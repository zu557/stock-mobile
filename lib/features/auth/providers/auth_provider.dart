import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../models/auth_user.dart';
import '../services/auth_api.dart';
import 'auth_session.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  AuthApi get _api => ref.read(authApiProvider);

  @override
  Future<AuthUser?> build() async {
    final events = ref.read(authSessionEventsProvider);
    void onSessionExpired() {
      state = const AsyncData(null);
    }

    events.addListener(onSessionExpired);
    ref.onDispose(() => events.removeListener(onSessionExpired));

    final token = await ref
        .read(secureStorageProvider)
        .read(authTokenStorageKey);
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _api.getSession();
      if (user == null) {
        await ref.read(secureStorageProvider).delete(authTokenStorageKey);
      }
      return user;
    } catch (error) {
      final statusCode = switch (error) {
        ApiException(:final statusCode) => statusCode,
        DioException(response: final response) => response?.statusCode,
        _ => null,
      };
      if (statusCode == 401) {
        await ref.read(secureStorageProvider).delete(authTokenStorageKey);
        return null;
      }
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _api.signIn(email: email.trim(), password: password);
    final user = await _api.getSession();
    if (user == null) {
      await ref.read(secureStorageProvider).delete(authTokenStorageKey);
      throw const ApiException(
        'Sign-in succeeded, but the backend returned no active session.',
      );
    }
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    try {
      await _api.signOut();
    } finally {
      await ref.read(secureStorageProvider).delete(authTokenStorageKey);
      state = const AsyncData(null);
    }
  }

  Future<void> retryInitialization() async {
    ref.invalidateSelf();
    await future;
  }
}
