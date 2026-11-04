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

  Future<List<String>> rootNames(int userId, {int limit = 1000}) async {
    final roots = await repository.fetchRoots(userId: userId, limit: limit);
    return roots.map((c) => c.name).toList();
  }

  test('inserts a category and reads it back for the same user', () async {
    await repository.addCategory(userId: userA, name: 'Books');

    final categories = await repository.fetchRoots(userId: userA, limit: 10);

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

    expect(await rootNames(userA), ['Books']);
    expect(await rootNames(userB), ['Books']);
  });

  test('allows the same name under a different parent', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final parent =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;
    await repository.addCategory(
      userId: userA,
      name: 'Books',
      parentId: parent.id,
    );

    final stats = await repository.getCategoryStats(userA);
    expect(stats.total, 2);
    expect(stats.roots, 1);
    expect(stats.nested, 1);
  });

  test('hides one user categories from another user', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    await repository.addCategory(userId: userB, name: 'Games');

    expect(await rootNames(userA), ['Books']);
    expect(await rootNames(userB), ['Games']);
  });

  test('does not update another users category', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;

    expect(
      () => repository.updateCategory(
        userId: userB,
        id: books.id,
        name: 'Hacked',
      ),
      throwsA(isA<AppException>()),
    );

    final stillBooks =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;
    expect(stillBooks.name, 'Books');
  });

  test('does not delete another users category', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;

    expect(
      () => repository.deleteCategory(userId: userB, id: books.id),
      throwsA(isA<AppException>()),
    );

    expect(await rootNames(userA), ['Books']);
  });

  test('deletes a category and its descendants in one transaction', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;
    await repository.addCategory(
      userId: userA,
      name: 'Fiction',
      parentId: books.id,
    );
    final fiction = (await repository.fetchChildren(
      userId: userA,
      parentId: books.id,
      limit: 10,
    ))
        .first;
    await repository.addCategory(
      userId: userA,
      name: 'Sci-Fi',
      parentId: fiction.id,
    );

    await repository.deleteCategory(userId: userA, id: books.id);

    final stats = await repository.getCategoryStats(userA);
    expect(stats.total, 0);
  });

  test('claims orphan categories for the first user', () async {
    await database.insertCategory(
      userId: 0,
      name: 'Legacy',
      createdAt: DateTime(2026, 1, 1),
    );

    await repository.claimOrphanCategories(userA);

    final forA = await repository.fetchRoots(userId: userA, limit: 10);
    final forB = await repository.fetchRoots(userId: userB, limit: 10);

    expect(forA.single.name, 'Legacy');
    expect(forA.single.userId, userA);
    expect(forB, isEmpty);
  });

  test('pages roots with LIMIT from the database', () async {
    for (var i = 1; i <= 15; i++) {
      await repository.addCategory(userId: userA, name: 'Root $i');
    }

    final firstPage = await repository.fetchRoots(userId: userA, limit: 10);
    final secondPage =
        await repository.fetchRoots(userId: userA, limit: 10, offset: 10);
    final stats = await repository.getCategoryStats(userA);

    expect(firstPage.length, 10);
    expect(secondPage.length, 5);
    expect(stats.roots, 15);
    expect(firstPage.first.name, 'Root 1');
    expect(secondPage.first.name, 'Root 11');
  });

  test('pages children with LIMIT and reports childCount', () async {
    await repository.addCategory(userId: userA, name: 'Books');
    final books =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;

    for (var i = 1; i <= 12; i++) {
      await repository.addCategory(
        userId: userA,
        name: 'Child $i',
        parentId: books.id,
      );
    }

    final refreshed =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;
    final page = await repository.fetchChildren(
      userId: userA,
      parentId: books.id,
      limit: 10,
    );

    expect(refreshed.childCount, 12);
    expect(page.length, 10);
    expect(page.first.name, 'Child 1');
  });

  test('search pages matches and builds ancestor path', () async {
    await repository.addCategory(userId: userA, name: 'Electronics');
    final electronics =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;
    await repository.addCategory(
      userId: userA,
      name: 'Mobiles',
      parentId: electronics.id,
    );
    final mobiles = (await repository.fetchChildren(
      userId: userA,
      parentId: electronics.id,
      limit: 10,
    ))
        .first;
    await repository.addCategory(
      userId: userA,
      name: 'Samsung',
      parentId: mobiles.id,
    );

    final page = await repository.fetchSearchPage(
      userId: userA,
      query: 'sam',
      limit: 10,
    );

    expect(page.totalMatches, 1);
    expect(page.tree.single.name, 'Electronics');
    expect(page.tree.single.children.single.name, 'Mobiles');
    expect(page.tree.single.children.single.children.single.name, 'Samsung');
    expect(
      page.tree.single.children.single.children.single.path,
      'Electronics > Mobiles > Samsung',
    );
  });

  test('restore remaps parent ids and keeps hierarchy', () async {
    await repository.addCategory(userId: userA, name: 'Keeper');
    final keeper =
        (await repository.fetchRoots(userId: userA, limit: 10)).first;
    await repository.addCategory(userId: userA, name: 'Books');
    final books = (await repository.fetchRoots(userId: userA, limit: 10))
        .firstWhere((category) => category.name == 'Books');
    await repository.addCategory(
      userId: userA,
      name: 'Fiction',
      parentId: books.id,
    );
    await repository.addCategory(
      userId: userA,
      name: 'Sci-Fi',
      parentId: (await repository.fetchChildren(
        userId: userA,
        parentId: books.id,
        limit: 10,
      ))
          .first
          .id,
    );

    final snapshot = await repository.getSubtreeForRestore(
      userId: userA,
      rootId: books.id,
    );
    final oldBooksId = books.id;

    await repository.deleteCategory(userId: userA, id: books.id);
    expect(await rootNames(userA), ['Keeper']);

    await repository.restoreDeletedCategories(
      userId: userA,
      snapshot: snapshot,
    );

    final restoredRoots =
        await repository.fetchRoots(userId: userA, limit: 10);
    final restoredBooks =
        restoredRoots.firstWhere((category) => category.name == 'Books');
    final restoredFiction = (await repository.fetchChildren(
      userId: userA,
      parentId: restoredBooks.id,
      limit: 10,
    ))
        .first;
    final restoredSciFi = (await repository.fetchChildren(
      userId: userA,
      parentId: restoredFiction.id,
      limit: 10,
    ))
        .first;

    expect(restoredBooks.id, isNot(oldBooksId));
    expect(restoredBooks.parentId, isNull);
    expect(restoredFiction.parentId, restoredBooks.id);
    expect(restoredSciFi.parentId, restoredFiction.id);
    expect(restoredRoots.map((c) => c.name).toSet(), {'Keeper', 'Books'});
    expect(
      keeper.id,
      restoredRoots.firstWhere((category) => category.name == 'Keeper').id,
    );
  });
}
