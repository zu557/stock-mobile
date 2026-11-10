import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/sale.dart';

class SaleApi {
  const SaleApi(this._dio);
  final Dio _dio;

  Future<List<Sale>> list({
    String search = '',
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{};
    if (search.trim().isNotEmpty) query['q'] = search.trim();
    if (from != null) query['from'] = _dateOnly(from);
    if (to != null) query['to'] = _dateOnly(to);
    final response = await _dio.get<List<dynamic>>(
      '/api/sales',
      queryParameters: query.isEmpty ? null : query,
    );
    return (response.data ?? const [])
        .map((item) => Sale.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Sale> create(SaleInput input) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/sales',
      data: input.toJson(),
    );
    if (response.data == null) {
      throw const ApiException('The server returned no sale.');
    }
    return Sale.fromJson(response.data!);
  }
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
