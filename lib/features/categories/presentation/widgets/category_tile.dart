import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category_helpers.dart';
import '../../domain/entities/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_form_dialog.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.flatCategories,
    required this.expandedIds,
    this.depth = 0,
  });

  final Category category;
  final List<Category> flatCategories;
  final Set<int> expandedIds;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.children.isNotEmpty;
    final isExpanded = expandedIds.contains(category.id);
    final parentPath = getCategoryPath(flatCategories, category.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 16.0),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: hasChildren
                ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                    ),
                    onPressed: () {
                      context.read<CategoryCubit>().toggleExpanded(category.id);
                    },
                  )
                : const SizedBox(width: 48, child: Icon(Icons.circle, size: 8)),
            title: Text(category.name),
            subtitle: Text(parentPath),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: 'Add subcategory',
                  icon: const Icon(Icons.add),
                  onPressed: () => _addSubcategory(context),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCategory(context),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          ...category.children.map(
            (child) => CategoryTile(
              category: child,
              flatCategories: flatCategories,
              expandedIds: expandedIds,
              depth: depth + 1,
            ),
          ),
      ],
    );
  }

  Future<void> _addSubcategory(BuildContext context) async {
    final name = await showCategoryFormDialog(
      context: context,
      title: 'Add subcategory',
    );
    if (name == null || !context.mounted) {
      return;
    }

    await context.read<CategoryCubit>().addCategory(
          name: name,
          parentId: category.id,
        );
  }

  Future<void> _editCategory(BuildContext context) async {
    final name = await showCategoryFormDialog(
      context: context,
      title: 'Edit category',
      initialName: category.name,
    );
    if (name == null || !context.mounted) {
      return;
    }

    await context.read<CategoryCubit>().updateCategory(
          id: category.id,
          name: name,
        );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: const Text(
            'This will also delete all subcategories. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await context.read<CategoryCubit>().deleteCategory(category.id);
  }
}

class CategoryTreeList extends StatelessWidget {
  const CategoryTreeList({super.key, required this.state});

  final CategoryLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.visibleCategories.isEmpty) {
      final hasSearch = state.searchQuery.trim().isNotEmpty;
      return Center(
        child: Text(
          hasSearch
              ? 'No categories match your search.'
              : 'No categories yet. Add a root category to get started.',
        ),
      );
    }

    return ListView(
      children: [
        ...state.visibleCategories.map(
          (category) => CategoryTile(
            category: category,
            flatCategories: state.flatCategories,
            expandedIds: state.expandedIds,
          ),
        ),
      ],
    );
  }
}
