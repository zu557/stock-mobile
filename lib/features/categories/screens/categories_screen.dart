import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categorySearchProvider(_search));
    final user = ref.watch(authProvider).asData?.value;
    final canManage = user?.canManageCategories == true;
    final canDelete = user?.canDeleteCategories == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('Add category'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search categories',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _debounce?.cancel();
                    setState(() => _search = '');
                  },
                  icon: const Icon(Icons.close),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) {
                    setState(() => _search = value.trim());
                  }
                });
              },
            ),
          ),
          Expanded(
            child: categories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _CategoryError(
                error: error,
                onRetry: () => ref.read(categoriesProvider.notifier).refresh(),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(categoriesProvider.notifier).refresh(),
                child: items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No categories found.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _CategoryCard(
                          category: items[index],
                          canManage: canManage,
                          canDelete: canDelete,
                          onEdit: () =>
                              _openEditor(context, category: items[index]),
                          onDelete: () => _confirmDelete(context, items[index]),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Category? category}) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => CategoryEditor(category: category),
      );

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete ${category.name}? This cannot be undone.'),
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
      await ref.read(categoriesProvider.notifier).deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Category deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.messageFor(error))));
      }
    }
  }
}

class CategoryEditor extends ConsumerStatefulWidget {
  const CategoryEditor({super.key, this.category});
  final Category? category;

  @override
  ConsumerState<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.category?.description ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
              widget.category == null ? 'Create category' : 'Update category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Category name is required'
                  : null,
            ),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.category == null
                          ? 'Create category'
                          : 'Save changes',
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final input = CategoryInput(
      name: _nameController.text.trim(),
      description: _descriptionController.text,
    );
    try {
      final notifier = ref.read(categoriesProvider.notifier);
      if (widget.category == null) {
        await notifier.create(input);
      } else {
        await notifier.updateCategory(widget.category!.id, input);
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.canManage,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final bool canManage;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.category_outlined),
      title: Text(category.name),
      subtitle: Text(
        category.description?.isNotEmpty == true
            ? '${category.description}\n${category.productCount} products'
            : '${category.productCount} products',
      ),
      isThreeLine: category.description?.isNotEmpty == true,
      trailing: canManage || canDelete
          ? PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => [
                if (canManage)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (canDelete)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
          : null,
    ),
  );
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.error, required this.onRetry});
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
