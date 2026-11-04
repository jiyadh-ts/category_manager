import 'entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategoryTree(int userId);

  Future<List<Category>> getFlatCategories(int userId);

  Future<void> addCategory({
    required int userId,
    required String name,
    int? parentId,
  });

  Future<void> updateCategory({
    required int userId,
    required int id,
    required String name,
  });

  Future<void> deleteCategory({
    required int userId,
    required int id,
  });

  /// Assigns legacy orphan categories (user_id = 0) to [userId].
  Future<void> claimOrphanCategories(int userId);
}
