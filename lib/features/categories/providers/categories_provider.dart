import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/category.dart';
import '../services/category_api.dart';

final categoryApiProvider = Provider<CategoryApi>(
  (ref) => CategoryApi(ref.watch(dioProvider)),
);

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
      CategoriesNotifier.new,
    );

final categorySearchProvider = FutureProvider.family<List<Category>, String>((
  ref,
  search,
) {
  return ref.watch(categoryApiProvider).list(search: search);
});

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  CategoryApi get _api => ref.read(categoryApiProvider);

  @override
  Future<List<Category>> build() => _api.list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.list());
  }

  Future<void> create(CategoryInput input) async {
    await _api.create(input);
    ref.invalidate(categorySearchProvider);
    await refresh();
  }

  Future<void> updateCategory(String id, CategoryInput input) async {
    await _api.update(id, input);
    ref.invalidate(categorySearchProvider);
    await refresh();
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete(id);
    ref.invalidate(categorySearchProvider);
    await refresh();
  }
}
