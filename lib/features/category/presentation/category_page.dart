import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sultan/core/widgets/responsive_page.dart';
import 'package:sultan/features/category/domain/models/category.dart';
import 'package:sultan/features/category/presentation/controllers/category_controller.dart';
import 'package:sultan/features/category/presentation/widgets/category_form_dialog.dart';

class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(categoryControllerProvider.notifier).load(),
    );
  }

  Future<void> _showCreateDialog({Category? parent}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CategoryFormDialog(
        parentId: parent?.id,
        parentName: parent?.name,
        categories: _currentCategories(),
      ),
    );
  }

  Future<void> _showEditDialog(Category category) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CategoryFormDialog(
        existing: category,
        categories: _currentCategories(),
      ),
    );
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"?'
          '${category.children.isNotEmpty ? '\n\nThis category has subcategories.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(categoryControllerProvider.notifier).delete(category.id);
    }
  }

  List<Category> _currentCategories() {
    final s = ref.read(categoryControllerProvider);
    return s is CategoryLoaded ? s.categories : [];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryControllerProvider);

    return ResponsivePage(
      mobile: _CategoryListView(
        state: state,
        onAdd: () => _showCreateDialog(),
        onEdit: _showEditDialog,
        onDelete: _confirmDelete,
        onAddChild: (parent) => _showCreateDialog(parent: parent),
        onRefresh: () => ref.read(categoryControllerProvider.notifier).load(),
      ),
      desktop: Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: _CategoryListView(
          state: state,
          onAdd: () => _showCreateDialog(),
          onEdit: _showEditDialog,
          onDelete: _confirmDelete,
          onAddChild: (parent) => _showCreateDialog(parent: parent),
          onRefresh: () => ref.read(categoryControllerProvider.notifier).load(),
          desktopLayout: true,
        ),
      ),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  final CategoryState state;
  final VoidCallback onAdd;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;
  final void Function(Category) onAddChild;
  final Future<void> Function() onRefresh;
  final bool desktopLayout;

  const _CategoryListView({
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
    required this.onRefresh,
    this.desktopLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (state is CategoryLoading || state is CategoryInitial) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state is CategoryError) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (state as CategoryError).message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state is CategoryLoaded) {
      final categories = (state as CategoryLoaded).categories;
      if (categories.isEmpty) {
        body = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No categories yet'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
        );
      } else {
        body = RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: desktopLayout ? 24 : 0,
              vertical: 8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                category: category,
                onEdit: onEdit,
                onDelete: onDelete,
                onAddChild: onAddChild,
              );
            },
          ),
        );
      }
    } else {
      body = const SizedBox.shrink();
    }

    return Scaffold(
      appBar: desktopLayout ? null : AppBar(title: const Text('Categories')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;
  final void Function(Category) onAddChild;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.children.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.category_outlined),
        title: Text(category.name),
        subtitle: category.description != null
            ? Text(
                category.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        initiallyExpanded: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add subcategory',
              onPressed: () => onAddChild(category),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => onEdit(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => onDelete(category),
            ),
          ],
        ),
        children: hasChildren
            ? category.children.map((child) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                  title: Text(child.name),
                  subtitle: child.description != null
                      ? Text(
                          child.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                );
              }).toList()
            : [
                const ListTile(
                  contentPadding: EdgeInsets.only(left: 32),
                  title: Text(
                    'No subcategories',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
      ),
    );
  }
}
