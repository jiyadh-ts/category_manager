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
    required this.allCategories,
    required this.visibleCategories,
    required this.flatCategories,
    required this.searchQuery,
    required this.expandedIds,
    required this.pageSize,
    required this.showAll,
    required this.rootVisibleCount,
    required this.childVisibleCounts,
    required this.searchVisibleCount,
    required this.totalRootCount,
    required this.totalSearchMatchCount,
    required this.hasMoreRoots,
    required this.hasMoreSearch,
    this.errorMessage,
  });

  final List<Category> allCategories;
  final List<Category> visibleCategories;
  final List<Category> flatCategories;
  final String searchQuery;
  final Set<int> expandedIds;
  final int pageSize;
  final bool showAll;
  final int rootVisibleCount;
  final Map<int, int> childVisibleCounts;
  final int searchVisibleCount;
  final int totalRootCount;
  final int totalSearchMatchCount;
  final bool hasMoreRoots;
  final bool hasMoreSearch;
  final String? errorMessage;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  int childVisibleCountFor(int parentId) {
    if (showAll) {
      return 1 << 30;
    }
    return childVisibleCounts[parentId] ?? pageSize;
  }

  bool hasMoreChildren(Category parent) {
    if (showAll) {
      return false;
    }
    return parent.children.length > childVisibleCountFor(parent.id);
  }

  CategoryLoaded copyWith({
    List<Category>? allCategories,
    List<Category>? visibleCategories,
    List<Category>? flatCategories,
    String? searchQuery,
    Set<int>? expandedIds,
    int? pageSize,
    bool? showAll,
    int? rootVisibleCount,
    Map<int, int>? childVisibleCounts,
    int? searchVisibleCount,
    int? totalRootCount,
    int? totalSearchMatchCount,
    bool? hasMoreRoots,
    bool? hasMoreSearch,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CategoryLoaded(
      allCategories: allCategories ?? this.allCategories,
      visibleCategories: visibleCategories ?? this.visibleCategories,
      flatCategories: flatCategories ?? this.flatCategories,
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
      hasMoreRoots: hasMoreRoots ?? this.hasMoreRoots,
      hasMoreSearch: hasMoreSearch ?? this.hasMoreSearch,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        allCategories,
        visibleCategories,
        flatCategories,
        searchQuery,
        expandedIds,
        pageSize,
        showAll,
        rootVisibleCount,
        childVisibleCounts,
        searchVisibleCount,
        totalRootCount,
        totalSearchMatchCount,
        hasMoreRoots,
        hasMoreSearch,
        errorMessage,
      ];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
