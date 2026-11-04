import '../../../core/database/app_database.dart';
import 'models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._database);

  final AppDatabase _database;

  Future<List<CategoryModel>> getRootCategories({
    required int userId,
    required int limit,
    int offset = 0,
  }) {
    return _database.getRootCategories(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<CategoryModel>> getChildCategories({
    required int userId,
    required int parentId,
    required int limit,
    int offset = 0,
  }) {
    return _database.getChildCategories(
      userId: userId,
      parentId: parentId,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> countAll(int userId) => _database.countAll(userId);

  Future<int> countRoots(int userId) => _database.countRoots(userId);

  Future<int> countChildren(int userId, int parentId) {
    return _database.countChildren(userId, parentId);
  }

  Future<List<CategoryModel>> searchCategories({
    required int userId,
    required String query,
    required int limit,
    int offset = 0,
  }) {
    return _database.searchCategories(
      userId: userId,
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> countSearchMatches({
    required int userId,
    required String query,
  }) {
    return _database.countSearchMatches(userId: userId, query: query);
  }

  Future<CategoryModel?> getCategoryById(int userId, int id) {
    return _database.getCategoryById(userId, id);
  }

  Future<List<CategoryModel>> getAncestorChain(int userId, int id) {
    return _database.getAncestorChain(userId, id);
  }

  Future<List<CategoryModel>> getSubtreeFlat(int userId, int rootId) {
    return _database.getSubtreeFlat(userId, rootId);
  }

  Future<bool> hasSiblingWithName({
    required int userId,
    required String name,
    required int? parentId,
    int? excludeId,
  }) {
    return _database.hasSiblingWithName(
      userId: userId,
      name: name,
      parentId: parentId,
      excludeId: excludeId,
    );
  }

  Future<int> insertCategory({
    required int userId,
    required String name,
    int? parentId,
    required DateTime createdAt,
  }) {
    return _database.insertCategory(
      userId: userId,
      name: name,
      parentId: parentId,
      createdAt: createdAt,
    );
  }

  Future<void> updateCategory({
    required int userId,
    required int id,
    required String name,
    int? parentId,
  }) {
    return _database.updateCategory(
      userId: userId,
      id: id,
      name: name,
      parentId: parentId,
    );
  }

  Future<void> deleteCategories(int userId, List<int> ids) {
    return _database.deleteCategories(userId, ids);
  }

  Future<Map<int, int>> restoreCategories({
    required int userId,
    required List<CategoryModel> snapshot,
  }) {
    return _database.restoreCategories(userId: userId, snapshot: snapshot);
  }

  Future<int> claimOrphanCategories(int userId) {
    return _database.claimOrphanCategories(userId);
  }
}
