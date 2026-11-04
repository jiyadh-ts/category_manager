import 'package:category_manager/core/database/app_database.dart';
import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/categories/data/category_local_data_source.dart';
import 'package:category_manager/features/categories/data/category_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryRepositoryImpl repository;

  const userA = 1;
  const userB = 2;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepositoryImpl(CategoryLocalDataSource(database));
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts a category and reads it back for the same user', () async {
    await repository.addCategory(userId: userA, name: 'Books');

    final categories = await repository.getFlatCategories(userA);

    expect(categories.length, 1);
    expect(categories.first.name, 'Books');
    expect(categories.first.userId, userA);
    expect(categories.first.parentId, isNull);
  });

  test('rejects duplicate sibling names for the same user', () async {
    await repository.addCategory(userId: userA, name: 'Books');

    expect(
      () => repository.addCategory(userId: userA, name: 'books'),
      throwsA(isA<AppException>()),
    );
  });

  test('allows the same sibling name for different users', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    await repository.addCategory(userId: userB, name: 'Books');

    final forA = await repository.getFlatCategories(userA);
    final forB = await repository.getFlatCategories(userB);

    expect(forA.single.name, 'Books');
    expect(forB.single.name, 'Books');
  });

  test('allows the same name under a different parent', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final parent = (await repository.getFlatCategories(userA)).first;
    await repository.addCategory(
      userId: userA,
      name: 'Books',
      parentId: parent.id,
    );

    final categories = await repository.getFlatCategories(userA);
    expect(categories.length, 2);
  });

  test('hides one user categories from another user', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    await repository.addCategory(userId: userB, name: 'Games');

    final forA = await repository.getFlatCategories(userA);
    final forB = await repository.getFlatCategories(userB);

    expect(forA.map((c) => c.name), ['Books']);
    expect(forB.map((c) => c.name), ['Games']);
  });

  test('does not update another users category', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books = (await repository.getFlatCategories(userA)).first;

    expect(
      () => repository.updateCategory(
        userId: userB,
        id: books.id,
        name: 'Hacked',
      ),
      throwsA(isA<AppException>()),
    );

    final stillBooks = (await repository.getFlatCategories(userA)).first;
    expect(stillBooks.name, 'Books');
  });

  test('does not delete another users category', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books = (await repository.getFlatCategories(userA)).first;

    expect(
      () => repository.deleteCategory(userId: userB, id: books.id),
      throwsA(isA<AppException>()),
    );

    final remaining = await repository.getFlatCategories(userA);
    expect(remaining.single.name, 'Books');
  });

  test('deletes a category and its descendants in one transaction', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books = (await repository.getFlatCategories(userA)).first;
    await repository.addCategory(
      userId: userA,
      name: 'Fiction',
      parentId: books.id,
    );
    final fiction = (await repository.getFlatCategories(userA))
        .firstWhere((category) => category.name == 'Fiction');
    await repository.addCategory(
      userId: userA,
      name: 'Sci-Fi',
      parentId: fiction.id,
    );

    await repository.deleteCategory(userId: userA, id: books.id);

    final remaining = await repository.getFlatCategories(userA);
    expect(remaining, isEmpty);
  });

  test('claims orphan categories for the first user', () async {
    await database.insertCategory(
      userId: 0,
      name: 'Legacy',
      createdAt: DateTime(2026, 1, 1),
    );

    await repository.claimOrphanCategories(userA);

    final forA = await repository.getFlatCategories(userA);
    final forB = await repository.getFlatCategories(userB);

    expect(forA.single.name, 'Legacy');
    expect(forA.single.userId, userA);
    expect(forB, isEmpty);
  });
}
