import 'entities/category.dart';

abstract class CategoryRepository {
  Future<CategoryStats> getCategoryStats(int userId);

  Future<List<Category>> fetchRoots({
    required int userId,
    required int limit,
    int offset = 0,
  });

  Future<List<Category>> fetchChildren({
    required int userId,
    required int parentId,
    required int limit,
    int offset = 0,
  });

  Future<CategorySearchPage> fetchSearchPage({
    required int userId,
    required String query,
    required int limit,
    int offset = 0,
  });

  /// Parent-before-child flat snapshot for undo restore.
  Future<List<Category>> getSubtreeForRestore({
    required int userId,
    required int rootId,
  });

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

  /// Re-inserts a deleted subtree. [snapshot] must be parent-before-child.
  Future<void> restoreDeletedCategories({
    required int userId,
    required List<Category> snapshot,
  });

  /// Assigns legacy orphan categories (user_id = 0) to [userId].
  Future<void> claimOrphanCategories(int userId);
}
