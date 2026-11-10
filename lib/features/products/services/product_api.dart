import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/product.dart';

class ProductApi {
  const ProductApi(this._dio);
  final Dio _dio;

  Future<ProductPage> list({
    String search = '',
    int page = 1,
    int limit = 10,
    String? categoryId,
    StockStatus? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/products',
      queryParameters: {
        'search': search,
        'page': page,
        'limit': limit,
        'categoryId': categoryId ?? 'all',
        'status': status?.apiValue ?? 'all',
      },
    );
    return ProductPage.fromJson(response.data ?? const {});
  }

  Future<Product> create(ProductInput input) => _write(
    () async => (await _dio.post<Map<String, dynamic>>(
      '/api/products',
      data: input.toJson(),
    )).data,
  );

  Future<Product> update(String id, ProductInput input) => _write(
    () async => (await _dio.patch<Map<String, dynamic>>(
      '/api/products/${Uri.encodeComponent(id)}',
      data: input.toJson(),
    )).data,
  );

  Future<void> deactivate(String id) async {
    await _dio.post<void>(
      '/api/products/${Uri.encodeComponent(id)}/deactivate',
      data: const <String, dynamic>{},
    );
  }

  Future<void> activate(String id) async {
    await _dio.post<void>(
      '/api/products/${Uri.encodeComponent(id)}/activate',
      data: const <String, dynamic>{},
    );
  }

  Future<Product> _write(
    Future<Map<String, dynamic>?> Function() request,
  ) async {
    final data = await request();
    if (data == null) {
      throw const ApiException('The server returned no product.');
    }
    return Product.fromJson(data);
  }
}
