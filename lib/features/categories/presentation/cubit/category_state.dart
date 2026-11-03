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
    required this.totalCount,
    this.errorMessage,
  });

  final List<Category> allCategories;
  final List<Category> visibleCategories;
  final List<Category> flatCategories;
  final String searchQuery;
  final Set<int> expandedIds;
  final int totalCount;
  final String? errorMessage;

  CategoryLoaded copyWith({
    List<Category>? allCategories,
    List<Category>? visibleCategories,
    List<Category>? flatCategories,
    String? searchQuery,
    Set<int>? expandedIds,
    int? totalCount,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CategoryLoaded(
      allCategories: allCategories ?? this.allCategories,
      visibleCategories: visibleCategories ?? this.visibleCategories,
      flatCategories: flatCategories ?? this.flatCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedIds: expandedIds ?? this.expandedIds,
      totalCount: totalCount ?? this.totalCount,
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
        totalCount,
        errorMessage,
      ];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
