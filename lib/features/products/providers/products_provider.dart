import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/product.dart';
import '../services/product_api.dart';

final productApiProvider = Provider<ProductApi>(
  (ref) => ProductApi(ref.watch(dioProvider)),
);

final productsProvider = AsyncNotifierProvider<ProductsNotifier, ProductPage>(
  ProductsNotifier.new,
);

class ProductsNotifier extends AsyncNotifier<ProductPage> {
  String search = '';
  String? categoryId;
  StockStatus? status;
  int page = 1;
  final int pageSize = 10;

  ProductApi get _api => ref.read(productApiProvider);

  @override
  Future<ProductPage> build() => _fetch();

  Future<ProductPage> _fetch() => _api.list(
    search: search,
    page: page,
    limit: pageSize,
    categoryId: categoryId,
    status: status,
  );

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setFilters({
    String? search,
    String? categoryId,
    StockStatus? status,
    bool clearCategory = false,
    bool clearStatus = false,
  }) async {
    if (search != null) this.search = search;
    if (categoryId != null) this.categoryId = categoryId;
    if (clearCategory) this.categoryId = null;
    if (status != null) this.status = status;
    if (clearStatus) this.status = null;
    page = 1;
    await refresh();
  }

  Future<void> goToPage(int nextPage) async {
    final lastPage = state.asData?.value.totalPages ?? 1;
    if (nextPage < 1 || nextPage > lastPage || nextPage == page) return;
    page = nextPage;
    await refresh();
  }

  Future<Product> create(ProductInput input) async {
    final product = await _api.create(input);
    await refresh();
    return product;
  }

  Future<Product> updateProduct(String id, ProductInput input) async {
    final product = await _api.update(id, input);
    await refresh();
    return product;
  }

  Future<void> deactivateProduct(String id) async {
    await _api.deactivate(id);
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> activateProduct(String id) async {
    await _api.activate(id);
    state = await AsyncValue.guard(_fetch);
  }
}
