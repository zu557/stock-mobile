import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';

import 'package:go_router/go_router.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../models/purchase.dart';
import '../providers/purchases_provider.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchasesProvider);
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      floatingActionButton: user?.canCreatePurchases == true
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('New purchase'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search reference number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _debounce?.cancel();
                    _searchController.clear();
                    ref.read(purchasesProvider.notifier).setSearch('');
                  },
                  icon: const Icon(Icons.close),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) {
                    ref.read(purchasesProvider.notifier).setSearch(value);
                  }
                });
              },
            ),
          ),
          Expanded(
            child: purchases.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _PurchaseError(
                error: error,
                onRetry: () => ref.read(purchasesProvider.notifier).refresh(),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.read(purchasesProvider.notifier).refresh(),
                child: items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No purchases found.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _PurchaseCard(
                          purchase: items[index],
                          user: user,
                          onTap: () =>
                              context.push('/purchases/${items[index].id}'),
                          onEdit: () => _openEditor(context, items[index]),
                          onDelete: () => _delete(context, items[index]),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, [Purchase? purchase]) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => PurchaseEditor(purchase: purchase),
      );

  Future<void> _delete(BuildContext context, Purchase purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete draft purchase?'),
        content: Text('Delete ${purchase.referenceNo ?? 'this draft'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(purchasesProvider.notifier).deletePurchase(purchase.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft purchase deleted.')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Purchase purchase;
  final AuthUser? user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get canManageDraft =>
      purchase.isDraft &&
      (user?.role == 'ADMIN' ||
          (user?.role == 'STOREKEEPER' && user?.id == purchase.createdById));

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(
        purchase.isDraft ? Icons.edit_note : Icons.inventory_2_outlined,
      ),
      title: Text(purchase.referenceNo ?? 'Purchase'),
      subtitle: Text(
        '${_date(purchase.purchasedAt)} · ${purchase.items.length} item(s)\n'
        '${purchase.createdByName ?? 'Unknown user'}',
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(purchase.total)),
              Text(
                purchase.status.apiValue,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          if (canManageDraft)
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit draft')),
                PopupMenuItem(value: 'delete', child: Text('Delete draft')),
              ],
            ),
        ],
      ),
    ),
  );
}

class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({super.key, required this.purchaseId});
  final String purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(purchaseId));
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase details')),
      body: purchaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PurchaseError(
          error: error,
          onRetry: () => ref.invalidate(purchaseDetailProvider(purchaseId)),
        ),
        data: (purchase) {
          final canEdit =
              purchase.isDraft &&
              (user?.role == 'ADMIN' ||
                  (user?.role == 'STOREKEEPER' &&
                      user?.id == purchase.createdById));
          final canComplete =
              purchase.isDraft && user?.canCreatePurchases == true;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                purchase.referenceNo ?? 'Purchase',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${purchase.status.apiValue} · ${_date(purchase.purchasedAt)}',
              ),
              if (purchase.createdByName != null)
                Text('Created by ${purchase.createdByName}'),
              if (purchase.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(purchase.notes!),
              ],
              const SizedBox(height: 20),
              Text('Items', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...purchase.items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.productCode} · ${_quantity(item.quantity)} × ${_money(item.unitCost)}',
                    ),
                    trailing: Text(_money(item.totalCost)),
                  ),
                ),
              ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Total'),
                trailing: Text(
                  _money(purchase.total),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (canEdit || canComplete) ...[
                const SizedBox(height: 16),
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        builder: (_) => PurchaseEditor(purchase: purchase),
                      );
                      ref.invalidate(purchaseDetailProvider(purchaseId));
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit draft'),
                  ),
                if (canComplete)
                  FilledButton.icon(
                    onPressed: () => _complete(context, ref),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete purchase'),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete purchase?'),
        content: const Text(
          'Completing this draft will add its quantities to inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(purchasesProvider.notifier).completePurchase(purchaseId);
      ref.invalidate(purchaseDetailProvider(purchaseId));
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class PurchaseEditor extends ConsumerStatefulWidget {
  const PurchaseEditor({super.key, this.purchase});
  final Purchase? purchase;

  @override
  ConsumerState<PurchaseEditor> createState() => _PurchaseEditorState();
}

class _PurchaseEditorState extends ConsumerState<PurchaseEditor> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _purchasedAt = widget.purchase?.purchasedAt ?? DateTime.now();
  late final _notesController = TextEditingController(
    text: widget.purchase?.notes ?? '',
  );
  late final List<_DraftLine> _lines =
      widget.purchase?.items.map(_DraftLine.fromItem).toList() ?? [];
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
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
              widget.purchase == null
                  ? 'New draft purchase'
                  : 'Edit draft purchase',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Purchase date: ${_date(_purchasedAt)}'),
            ),
            const SizedBox(height: 12),
            ..._lines.asMap().entries.map(
              (entry) => _lineEditor(entry.key, entry.value),
            ),
            OutlinedButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.purchase == null ? 'Save draft' : 'Save changes',
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _lineEditor(int index, _DraftLine line) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${line.productName} (${line.productCode})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Remove product',
                onPressed: () => setState(() {
                  _lines.removeAt(index).dispose();
                }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) =>
                      _positiveNumber(value, 'Enter a valid quantity'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: line.costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Unit cost'),
                  validator: (value) =>
                      _nonNegativeNumber(value, 'Enter a valid cost'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _purchasedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (chosen != null) setState(() => _purchasedAt = chosen);
  }

  Future<void> _addProduct() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const _ProductPickerDialog(),
    );
    if (product == null || !mounted) return;
    if (_lines.any((line) => line.productId == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That product is already in this purchase.'),
        ),
      );
      return;
    }
    setState(() => _lines.add(_DraftLine.fromProduct(product)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product.')),
      );
      return;
    }
    setState(() => _saving = true);
    final input = PurchaseInput(
      purchasedAt: _purchasedAt,
      notes: _notesController.text,
      items: _lines
          .map(
            (line) => PurchaseItem(
              productId: line.productId,
              productName: line.productName,
              productCode: line.productCode,
              quantity: double.parse(line.quantityController.text.trim()),
              unitCost: double.parse(line.costController.text.trim()),
              totalCost: 0,
            ),
          )
          .toList(),
    );
    try {
      final notifier = ref.read(purchasesProvider.notifier);
      if (widget.purchase == null) {
        await notifier.create(input);
      } else {
        await notifier.updatePurchase(widget.purchase!.id, input);
        ref.invalidate(purchaseDetailProvider(widget.purchase!.id));
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProductPickerDialog extends ConsumerStatefulWidget {
  const _ProductPickerDialog();

  @override
  ConsumerState<_ProductPickerDialog> createState() =>
      _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<_ProductPickerDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(purchaseProductsProvider(_search));
    return AlertDialog(
      title: const Text('Choose product'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _search = value.trim());
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: products.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text(ApiException.messageFor(error))),
                data: (page) => page.products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.builder(
                        itemCount: page.products.length,
                        itemBuilder: (context, index) {
                          final product = page.products[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.code} · ${product.unit.apiValue}',
                            ),
                            onTap: () => Navigator.pop(context, product),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _DraftLine {
  _DraftLine({
    required this.productId,
    required this.productName,
    required this.productCode,
    required String quantity,
    required String cost,
  }) : quantityController = TextEditingController(text: quantity),
       costController = TextEditingController(text: cost);

  final String productId;
  final String productName;
  final String productCode;
  final TextEditingController quantityController;
  final TextEditingController costController;

  factory _DraftLine.fromItem(PurchaseItem item) => _DraftLine(
    productId: item.productId,
    productName: item.productName,
    productCode: item.productCode,
    quantity: _quantity(item.quantity),
    cost: _quantity(item.unitCost),
  );

  factory _DraftLine.fromProduct(Product product) => _DraftLine(
    productId: product.id,
    productName: product.name,
    productCode: product.code,
    quantity: '1',
    cost: '0',
  );

  void dispose() {
    quantityController.dispose();
    costController.dispose();
  }
}

class _PurchaseError extends StatelessWidget {
  const _PurchaseError({required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ApiException.messageFor(error), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}

String? _positiveNumber(String? value, String message) {
  final number = double.tryParse(value?.trim() ?? '');
  return number == null || !number.isFinite || number <= 0 ? message : null;
}

String? _nonNegativeNumber(String? value, String message) {
  final number = double.tryParse(value?.trim() ?? '');
  return number == null || !number.isFinite || number < 0 ? message : null;
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _money(double value) => value.toStringAsFixed(2);

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(ApiException.messageFor(error))));
}
