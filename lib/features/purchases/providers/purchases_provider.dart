import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../features/products/models/product.dart';
import '../../../features/products/services/product_api.dart';
import '../models/purchase.dart';
import '../services/purchase_api.dart';

final purchaseApiProvider = Provider<PurchaseApi>(
  (ref) => PurchaseApi(ref.watch(dioProvider)),
);

final purchaseProductApiProvider = Provider<ProductApi>(
  (ref) => ProductApi(ref.watch(dioProvider)),
);

final purchaseProductsProvider = FutureProvider.family<ProductPage, String>((
  ref,
  search,
) {
  return ref.watch(purchaseProductApiProvider).list(search: search, limit: 100);
});

final purchasesProvider =
    AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(
      PurchasesNotifier.new,
    );

final purchaseDetailProvider = FutureProvider.family<Purchase, String>(
  (ref, id) => ref.watch(purchaseApiProvider).getById(id),
);

class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  String search = '';

  PurchaseApi get _api => ref.read(purchaseApiProvider);

  @override
  Future<List<Purchase>> build() => _api.list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.list(search: search));
  }

  Future<void> setSearch(String value) async {
    search = value;
    await refresh();
  }

  Future<void> create(PurchaseInput input) async {
    await _api.create(input);
    await refresh();
  }

  Future<void> updatePurchase(String id, PurchaseInput input) async {
    await _api.update(id, input);
    await refresh();
  }

  Future<void> deletePurchase(String id) async {
    await _api.delete(id);
    await refresh();
  }

  Future<void> completePurchase(String id) async {
    await _api.complete(id);
    await refresh();
  }
}
