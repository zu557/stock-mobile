import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/purchase.dart';

class PurchaseApi {
  const PurchaseApi(this._dio);
  final Dio _dio;

  Future<List<Purchase>> list({String search = ''}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/purchases',
      queryParameters: search.trim().isEmpty ? null : {'search': search.trim()},
    );
    final purchases = response.data?['data'];
    if (purchases is! List<dynamic>) return const [];
    return purchases
        .map((value) => Purchase.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/purchases/${Uri.encodeComponent(id)}',
    );
    final purchase = response.data?['data'];
    if (purchase is! Map<String, dynamic>) {
      throw const ApiException('The server returned no purchase.');
    }
    return Purchase.fromJson(purchase);
  }

  Future<Purchase> create(PurchaseInput input) => _write(
    () async => (await _dio.post<Map<String, dynamic>>(
      '/api/purchases',
      data: input.toJson(),
    )).data,
  );

  Future<void> update(String id, PurchaseInput input) async {
    await _dio.patch<void>(
      '/api/purchases/${Uri.encodeComponent(id)}',
      data: input.toJson(),
    );
  }

  Future<void> delete(String id) =>
      _dio.delete<void>('/api/purchases/${Uri.encodeComponent(id)}');

  Future<void> complete(String id) async {
    await _dio.post<void>('/api/purchases/${Uri.encodeComponent(id)}/complete');
  }

  Future<Purchase> _write(
    Future<Map<String, dynamic>?> Function() request,
  ) async {
    final data = await request();
    final purchase = data?['data'];
    if (purchase is! Map<String, dynamic>) {
      throw const ApiException('The server returned no purchase.');
    }
    return Purchase.fromJson(purchase);
  }
}
