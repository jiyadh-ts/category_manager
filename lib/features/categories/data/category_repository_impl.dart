import '../../../core/errors/app_exception.dart';
import '../domain/category_helpers.dart';
import '../domain/category_repository.dart';
import '../domain/entities/category.dart';
import 'category_local_data_source.dart';
import 'models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._localDataSource);

  final CategoryLocalDataSource _localDataSource;

  @override
  Future<CategoryStats> getCategoryStats(int userId) async {
    final total = await _localDataSource.countAll(userId);
    final roots = await _localDataSource.countRoots(userId);
    return CategoryStats(total: total, roots: roots);
  }

  @override
  Future<List<Category>> fetchRoots({
    required int userId,
    required int limit,
    int offset = 0,
  }) async {
    final rows = await _localDataSource.getRootCategories(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<Category>> fetchChildren({
    required int userId,
    required int parentId,
    required int limit,
    int offset = 0,
  }) async {
    final rows = await _localDataSource.getChildCategories(
      userId: userId,
      parentId: parentId,
      limit: limit,
      offset: offset,
    );
    return rows.map(_toEntity).toList();
  }

  @override
  Future<CategorySearchPage> fetchSearchPage({
    required int userId,
    required String query,
    required int limit,
    int offset = 0,
  }) async {
    final totalMatches = await _localDataSource.countSearchMatches(
      userId: userId,
      query: query,
    );
    if (totalMatches == 0) {
      return const CategorySearchPage(tree: [], totalMatches: 0);
    }

    final matchRows = await _localDataSource.searchCategories(
      userId: userId,
      query: query,
      limit: limit,
      offset: offset,
    );

    final byId = <int, Category>{};
    final matchIds = <int>{};

    for (final match in matchRows) {
      matchIds.add(match.id);
      final chain = await _localDataSource.getAncestorChain(userId, match.id);
      final path = chain.map((c) => c.name).join(' > ');
      for (final node in chain) {
        byId.putIfAbsent(
          node.id,
          () => _toEntity(
            node,
            path: node.id == match.id ? path : null,
          ),
        );
        if (node.id == match.id) {
          byId[node.id] = _toEntity(node, path: path);
        }
      }
    }

    final flatList = byId.values.toList();
    final tree = buildTreeFromMatches(
      flatList,
      flatList.where((c) => matchIds.contains(c.id)).toList(),
    );

    return CategorySearchPage(tree: tree, totalMatches: totalMatches);
  }

  @override
  Future<List<Category>> getSubtreeForRestore({
    required int userId,
    required int rootId,
  }) async {
    final rows = await _localDataSource.getSubtreeFlat(userId, rootId);
    return rows
        .map(
          (row) => Category(
            id: row.id,
            userId: row.userId,
            name: row.name,
            parentId: row.parentId,
            createdAt: row.createdAt,
            childCount: 0,
            children: const [],
          ),
        )
        .toList();
  }

  @override
  Future<void> addCategory({
    required int userId,
    required String name,
    int? parentId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppException('Category name cannot be empty.');
    }

    if (parentId != null) {
      final parent =
          await _localDataSource.getCategoryById(userId, parentId);
      if (parent == null) {
        throw const AppException('Parent category was not found.');
      }
    }

    final isDuplicate = await _localDataSource.hasSiblingWithName(
      userId: userId,
      name: trimmedName,
      parentId: parentId,
    );
    if (isDuplicate) {
      throw const AppException(
        'A category with this name already exists under the same parent.',
      );
    }

    try {
      await _localDataSource.insertCategory(
        userId: userId,
        name: trimmedName,
        parentId: parentId,
        createdAt: DateTime.now(),
      );
    } catch (error) {
      throw AppException('Could not save the category. $error');
    }
  }

  @override
  Future<void> updateCategory({
    required int userId,
    required int id,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppException('Category name cannot be empty.');
    }

    final existing = await _localDataSource.getCategoryById(userId, id);
    if (existing == null) {
      throw const AppException('Category was not found.');
    }

    final isDuplicate = await _localDataSource.hasSiblingWithName(
      userId: userId,
      name: trimmedName,
      parentId: existing.parentId,
      excludeId: id,
    );
    if (isDuplicate) {
      throw const AppException(
        'A category with this name already exists under the same parent.',
      );
    }

    try {
      await _localDataSource.updateCategory(
        userId: userId,
        id: id,
        name: trimmedName,
        parentId: existing.parentId,
      );
    } catch (error) {
      throw AppException('Could not update the category. $error');
    }
  }

  @override
  Future<void> deleteCategory({
    required int userId,
    required int id,
  }) async {
    final subtree = await _localDataSource.getSubtreeFlat(userId, id);
    if (subtree.isEmpty) {
      throw const AppException('Category was not found.');
    }

    // Children first so foreign keys stay valid during delete.
    final idsToDelete =
        subtree.reversed.map((category) => category.id).toList();

    try {
      await _localDataSource.deleteCategories(userId, idsToDelete);
    } catch (error) {
      throw AppException('Could not delete the category. $error');
    }
  }

  @override
  Future<void> restoreDeletedCategories({
    required int userId,
    required List<Category> snapshot,
  }) async {
    if (snapshot.isEmpty) {
      return;
    }

    try {
      await _localDataSource.restoreCategories(
        userId: userId,
        snapshot: snapshot
            .map(
              (category) => CategoryModel(
                id: category.id,
                userId: userId,
                name: category.name,
                parentId: category.parentId,
                createdAt: category.createdAt,
              ),
            )
            .toList(),
      );
    } catch (error) {
      throw AppException('Could not restore the category. $error');
    }
  }

  @override
  Future<void> claimOrphanCategories(int userId) async {
    await _localDataSource.claimOrphanCategories(userId);
  }

  Category _toEntity(CategoryModel model, {String? path}) {
    return Category(
      id: model.id,
      userId: model.userId,
      name: model.name,
      parentId: model.parentId,
      createdAt: model.createdAt,
      childCount: model.childCount,
      path: path,
    );
  }
}
