import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';

import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  final Set<String> _processingProductIds = {};
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final canManageProducts =
        ref.watch(authProvider).asData?.value?.canManageProducts == true;
    final canDeactivateProducts =
        ref.watch(authProvider).asData?.value?.canDeactivateProducts == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: canManageProducts
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search name or code',
                    suffixIcon: IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _debounce?.cancel();
                        ref
                            .read(productsProvider.notifier)
                            .setFilters(search: '');
                      },
                      icon: const Icon(Icons.close),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      if (mounted) {
                        ref
                            .read(productsProvider.notifier)
                            .setFilters(search: value.trim());
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: categories.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, _) => Text(
                          'Categories unavailable: ${ApiException.messageFor(error)}',
                        ),
                        data: (items) => DropdownButtonFormField<String?>(
                          key: ValueKey(
                            ref.read(productsProvider.notifier).categoryId,
                          ),
                          initialValue: ref
                              .read(productsProvider.notifier)
                              .categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All categories'),
                            ),
                            ...items.map(
                              (item) => DropdownMenuItem<String?>(
                                value: item.id,
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) => ref
                              .read(productsProvider.notifier)
                              .setFilters(
                                categoryId: value,
                                clearCategory: value == null,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<StockStatus?>(
                        key: ValueKey(
                          ref.read(productsProvider.notifier).status,
                        ),
                        initialValue: ref
                            .read(productsProvider.notifier)
                            .status,
                        decoration: const InputDecoration(
                          labelText: 'Stock status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<StockStatus?>(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          ...StockStatus.values.map(
                            (status) => DropdownMenuItem<StockStatus?>(
                              value: status,
                              child: Text(
                                _statusLabel(status),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => ref
                            .read(productsProvider.notifier)
                            .setFilters(
                              status: value,
                              clearStatus: value == null,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                error: error,
                onRetry: () => ref.read(productsProvider.notifier).refresh(),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () => ref.read(productsProvider.notifier).refresh(),
                child: page.products.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 140),
                          Center(child: Text('No products found.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: page.products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _ProductCard(
                          product: page.products[index],
                          onOpen: () => context.push(
                            '/products/${page.products[index].id}',
                            extra: page.products[index],
                          ),
                          onEdit: () =>
                              _openForm(context, product: page.products[index]),
                          canManage: canManageProducts,
                          canDeactivate: canDeactivateProducts,
                          isProcessing: _processingProductIds.contains(
                            page.products[index].id,
                          ),
                          onDeactivate: () =>
                              _setProductActive(page.products[index], false),
                          onActivate: () =>
                              _setProductActive(page.products[index], true),
                        ),
                      ),
              ),
            ),
          ),
          if (products.asData?.value case final page? when page.totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: page.page > 1
                        ? () => ref
                              .read(productsProvider.notifier)
                              .goToPage(page.page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${page.page} / ${page.totalPages}  •  ${page.total} products',
                  ),
                  IconButton(
                    onPressed: page.page < page.totalPages
                        ? () => ref
                              .read(productsProvider.notifier)
                              .goToPage(page.page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductFormSheet(product: product),
    );
  }

  Future<void> _setProductActive(Product product, bool isActive) async {
    if (_processingProductIds.contains(product.id)) return;
    if (!isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate product?'),
          content: Text(
            '${product.name} will no longer be available for new sales. You can still find it in the product list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _processingProductIds.add(product.id));
    try {
      final notifier = ref.read(productsProvider.notifier);
      if (isActive) {
        await notifier.activateProduct(product.id);
      } else {
        await notifier.deactivateProduct(product.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product.name} was ${isActive ? 'activated' : 'deactivated'}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _processingProductIds.remove(product.id));
      }
    }
  }
}

class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, this.product});
  final Product? product;

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.product?.code ?? '');
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _description = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late final _reorder = TextEditingController(
    text: widget.product?.reorderLevel.toString() ?? '0',
  );
  late String? _categoryId = widget.product?.categoryId;
  late ProductUnit _unit = widget.product?.unit ?? ProductUnit.piece;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _reorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product == null ? 'Create product' : 'Update product',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _textField(_code, 'Product code'),
              _textField(_name, 'Product name'),
              _textField(_description, 'Description', requiredField: false),
              DropdownButtonFormField<ProductUnit>(
                initialValue: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: ProductUnit.values
                    .map(
                      (unit) =>
                          DropdownMenuItem(value: unit, child: Text(unit.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _unit = value);
                },
              ),
              TextFormField(
                controller: _reorder,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Reorder level'),
                validator: (value) =>
                    double.tryParse(value ?? '') == null ||
                        double.parse(value!) < 0
                    ? 'Enter a number of 0 or more'
                    : null,
              ),
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(
                  'Could not load categories: ${ApiException.messageFor(error)}',
                ),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: items.any((item) => item.id == _categoryId)
                      ? _categoryId
                      : null,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) =>
                      value == null ? 'Choose a category' : null,
                  items: items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.product == null
                            ? 'Create product'
                            : 'Save changes',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool requiredField = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          requiredField && (value == null || value.trim().isEmpty)
          ? '$label is required'
          : null,
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _saving = true);
    final input = ProductInput(
      code: _code.text.trim(),
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      unit: _unit,
      reorderLevel: double.parse(_reorder.text),
      categoryId: _categoryId!,
    );
    try {
      final notifier = ref.read(productsProvider.notifier);
      if (widget.product == null) {
        await notifier.create(input);
      } else {
        await notifier.updateProduct(widget.product!.id, input);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.messageFor(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product details')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Code: ${product.code}'),
        Text('Category: ${product.categoryName ?? 'Unavailable'}'),
        Text('Unit: ${product.unit.name}'),
        Text('Current stock: ${product.currentStock}'),
        Text('Reorder level: ${product.reorderLevel}'),
        Text('Status: ${_statusLabel(product.stockStatus)}'),
        if (product.description?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(product.description!),
        ],
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onOpen,
    required this.onEdit,
    required this.canManage,
    required this.canDeactivate,
    required this.isProcessing,
    required this.onDeactivate,
    required this.onActivate,
  });
  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final bool canManage;
  final bool canDeactivate;
  final bool isProcessing;
  final VoidCallback onDeactivate;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onOpen,
      title: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!product.isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Inactive',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${product.code}  •  ${product.currentStock} ${product.unit.name}\n${product.categoryName ?? ''}',
      ),
      isThreeLine: true,
      trailing: (canManage || (canDeactivate && product.isActive))
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canManage)
                  IconButton(
                    onPressed: isProcessing ? null : onEdit,
                    tooltip: 'Edit product',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (canDeactivate)
                  if (isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: product.isActive ? onDeactivate : onActivate,
                      tooltip: product.isActive
                          ? 'Deactivate product'
                          : 'Activate product',
                      color: product.isActive
                          ? Theme.of(context).colorScheme.error
                          : Colors.green,
                      icon: Icon(
                        product.isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                      ),
                    ),
              ],
            )
          : null,
      leading: Icon(
        Icons.inventory_2_outlined,
        color: _statusColor(product.stockStatus),
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ApiException.messageFor(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

String _statusLabel(StockStatus status) => switch (status) {
  StockStatus.outOfStock => 'Out of stock',
  StockStatus.low => 'Low stock',
  StockStatus.inStock => 'In stock',
};

Color _statusColor(StockStatus status) => switch (status) {
  StockStatus.outOfStock => Colors.red,
  StockStatus.low => Colors.orange,
  StockStatus.inStock => Colors.green,
};
