import '../../../core/database/app_database.dart';
import 'models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._database);

  final AppDatabase _database;

  Future<List<CategoryModel>> getCategories(int userId) {
    return _database.getCategories(userId);
  }

  Future<CategoryModel?> getCategoryById(int userId, int id) {
    return _database.getCategoryById(userId, id);
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

  Future<int> claimOrphanCategories(int userId) {
    return _database.claimOrphanCategories(userId);
  }
}
