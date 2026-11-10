import 'package:dio/dio.dart';

import '../../features/auth/providers/auth_session.dart';
import '../storage/secure_storage.dart';

class BearerTokenInterceptor extends Interceptor {
  const BearerTokenInterceptor({required this.storage, required this.events});

  final SecureStorage storage;
  final AuthSessionEvents events;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await storage.read(authTokenStorageKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final token = response.headers.value('set-auth-token');
    if (token != null && token.isNotEmpty) {
      try {
        await storage.write(authTokenStorageKey, token);
      } catch (error) {
        handler.reject(
          DioException(requestOptions: response.requestOptions, error: error),
        );
        return;
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isProtectedApi = !err.requestOptions.path.startsWith('/api/auth/');
    if (err.response?.statusCode == 401 && isProtectedApi) {
      try {
        await storage.delete(authTokenStorageKey);
      } finally {
        events.sessionExpired();
      }
    }
    handler.next(err);
  }
}
