import 'entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategoryTree();

  Future<List<Category>> getFlatCategories();

  Future<void> addCategory({
    required String name,
    int? parentId,
  });

  Future<void> updateCategory({
    required int id,
    required String name,
  });

  Future<void> deleteCategory(int id);
}
