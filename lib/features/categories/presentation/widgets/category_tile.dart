import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../cubit/category_cubit.dart';
import '../cubit/category_state.dart';
import 'category_form_dialog.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.state,
    this.depth = 0,
  });

  final Category category;
  final CategoryLoaded state;
  final int depth;

  Color _getIconBgColor(int depth) {
    if (depth == 0) return AppColors.secondaryFixed;
    if (depth == 1) return AppColors.surfaceContainerHighest;
    return AppColors.tertiaryFixed;
  }

  Color _getIconColor(int depth) {
    if (depth == 0) return AppColors.onSecondaryFixed;
    if (depth == 1) return AppColors.secondary;
    return AppColors.onTertiaryFixed;
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = category.childCount > 0;
    // Search results include match + ancestors; keep the path expanded so the
    // matching folder is visible without tapping chevrons.
    final isExpanded =
        state.isSearching || state.expandedIds.contains(category.id);
    final isRoot = depth == 0;
    final hasMoreChildren =
        !state.isSearching && state.hasMoreChildren(category);
    final query = state.searchQuery.trim().toLowerCase();
    final showBreadcrumb = state.isSearching &&
        query.isNotEmpty &&
        category.name.toLowerCase().contains(query);
    final breadcrumbPath =
        showBreadcrumb ? (category.path ?? category.name) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: depth == 0 ? 0 : 16.0,
            bottom: 8.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isRoot
                ? AppColors.surfaceContainerLowest
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRoot
                  ? AppColors.borderSubtle
                  : AppColors.secondaryFixedDim.withValues(alpha: 0.4),
            ),
            boxShadow: isRoot
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasChildren)
                InkWell(
                  onTap: () {
                    context.read<CategoryCubit>().toggleExpanded(category.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                )
              else if (depth > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                  child: Icon(
                    Icons.remove,
                    size: 18,
                    color: AppColors.outlineVariant,
                  ),
                ),
              Container(
                width: isRoot ? 36 : 30,
                height: isRoot ? 36 : 30,
                decoration: BoxDecoration(
                  color: _getIconBgColor(depth),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder,
                  color: _getIconColor(depth),
                  size: isRoot ? 20 : 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      softWrap: true,
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: isRoot ? 15 : 13.5,
                        fontWeight:
                            isRoot ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (breadcrumbPath != null && breadcrumbPath.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        breadcrumbPath,
                        softWrap: true,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isRoot
                            ? AppColors.surfaceContainerHigh
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasChildren
                            ? '${category.childCount} ${category.childCount == 1 ? 'sub' : 'subs'}'
                            : 'Empty',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _addSubcategory(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: AppColors.statusInfo,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Sub',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: AppColors.onSurfaceVariant,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                    tooltip: 'Edit name',
                    onPressed: () => _editCategory(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: AppColors.error,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete folder',
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (hasChildren && isExpanded) ...[
          ...category.children.map(
            (child) => CategoryTile(
              category: child,
              state: state,
              depth: depth + 1,
            ),
          ),
          if (hasMoreChildren)
            Padding(
              padding: EdgeInsets.only(left: depth == 0 ? 16 : 32, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    context.read<CategoryCubit>().loadMoreChildren(category.id);
                  },
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: const Text('Load more'),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _addSubcategory(BuildContext context) async {
    final name = await showCategoryFormDialog(
      context: context,
      title: 'Add Subfolder',
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
      title: 'Edit Category',
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
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Folder',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to delete "${category.name}" and all its subcategories?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
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
      final hasSearch = state.isSearching;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSearch ? Icons.search_off : Icons.folder_open,
                size: 48,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                hasSearch
                    ? 'No categories match "${state.searchQuery}"'
                    : 'No categories yet. Tap "+ New Folder" to create your first root category.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ...state.visibleCategories.map(
          (category) => CategoryTile(
            category: category,
            state: state,
          ),
        ),
        if (!state.isSearching && state.hasMoreRoots)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  context.read<CategoryCubit>().loadMoreRoots();
                },
                icon: const Icon(Icons.expand_more),
                label: Text(
                  'Load more (${state.totalRootCount - state.rootVisibleCount} left)',
                ),
              ),
            ),
          ),
        if (state.isSearching && state.hasMoreSearch)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  context.read<CategoryCubit>().loadMoreSearch();
                },
                icon: const Icon(Icons.expand_more),
                label: Text(
                  'Load more (${state.totalSearchMatchCount - state.searchVisibleCount} left)',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
