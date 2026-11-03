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
  Future<List<Category>> getCategoryTree() async {
    final flatList = await getFlatCategories();
    return buildCategoryTree(flatList);
  }

  @override
  Future<List<Category>> getFlatCategories() async {
    final rows = await _localDataSource.getAllCategories();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> addCategory({
    required String name,
    int? parentId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppException('Category name cannot be empty.');
    }

    final flatList = await getFlatCategories();

    if (parentId != null) {
      final parentExists = flatList.any((category) => category.id == parentId);
      if (!parentExists) {
        throw const AppException('Parent category was not found.');
      }
    }

    final isDuplicate = hasDuplicateSibling(
      flatList: flatList,
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
    required int id,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppException('Category name cannot be empty.');
    }

    final flatList = await getFlatCategories();
    Category? existing;
    for (final category in flatList) {
      if (category.id == id) {
        existing = category;
        break;
      }
    }

    if (existing == null) {
      throw const AppException('Category was not found.');
    }

    final isDuplicate = hasDuplicateSibling(
      flatList: flatList,
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
        id: id,
        name: trimmedName,
        parentId: existing.parentId,
      );
    } catch (error) {
      throw AppException('Could not update the category. $error');
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    final flatList = await getFlatCategories();
    final exists = flatList.any((category) => category.id == id);
    if (!exists) {
      throw const AppException('Category was not found.');
    }

    // Children are listed first so foreign keys stay valid during delete.
    final idsToDelete = collectDescendantIds(flatList, id);

    try {
      await _localDataSource.deleteCategories(idsToDelete);
    } catch (error) {
      throw AppException('Could not delete the category. $error');
    }
  }

  Category _toEntity(CategoryModel model) {
    return Category(
      id: model.id,
      name: model.name,
      parentId: model.parentId,
      createdAt: model.createdAt,
    );
  }
}
