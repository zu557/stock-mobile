import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String get apiBaseUrl {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredUrl.isNotEmpty) return _withoutTrailingSlash(configuredUrl);
  // Android emulators reach the host computer through 10.0.2.2. For web,
  // physical devices, and production, pass API_BASE_URL with --dart-define.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

String _withoutTrailingSlash(String value) =>
    value.endsWith('/') ? value.substring(0, value.length - 1) : value;

Dio createDioClient() => Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ),
);
