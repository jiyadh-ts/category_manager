import 'package:category_manager/features/categories/domain/category_helpers.dart';
import 'package:category_manager/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Category category({
    required int id,
    required String name,
    int userId = 1,
    int? parentId,
  }) {
    return Category(
      id: id,
      userId: userId,
      name: name,
      parentId: parentId,
      createdAt: now,
    );
  }

  group('hasDuplicateSibling', () {
    final flatList = [
      category(id: 1, name: 'Books'),
      category(id: 2, name: 'Fiction', parentId: 1),
      category(id: 3, name: 'Games'),
      category(id: 4, name: 'Fiction', userId: 2, parentId: 1),
    ];

    test('rejects the same name under the same parent for the same user', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
        userId: 1,
        name: 'fiction',
        parentId: 1,
      );

      expect(isDuplicate, isTrue);
    });

    test('allows the same name under a different parent', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
        userId: 1,
        name: 'Fiction',
        parentId: null,
      );

      expect(isDuplicate, isFalse);
    });

    test('allows the same name for a different user', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
        userId: 2,
        name: 'Books',
        parentId: null,
      );

      expect(isDuplicate, isFalse);
    });

    test('ignores the category being edited', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
        userId: 1,
        name: 'Fiction',
        parentId: 1,
        excludeId: 2,
      );

      expect(isDuplicate, isFalse);
    });
  });

  group('buildCategoryTree', () {
    test('builds nested children from a flat list', () {
      final flatList = [
        category(id: 1, name: 'Books'),
        category(id: 2, name: 'Fiction', parentId: 1),
        category(id: 3, name: 'Sci-Fi', parentId: 2),
        category(id: 4, name: 'Games'),
      ];

      final tree = buildCategoryTree(flatList);

      expect(tree.length, 2);
      expect(tree[0].name, 'Books');
      expect(tree[0].children.single.name, 'Fiction');
      expect(tree[0].children.single.children.single.name, 'Sci-Fi');
      expect(tree[1].name, 'Games');
    });
  });

  group('searchCategories', () {
    test('keeps parents when a nested child matches', () {
      final tree = buildCategoryTree([
        category(id: 1, name: 'Books'),
        category(id: 2, name: 'Fiction', parentId: 1),
        category(id: 3, name: 'Sci-Fi', parentId: 2),
        category(id: 4, name: 'Games'),
      ]);

      final results = searchCategories(tree, 'sci');

      expect(results.length, 1);
      expect(results.first.name, 'Books');
      expect(results.first.children.single.name, 'Fiction');
      expect(results.first.children.single.children.single.name, 'Sci-Fi');
    });
  });

  group('isValidParent', () {
    final flatList = [
      category(id: 1, name: 'Books'),
      category(id: 2, name: 'Fiction', parentId: 1),
      category(id: 3, name: 'Sci-Fi', parentId: 2),
      category(id: 4, name: 'Games'),
    ];

    test('rejects setting a category as its own parent', () {
      expect(
        isValidParent(flatList: flatList, categoryId: 1, newParentId: 1),
        isFalse,
      );
    });

    test('rejects a descendant as the parent', () {
      expect(
        isValidParent(flatList: flatList, categoryId: 1, newParentId: 3),
        isFalse,
      );
    });

    test('rejects a parent that does not exist', () {
      expect(
        isValidParent(flatList: flatList, categoryId: 4, newParentId: 99),
        isFalse,
      );
    });

    test('allows a different existing category as parent', () {
      expect(
        isValidParent(flatList: flatList, categoryId: 4, newParentId: 1),
        isTrue,
      );
    });
  });

  group('getCategoryPath', () {
    test('joins ancestor names with >', () {
      final flatList = [
        category(id: 1, name: 'Books'),
        category(id: 2, name: 'Fiction', parentId: 1),
        category(id: 3, name: 'Sci-Fi', parentId: 2),
      ];

      expect(getCategoryPath(flatList, 3), 'Books > Fiction > Sci-Fi');
    });

    test('builds a deep breadcrumb path', () {
      final flatList = [
        category(id: 1, name: 'Electronics'),
        category(id: 2, name: 'Mobiles', parentId: 1),
        category(id: 3, name: 'Android', parentId: 2),
        category(id: 4, name: 'Samsung', parentId: 3),
      ];

      expect(
        getCategoryPath(flatList, 4),
        'Electronics > Mobiles > Android > Samsung',
      );
    });
  });

  group('collectSubtreeForRestore', () {
    test('returns parent-before-child snapshot of the subtree', () {
      final flatList = [
        category(id: 1, name: 'Books'),
        category(id: 2, name: 'Fiction', parentId: 1),
        category(id: 3, name: 'Sci-Fi', parentId: 2),
        category(id: 4, name: 'Games'),
      ];

      final snapshot = collectSubtreeForRestore(flatList, 1);

      expect(snapshot.map((c) => c.id), [1, 2, 3]);
      expect(snapshot.map((c) => c.name), ['Books', 'Fiction', 'Sci-Fi']);
      expect(snapshot.every((c) => c.children.isEmpty), isTrue);
    });
  });

  group('load more helpers', () {
    late List<Category> flatList;
    late List<Category> tree;

    setUp(() {
      flatList = [
        for (var i = 1; i <= 25; i++) category(id: i, name: 'Item $i'),
        category(id: 100, name: 'Books'),
        category(id: 101, name: 'Fiction', parentId: 100),
        category(id: 102, name: 'Samsung', parentId: 101),
      ];
      tree = buildCategoryTree(flatList);
    });

    test('takeFirstCategories returns the first batch of siblings', () {
      final roots = tree.where((c) => c.parentId == null).toList();
      final firstBatch = takeFirstCategories(roots, 10);

      expect(roots.length, greaterThan(10));
      expect(firstBatch.length, 10);
      expect(firstBatch.first.name, 'Item 1');
      expect(firstBatch.last.name, 'Item 10');
    });

    test('takeFirstCategories second batch continues after the first 10', () {
      final matches = collectMatchingCategories(tree, 'Item');
      final secondBatch = matches.skip(10).take(10).toList();

      expect(matches.length, 25);
      expect(secondBatch.first.name, 'Item 11');
      expect(secondBatch.last.name, 'Item 20');
    });

    test('buildTreeFromMatches preserves ancestors for a deep match', () {
      final matches = collectMatchingCategories(tree, 'Samsung');
      final visible = buildTreeFromMatches(
        flatList,
        takeFirstCategories(matches, 10),
      );

      expect(matches.length, 1);
      expect(visible.single.name, 'Books');
      expect(visible.single.children.single.name, 'Fiction');
      expect(visible.single.children.single.children.single.name, 'Samsung');
    });
  });
}
