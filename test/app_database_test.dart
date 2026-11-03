import 'package:category_manager/core/database/app_database.dart';
import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/categories/data/category_local_data_source.dart';
import 'package:category_manager/features/categories/data/category_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = CategoryRepositoryImpl(CategoryLocalDataSource(database));
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts a category and reads it back', () async {
    await repository.addCategory(name: 'Books');

    final categories = await repository.getFlatCategories();

    expect(categories.length, 1);
    expect(categories.first.name, 'Books');
    expect(categories.first.parentId, isNull);
  });

  test('rejects duplicate sibling names', () async {
    await repository.addCategory(name: 'Books');

    expect(
      () => repository.addCategory(name: 'books'),
      throwsA(isA<AppException>()),
    );
  });

  test('allows the same name under a different parent', () async {
    await repository.addCategory(name: 'Books');
    final parent = (await repository.getFlatCategories()).first;
    await repository.addCategory(name: 'Books', parentId: parent.id);

    final categories = await repository.getFlatCategories();
    expect(categories.length, 2);
  });

  test('deletes a category and its descendants in one transaction', () async {
    await repository.addCategory(name: 'Books');
    final books = (await repository.getFlatCategories()).first;
    await repository.addCategory(name: 'Fiction', parentId: books.id);
    final fiction = (await repository.getFlatCategories())
        .firstWhere((category) => category.name == 'Fiction');
    await repository.addCategory(name: 'Sci-Fi', parentId: fiction.id);

    await repository.deleteCategory(books.id);

    final remaining = await repository.getFlatCategories();
    expect(remaining, isEmpty);
  });
}
