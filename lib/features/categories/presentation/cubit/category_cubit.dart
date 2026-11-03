import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/category_helpers.dart';
import '../../domain/category_repository.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._repository) : super(const CategoryInitial());

  final CategoryRepository _repository;

  String _searchQuery = '';
  Set<int> _expandedIds = <int>{};

  Future<void> loadCategories() async {
    emit(const CategoryLoading());
    await _reloadCategories();
  }

  Future<void> addCategory({
    required String name,
    int? parentId,
  }) async {
    try {
      await _repository.addCategory(name: name, parentId: parentId);
      await _reloadCategories();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
  }) async {
    try {
      await _repository.updateCategory(id: id, name: name);
      await _reloadCategories();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      _expandedIds.remove(id);
      await _reloadCategories();
    } catch (error) {
      _emitMutationError(error);
    }
  }

  void search(String query) {
    _searchQuery = query;
    final currentState = state;
    if (currentState is! CategoryLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        searchQuery: _searchQuery,
        visibleCategories: searchCategories(
          currentState.allCategories,
          _searchQuery,
        ),
        clearErrorMessage: true,
      ),
    );
  }

  void clearErrorMessage() {
    final currentState = state;
    if (currentState is CategoryLoaded && currentState.errorMessage != null) {
      emit(currentState.copyWith(clearErrorMessage: true));
    }
  }

  void toggleExpanded(int categoryId) {
    final currentState = state;
    if (currentState is! CategoryLoaded) {
      return;
    }

    final updatedIds = Set<int>.from(_expandedIds);
    if (updatedIds.contains(categoryId)) {
      updatedIds.remove(categoryId);
    } else {
      updatedIds.add(categoryId);
    }
    _expandedIds = updatedIds;

    emit(currentState.copyWith(expandedIds: updatedIds));
  }

  Future<void> _reloadCategories() async {
    try {
      final tree = await _repository.getCategoryTree();
      final flatList = await _repository.getFlatCategories();
      emit(
        CategoryLoaded(
          allCategories: tree,
          visibleCategories: searchCategories(tree, _searchQuery),
          flatCategories: flatList,
          searchQuery: _searchQuery,
          expandedIds: _expandedIds,
          totalCount: countCategories(tree),
        ),
      );
    } catch (error) {
      emit(CategoryError(_errorMessage(error)));
    }
  }

  void _emitMutationError(Object error) {
    final currentState = state;
    final message = _errorMessage(error);
    if (currentState is CategoryLoaded) {
      emit(currentState.copyWith(errorMessage: message));
      return;
    }
    emit(CategoryError(message));
  }

  String _errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
