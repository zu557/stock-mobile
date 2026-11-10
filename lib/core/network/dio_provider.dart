import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_session.dart';
import '../storage/secure_storage_provider.dart';
import 'bearer_token_interceptor.dart';
import 'dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = createDioClient();
  dio.interceptors.add(
    BearerTokenInterceptor(
      storage: ref.watch(secureStorageProvider),
      events: ref.watch(authSessionEventsProvider),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
