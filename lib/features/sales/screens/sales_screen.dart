import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
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
    final sales = ref.watch(salesProvider);
    final user = ref.watch(authProvider).asData?.value;
    final notifier = ref.read(salesProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            tooltip: 'Filter dates',
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      floatingActionButton: user?.canCreateSales == true
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('New sale'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    notifier.setFilters(search: '');
                  },
                  icon: const Icon(Icons.close),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) notifier.setFilters(search: value);
                });
              },
            ),
          ),
          _DateFilterLabel(
            from: notifier.from,
            to: notifier.to,
            onClear: () => notifier.setFilters(clearFrom: true, clearTo: true),
          ),
          Expanded(
            child: sales.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _SalesError(error: error, onRetry: () => notifier.refresh()),
              data: (items) => RefreshIndicator(
                onRefresh: notifier.refresh,
                child: items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 150),
                          Center(child: Text('No sales found.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _SaleCard(
                          sale: items[index],
                          onTap: () => _showDetails(context, items[index]),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final notifier = ref.read(salesProvider.notifier);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: notifier.from == null && notifier.to == null
          ? null
          : DateTimeRange(
              start: notifier.from ?? notifier.to!,
              end: notifier.to ?? notifier.from!,
            ),
    );
    if (range != null) {
      await notifier.setFilters(from: range.start, to: range.end);
    }
  }

  Future<void> _openEditor(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => const SaleEditor(),
  );

  Future<void> _showDetails(BuildContext context, Sale sale) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (_) => _SaleDetails(sale: sale),
      );
}

class _DateFilterLabel extends StatelessWidget {
  const _DateFilterLabel({
    required this.from,
    required this.to,
    required this.onClear,
  });
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (from == null && to == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('Date range: ${_date(from!)} – ${_date(to!)}')),
          IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.onTap});
  final Sale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(sale.referenceNo ?? 'Sale'),
      subtitle: Text(
        '${_date(sale.soldAt)} · ${sale.items.length} item(s)'
        '${sale.createdByName == null ? '' : '\n${sale.createdByName}'}',
      ),
      isThreeLine: sale.createdByName != null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_money(sale.total)),
          Text(
            sale.status.apiValue,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _SaleDetails extends StatelessWidget {
  const _SaleDetails({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sale.referenceNo ?? 'Sale',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('${_date(sale.soldAt)} · ${sale.status.apiValue}'),
          if (sale.createdByName != null) Text('Sold by ${sale.createdByName}'),
          if (sale.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(sale.notes!),
          ],
          const SizedBox(height: 12),
          ...sale.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.productName),
              subtitle: Text(
                '${item.productCode} · ${_quantity(item.quantity)} × ${_money(item.unitPrice)}',
              ),
              trailing: Text(_money(item.totalPrice)),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Total'),
            trailing: Text(
              _money(sale.total),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    ),
  );
}

class SaleEditor extends ConsumerStatefulWidget {
  const SaleEditor({super.key});

  @override
  ConsumerState<SaleEditor> createState() => _SaleEditorState();
}

class _SaleEditorState extends ConsumerState<SaleEditor> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<_SaleLine> _lines = [];
  DateTime _soldAt = DateTime.now();
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
            Text('New sale', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Sale date: ${_date(_soldAt)}'),
            ),
            const SizedBox(height: 8),
            ..._lines.asMap().entries.map(
              (entry) => _lineEditor(entry.key, entry.value),
            ),
            OutlinedButton.icon(
              onPressed: _chooseProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLength: 2000,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_lines.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ${_money(_total)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete sale'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completing the sale immediately deducts stock. The server validates availability.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  double get _total => _lines.fold(
    0,
    (sum, line) =>
        sum +
        ((double.tryParse(line.quantityController.text) ?? 0) *
            (double.tryParse(line.priceController.text) ?? 0)),
  );

  Widget _lineEditor(int index, _SaleLine line) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${line.product.name} · ${_quantity(line.product.currentStock)} ${line.product.unit.apiValue} available',
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _lines.removeAt(index).dispose()),
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
                  validator: (value) {
                    final n = double.tryParse(value?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter a valid quantity';
                    if (n > line.product.currentStock) {
                      return 'Exceeds available stock';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: line.priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  validator: (value) {
                    final n = double.tryParse(value?.trim() ?? '');
                    return n == null || n < 0 ? 'Enter a valid price' : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _soldAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _soldAt = date);
  }

  Future<void> _chooseProduct() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => const _SaleProductPicker(),
    );
    if (product == null || !mounted) return;
    if (_lines.any((line) => line.product.id == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That product is already in the sale.')),
      );
      return;
    }
    setState(() => _lines.add(_SaleLine(product)));
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
    final input = SaleInput(
      soldAt: _soldAt,
      notes: _notesController.text,
      items: _lines
          .map(
            (line) => SaleItem(
              productId: line.product.id,
              productName: line.product.name,
              productCode: line.product.code,
              quantity: double.parse(line.quantityController.text.trim()),
              unitPrice: double.parse(line.priceController.text.trim()),
              totalPrice: 0,
            ),
          )
          .toList(),
    );
    try {
      await ref.read(salesProvider.notifier).create(input);
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

class _SaleProductPicker extends ConsumerStatefulWidget {
  const _SaleProductPicker();

  @override
  ConsumerState<_SaleProductPicker> createState() => _SaleProductPickerState();
}

class _SaleProductPickerState extends ConsumerState<_SaleProductPicker> {
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
    final products = ref.watch(saleProductsProvider(_search));
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
                          final outOfStock = product.currentStock <= 0;
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.code} · ${_quantity(product.currentStock)} ${product.unit.apiValue} available',
                            ),
                            enabled: !outOfStock,
                            onTap: outOfStock
                                ? null
                                : () => Navigator.pop(context, product),
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

class _SaleLine {
  _SaleLine(this.product)
    : quantityController = TextEditingController(text: '1'),
      priceController = TextEditingController(text: '0');

  final Product product;
  final TextEditingController quantityController;
  final TextEditingController priceController;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class _SalesError extends StatelessWidget {
  const _SalesError({required this.error, required this.onRetry});
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

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
String _money(double value) => value.toStringAsFixed(2);
