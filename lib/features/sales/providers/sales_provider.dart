import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/products_provider.dart';
import '../models/sale.dart';
import '../services/sale_api.dart';

final saleApiProvider = Provider<SaleApi>(
  (ref) => SaleApi(ref.watch(dioProvider)),
);

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(
  SalesNotifier.new,
);

final saleProductsProvider = FutureProvider.family<ProductPage, String>((
  ref,
  search,
) {
  return ref.watch(productApiProvider).list(search: search, limit: 100);
});

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  String search = '';
  DateTime? from;
  DateTime? to;

  SaleApi get _api => ref.read(saleApiProvider);

  @override
  Future<List<Sale>> build() => _fetch();

  Future<List<Sale>> _fetch() => _api.list(search: search, from: from, to: to);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setFilters({
    String? search,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
  }) async {
    if (search != null) this.search = search;
    if (from != null) this.from = from;
    if (to != null) this.to = to;
    if (clearFrom) this.from = null;
    if (clearTo) this.to = null;
    await refresh();
  }

  Future<void> create(SaleInput input) async {
    await _api.create(input);
    await refresh();
  }
}
