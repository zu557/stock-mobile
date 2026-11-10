import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/category.dart';

class CategoryApi {
  const CategoryApi(this._dio);
  final Dio _dio;

  Future<List<Category>> list({String search = ''}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/categories',
      queryParameters: search.trim().isEmpty ? null : {'search': search.trim()},
    );
    return (response.data ?? const [])
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create(CategoryInput input) => _write(
    () async => (await _dio.post<Map<String, dynamic>>(
      '/api/categories',
      data: input.toJson(),
    )).data,
  );

  Future<Category> update(String id, CategoryInput input) => _write(
    () async => (await _dio.patch<Map<String, dynamic>>(
      '/api/categories/${Uri.encodeComponent(id)}',
      data: input.toJson(),
    )).data,
  );

  Future<void> delete(String id) async {
    await _dio.delete<void>('/api/categories/${Uri.encodeComponent(id)}');
  }

  Future<Category> _write(
    Future<Map<String, dynamic>?> Function() request,
  ) async {
    final data = await request();
    if (data == null) {
      throw const ApiException('The server returned no category.');
    }
    return Category.fromJson(data);
  }
}
