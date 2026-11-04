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
  Future<List<Category>> getCategoryTree(int userId) async {
    final flatList = await getFlatCategories(userId);
    return buildCategoryTree(flatList);
  }

  @override
  Future<List<Category>> getFlatCategories(int userId) async {
    final rows = await _localDataSource.getCategories(userId);
    return rows.map(_toEntity).toList();
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

    final flatList = await getFlatCategories(userId);

    if (parentId != null) {
      Category? parent;
      for (final category in flatList) {
        if (category.id == parentId) {
          parent = category;
          break;
        }
      }
      if (parent == null || parent.userId != userId) {
        throw const AppException('Parent category was not found.');
      }
    }

    final isDuplicate = hasDuplicateSibling(
      flatList: flatList,
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

    final existingModel = await _localDataSource.getCategoryById(userId, id);
    if (existingModel == null) {
      throw const AppException('Category was not found.');
    }
    final existing = _toEntity(existingModel);

    final flatList = await getFlatCategories(userId);
    final isDuplicate = hasDuplicateSibling(
      flatList: flatList,
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
    final existing = await _localDataSource.getCategoryById(userId, id);
    if (existing == null) {
      throw const AppException('Category was not found.');
    }

    final flatList = await getFlatCategories(userId);
    // Children are listed first so foreign keys stay valid during delete.
    final idsToDelete = collectDescendantIds(flatList, id);

    try {
      await _localDataSource.deleteCategories(userId, idsToDelete);
    } catch (error) {
      throw AppException('Could not delete the category. $error');
    }
  }

  @override
  Future<void> claimOrphanCategories(int userId) async {
    await _localDataSource.claimOrphanCategories(userId);
  }

  Category _toEntity(CategoryModel model) {
    return Category(
      id: model.id,
      userId: model.userId,
      name: model.name,
      parentId: model.parentId,
      createdAt: model.createdAt,
    );
  }
}
