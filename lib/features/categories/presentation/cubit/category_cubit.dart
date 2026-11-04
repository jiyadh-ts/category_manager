import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/category_helpers.dart';
import '../../domain/category_repository.dart';
import '../../domain/entities/category.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(
    this._repository, {
    required AuthCubit authCubit,
  })  : _authCubit = authCubit,
        super(const CategoryInitial()) {
    _onAuthState(_authCubit.state);
    _authSubscription = _authCubit.stream.listen(_onAuthState);
  }

  static const int defaultPageSize = 10;
  static const int _allPageSize = 1 << 30;

  final CategoryRepository _repository;
  final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSubscription;

  int? _currentUserId;
  String _searchQuery = '';
  Set<int> _expandedIds = <int>{};
  int _pageSize = defaultPageSize;
  bool _showAll = false;
  int _rootVisibleCount = defaultPageSize;
  Map<int, int> _childVisibleCounts = <int, int>{};
  int _searchVisibleCount = defaultPageSize;

  int get _effectivePageSize => _showAll ? _allPageSize : _pageSize;

  Future<void> loadCategories() async {
    final userId = _currentUserId;
    if (userId == null) {
      emit(const CategoryInitial());
      return;
    }

    emit(const CategoryLoading());
    await _reloadCategories(userId);
  }

  Future<void> addCategory({
    required String name,
    int? parentId,
  }) async {
    final userId = _requireUserId();
    if (userId == null) {
      return;
    }

    try {
      await _repository.addCategory(
        userId: userId,
        name: name,
        parentId: parentId,
      );
      await _reloadCategories(userId);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
  }) async {
    final userId = _requireUserId();
    if (userId == null) {
      return;
    }

    try {
      await _repository.updateCategory(
        userId: userId,
        id: id,
        name: name,
      );
      await _reloadCategories(userId);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  Future<void> deleteCategory(int id) async {
    final userId = _requireUserId();
    if (userId == null) {
      return;
    }

    try {
      await _repository.deleteCategory(userId: userId, id: id);
      _expandedIds.remove(id);
      _childVisibleCounts.remove(id);
      await _reloadCategories(userId);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  void search(String query) {
    _searchQuery = query;
    _searchVisibleCount = _effectivePageSize;
    if (query.trim().isEmpty) {
      _rootVisibleCount = _effectivePageSize;
    }
    _emitVisibleFromCurrent();
  }

  /// [size] null means All; otherwise 10 / 20 / 50.
  void setPageSize(int? size) {
    if (size == null) {
      _showAll = true;
      _pageSize = defaultPageSize;
    } else {
      _showAll = false;
      _pageSize = size;
    }
    _rootVisibleCount = _effectivePageSize;
    _searchVisibleCount = _effectivePageSize;
    _childVisibleCounts = <int, int>{};
    for (final id in _expandedIds) {
      _childVisibleCounts[id] = _effectivePageSize;
    }
    _emitVisibleFromCurrent();
  }

  void loadMoreRoots() {
    final currentState = state;
    if (currentState is! CategoryLoaded ||
        currentState.isSearching ||
        _showAll) {
      return;
    }
    if (!currentState.hasMoreRoots) {
      return;
    }
    _rootVisibleCount += _pageSize;
    _emitVisibleFromCurrent();
  }

  void loadMoreChildren(int parentId) {
    final currentState = state;
    if (currentState is! CategoryLoaded ||
        currentState.isSearching ||
        _showAll) {
      return;
    }
    final current = _childVisibleCounts[parentId] ?? _pageSize;
    _childVisibleCounts = Map<int, int>.from(_childVisibleCounts)
      ..[parentId] = current + _pageSize;
    emit(currentState.copyWith(childVisibleCounts: _childVisibleCounts));
  }

  void loadMoreSearch() {
    final currentState = state;
    if (currentState is! CategoryLoaded ||
        !currentState.isSearching ||
        _showAll) {
      return;
    }
    if (!currentState.hasMoreSearch) {
      return;
    }
    _searchVisibleCount += _pageSize;
    _emitVisibleFromCurrent();
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
      _childVisibleCounts.putIfAbsent(categoryId, () => _effectivePageSize);
    }
    _expandedIds = updatedIds;

    emit(
      currentState.copyWith(
        expandedIds: updatedIds,
        childVisibleCounts: Map<int, int>.from(_childVisibleCounts),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }

  void _onAuthState(AuthState authState) {
    if (authState is AuthSuccess) {
      final userId = authState.user.id;
      if (_currentUserId == userId && state is CategoryLoaded) {
        return;
      }
      _currentUserId = userId;
      _clearUserScopedUiState();
      unawaited(_loadForUser(userId));
      return;
    }

    _currentUserId = null;
    _clearUserScopedUiState();
    emit(const CategoryInitial());
  }

  Future<void> _loadForUser(int userId) async {
    emit(const CategoryLoading());
    try {
      await _repository.claimOrphanCategories(userId);
      await _reloadCategories(userId);
    } catch (error) {
      emit(CategoryError(_errorMessage(error)));
    }
  }

  Future<void> _reloadCategories(int userId) async {
    try {
      final tree = await _repository.getCategoryTree(userId);
      final flatList = await _repository.getFlatCategories(userId);
      emit(_buildLoadedState(tree: tree, flatList: flatList));
    } catch (error) {
      emit(CategoryError(_errorMessage(error)));
    }
  }

  void _emitVisibleFromCurrent() {
    final currentState = state;
    if (currentState is! CategoryLoaded) {
      return;
    }

    emit(
      _buildLoadedState(
        tree: currentState.allCategories,
        flatList: currentState.flatCategories,
      ),
    );
  }

  CategoryLoaded _buildLoadedState({
    required List<Category> tree,
    required List<Category> flatList,
  }) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    if (isSearching) {
      final matches = collectMatchingCategories(tree, _searchQuery);
      final visibleCount =
          _showAll ? matches.length : _searchVisibleCount;
      final visibleMatches = takeFirstCategories(matches, visibleCount);
      return CategoryLoaded(
        allCategories: tree,
        visibleCategories: buildTreeFromMatches(flatList, visibleMatches),
        flatCategories: flatList,
        searchQuery: _searchQuery,
        expandedIds: _expandedIds,
        pageSize: _pageSize,
        showAll: _showAll,
        rootVisibleCount: _rootVisibleCount,
        childVisibleCounts: Map<int, int>.from(_childVisibleCounts),
        searchVisibleCount: visibleCount,
        totalRootCount: tree.length,
        totalSearchMatchCount: matches.length,
        hasMoreRoots: false,
        hasMoreSearch: !_showAll && matches.length > visibleCount,
      );
    }

    final visibleCount = _showAll ? tree.length : _rootVisibleCount;
    final visibleRoots = takeFirstCategories(tree, visibleCount);
    return CategoryLoaded(
      allCategories: tree,
      visibleCategories: visibleRoots,
      flatCategories: flatList,
      searchQuery: _searchQuery,
      expandedIds: _expandedIds,
      pageSize: _pageSize,
      showAll: _showAll,
      rootVisibleCount: visibleCount,
      childVisibleCounts: Map<int, int>.from(_childVisibleCounts),
      searchVisibleCount: _searchVisibleCount,
      totalRootCount: tree.length,
      totalSearchMatchCount: 0,
      hasMoreRoots: !_showAll && tree.length > visibleCount,
      hasMoreSearch: false,
    );
  }

  void _clearUserScopedUiState() {
    _searchQuery = '';
    _expandedIds = <int>{};
    _pageSize = defaultPageSize;
    _showAll = false;
    _rootVisibleCount = defaultPageSize;
    _childVisibleCounts = <int, int>{};
    _searchVisibleCount = defaultPageSize;
  }

  int? _requireUserId() {
    final userId = _currentUserId;
    if (userId == null) {
      emit(const CategoryError('You must be logged in to manage categories.'));
      return null;
    }
    return userId;
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
