import '../../../core/network/api_exception.dart';

import 'package:dio/dio.dart';

import '../models/auth_user.dart';

class AuthApi {
  const AuthApi(this._dio);
  final Dio _dio;

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/sign-in/email',
      data: {'email': email, 'password': password, 'rememberMe': true},
    );
    final user = response.data?['user'];
    if (user is! Map<String, dynamic>) {
      throw const ApiException('Sign-in response did not include a user.');
    }
    return AuthUser.fromJson(user);
  }

  Future<AuthUser?> getSession() async {
    final response = await _dio.get<dynamic>('/api/auth/get-session');
    final data = response.data;
    if (data is! Map<String, dynamic> || data['user'] == null) return null;
    final user = data['user'];
    if (user is! Map<String, dynamic>) return null;
    return AuthUser.fromJson(user);
  }

  Future<void> signOut() async {
    // Dio sends application/json by default. Send a valid empty JSON object
    // instead of a zero-byte body so Better Auth's body parser can read it.
    await _dio.post<void>(
      '/api/auth/sign-out',
      data: const <String, dynamic>{},
    );
  }
}
