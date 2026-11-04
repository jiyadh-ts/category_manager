import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
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
  List<Category> _pendingRestore = const [];
  String? _pendingUndoMessage;
  int _refreshToken = 0;

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
      if (parentId != null) {
        _expandedIds = Set<int>.from(_expandedIds)..add(parentId);
        _childVisibleCounts.putIfAbsent(parentId, () => _effectivePageSize);
      }
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

    final currentState = state;
    if (currentState is! CategoryLoaded) {
      return;
    }

    try {
      final snapshot = await _repository.getSubtreeForRestore(
        userId: userId,
        rootId: id,
      );
      if (snapshot.isEmpty) {
        throw const AppException('Category was not found.');
      }

      final deletedName = snapshot.first.name;
      _pendingRestore = snapshot;
      _pendingUndoMessage = 'Category "$deletedName" deleted.';

      await _repository.deleteCategory(userId: userId, id: id);
      _expandedIds.remove(id);
      _childVisibleCounts.remove(id);
      await _reloadCategories(userId, keepUndoMessage: true);
    } catch (error) {
      _pendingRestore = const [];
      _pendingUndoMessage = null;
      _emitMutationError(error);
    }
  }

  Future<void> undoDelete() async {
    final userId = _requireUserId();
    if (userId == null || _pendingRestore.isEmpty) {
      return;
    }

    try {
      final snapshot = List<Category>.from(_pendingRestore);
      _pendingRestore = const [];
      _pendingUndoMessage = null;
      await _repository.restoreDeletedCategories(
        userId: userId,
        snapshot: snapshot,
      );
      await _reloadCategories(userId);
    } catch (error) {
      _emitMutationError(error);
    }
  }

  void clearUndoMessage() {
    _pendingUndoMessage = null;
    final currentState = state;
    if (currentState is CategoryLoaded && currentState.undoMessage != null) {
      emit(currentState.copyWith(clearUndoMessage: true));
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    _searchVisibleCount = _effectivePageSize;
    if (query.trim().isEmpty) {
      _rootVisibleCount = _effectivePageSize;
    }
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await _reloadCategories(userId);
  }

  /// [size] null means All; otherwise 10 / 20 / 50.
  Future<void> setPageSize(int? size) async {
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
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await _reloadCategories(userId);
  }

  Future<void> loadMoreRoots() async {
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
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await _reloadCategories(userId);
  }

  Future<void> loadMoreChildren(int parentId) async {
    final currentState = state;
    if (currentState is! CategoryLoaded ||
        currentState.isSearching ||
        _showAll) {
      return;
    }
    final current = _childVisibleCounts[parentId] ?? _pageSize;
    _childVisibleCounts = Map<int, int>.from(_childVisibleCounts)
      ..[parentId] = current + _pageSize;
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await _reloadCategories(userId);
  }

  Future<void> loadMoreSearch() async {
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
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await _reloadCategories(userId);
  }

  void clearErrorMessage() {
    final currentState = state;
    if (currentState is CategoryLoaded && currentState.errorMessage != null) {
      emit(currentState.copyWith(clearErrorMessage: true));
    }
  }

  Future<void> toggleExpanded(int categoryId) async {
    final currentState = state;
    if (currentState is! CategoryLoaded || currentState.isSearching) {
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

    final userId = _currentUserId;
    if (userId == null) {
      return;
    }
    await _reloadCategories(userId);
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

  Future<void> _reloadCategories(
    int userId, {
    bool keepUndoMessage = false,
  }) async {
    final token = ++_refreshToken;
    try {
      final stats = await _repository.getCategoryStats(userId);
      if (token != _refreshToken) {
        return;
      }

      final isSearching = _searchQuery.trim().isNotEmpty;
      if (isSearching) {
        final limit = _showAll ? _allPageSize : _searchVisibleCount;
        final page = await _repository.fetchSearchPage(
          userId: userId,
          query: _searchQuery,
          limit: limit,
        );
        if (token != _refreshToken) {
          return;
        }

        emit(
          CategoryLoaded(
            visibleCategories: page.tree,
            searchQuery: _searchQuery,
            expandedIds: _expandedIds,
            pageSize: _pageSize,
            showAll: _showAll,
            rootVisibleCount: _rootVisibleCount,
            childVisibleCounts: Map<int, int>.from(_childVisibleCounts),
            searchVisibleCount: page.totalMatches == 0
                ? 0
                : (limit > page.totalMatches ? page.totalMatches : limit),
            totalRootCount: stats.roots,
            totalSearchMatchCount: page.totalMatches,
            totalCategories: stats.total,
            nestedCount: stats.nested,
            hasMoreRoots: false,
            hasMoreSearch: !_showAll && page.totalMatches > limit,
            undoMessage: keepUndoMessage ? _pendingUndoMessage : null,
          ),
        );
      } else {
        final rootLimit = _showAll ? _allPageSize : _rootVisibleCount;
        final roots = await _repository.fetchRoots(
          userId: userId,
          limit: rootLimit,
        );
        if (token != _refreshToken) {
          return;
        }

        final visible = await _attachExpandedChildren(
          userId: userId,
          nodes: roots,
          token: token,
        );
        if (token != _refreshToken || visible == null) {
          return;
        }

        emit(
          CategoryLoaded(
            visibleCategories: visible,
            searchQuery: _searchQuery,
            expandedIds: _expandedIds,
            pageSize: _pageSize,
            showAll: _showAll,
            rootVisibleCount: stats.roots == 0
                ? 0
                : (rootLimit > stats.roots ? stats.roots : rootLimit),
            childVisibleCounts: Map<int, int>.from(_childVisibleCounts),
            searchVisibleCount: _searchVisibleCount,
            totalRootCount: stats.roots,
            totalSearchMatchCount: 0,
            totalCategories: stats.total,
            nestedCount: stats.nested,
            hasMoreRoots: !_showAll && stats.roots > rootLimit,
            hasMoreSearch: false,
            undoMessage: keepUndoMessage ? _pendingUndoMessage : null,
          ),
        );
      }

      if (!keepUndoMessage) {
        _pendingUndoMessage = null;
      }
    } catch (error) {
      if (token != _refreshToken) {
        return;
      }
      emit(CategoryError(_errorMessage(error)));
    }
  }

  Future<List<Category>?> _attachExpandedChildren({
    required int userId,
    required List<Category> nodes,
    required int token,
  }) async {
    final result = <Category>[];
    for (final node in nodes) {
      if (token != _refreshToken) {
        return null;
      }

      if (!_expandedIds.contains(node.id) || node.childCount == 0) {
        result.add(node.copyWith(children: const []));
        continue;
      }

      final childLimit = _showAll
          ? _allPageSize
          : (_childVisibleCounts[node.id] ?? _effectivePageSize);
      final children = await _repository.fetchChildren(
        userId: userId,
        parentId: node.id,
        limit: childLimit,
      );
      if (token != _refreshToken) {
        return null;
      }

      final nested = await _attachExpandedChildren(
        userId: userId,
        nodes: children,
        token: token,
      );
      if (nested == null) {
        return null;
      }

      result.add(node.copyWith(children: nested));
    }
    return result;
  }

  void _clearUserScopedUiState() {
    _searchQuery = '';
    _expandedIds = <int>{};
    _pageSize = defaultPageSize;
    _showAll = false;
    _rootVisibleCount = defaultPageSize;
    _childVisibleCounts = <int, int>{};
    _searchVisibleCount = defaultPageSize;
    _pendingRestore = const [];
    _pendingUndoMessage = null;
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
