import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final responseData = error.response?.data;
    final serverMessage = responseData is Map<String, dynamic>
        ? (responseData['error'] ?? responseData['message'])?.toString()
        : null;
    final message =
        serverMessage ??
        switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout =>
            'The request timed out. Please try again.',
          DioExceptionType.connectionError =>
            'Could not connect to the server.',
          _ => error.message ?? 'The request failed. Please try again.',
        };
    return ApiException(message, statusCode: error.response?.statusCode);
  }

  static String messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) return ApiException.fromDio(error).message;
    return error.toString();
  }

  @override
  String toString() => message;
}
