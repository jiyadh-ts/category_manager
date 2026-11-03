import '../../../core/database/app_database.dart';
import 'models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._database);

  final AppDatabase _database;

  Future<List<CategoryModel>> getAllCategories() {
    return _database.getAllCategories();
  }

  Future<CategoryModel?> getCategoryById(int id) {
    return _database.getCategoryById(id);
  }

  Future<int> insertCategory({
    required String name,
    int? parentId,
    required DateTime createdAt,
  }) {
    return _database.insertCategory(
      name: name,
      parentId: parentId,
      createdAt: createdAt,
    );
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    int? parentId,
  }) {
    return _database.updateCategory(
      id: id,
      name: name,
      parentId: parentId,
    );
  }

  Future<void> deleteCategories(List<int> ids) {
    return _database.deleteCategories(ids);
  }
}
