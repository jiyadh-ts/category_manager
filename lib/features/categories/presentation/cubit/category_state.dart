import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  const CategoryLoaded({
    required this.visibleCategories,
    required this.searchQuery,
    required this.expandedIds,
    required this.pageSize,
    required this.showAll,
    required this.rootVisibleCount,
    required this.childVisibleCounts,
    required this.searchVisibleCount,
    required this.totalRootCount,
    required this.totalSearchMatchCount,
    required this.totalCategories,
    required this.nestedCount,
    required this.hasMoreRoots,
    required this.hasMoreSearch,
    this.errorMessage,
    this.undoMessage,
  });

  final List<Category> visibleCategories;
  final String searchQuery;
  final Set<int> expandedIds;
  final int pageSize;
  final bool showAll;
  final int rootVisibleCount;
  final Map<int, int> childVisibleCounts;
  final int searchVisibleCount;
  final int totalRootCount;
  final int totalSearchMatchCount;
  final int totalCategories;
  final int nestedCount;
  final bool hasMoreRoots;
  final bool hasMoreSearch;
  final String? errorMessage;
  final String? undoMessage;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  int childVisibleCountFor(int parentId) {
    if (showAll) {
      return 1 << 30;
    }
    return childVisibleCounts[parentId] ?? pageSize;
  }

  bool hasMoreChildren(Category parent) {
    if (showAll || isSearching) {
      return false;
    }
    return parent.childCount > parent.children.length;
  }

  CategoryLoaded copyWith({
    List<Category>? visibleCategories,
    String? searchQuery,
    Set<int>? expandedIds,
    int? pageSize,
    bool? showAll,
    int? rootVisibleCount,
    Map<int, int>? childVisibleCounts,
    int? searchVisibleCount,
    int? totalRootCount,
    int? totalSearchMatchCount,
    int? totalCategories,
    int? nestedCount,
    bool? hasMoreRoots,
    bool? hasMoreSearch,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? undoMessage,
    bool clearUndoMessage = false,
  }) {
    return CategoryLoaded(
      visibleCategories: visibleCategories ?? this.visibleCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedIds: expandedIds ?? this.expandedIds,
      pageSize: pageSize ?? this.pageSize,
      showAll: showAll ?? this.showAll,
      rootVisibleCount: rootVisibleCount ?? this.rootVisibleCount,
      childVisibleCounts: childVisibleCounts ?? this.childVisibleCounts,
      searchVisibleCount: searchVisibleCount ?? this.searchVisibleCount,
      totalRootCount: totalRootCount ?? this.totalRootCount,
      totalSearchMatchCount:
          totalSearchMatchCount ?? this.totalSearchMatchCount,
      totalCategories: totalCategories ?? this.totalCategories,
      nestedCount: nestedCount ?? this.nestedCount,
      hasMoreRoots: hasMoreRoots ?? this.hasMoreRoots,
      hasMoreSearch: hasMoreSearch ?? this.hasMoreSearch,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      undoMessage: clearUndoMessage ? null : undoMessage ?? this.undoMessage,
    );
  }

  @override
  List<Object?> get props => [
        visibleCategories,
        searchQuery,
        expandedIds,
        pageSize,
        showAll,
        rootVisibleCount,
        childVisibleCounts,
        searchVisibleCount,
        totalRootCount,
        totalSearchMatchCount,
        totalCategories,
        nestedCount,
        hasMoreRoots,
        hasMoreSearch,
        errorMessage,
        undoMessage,
      ];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
