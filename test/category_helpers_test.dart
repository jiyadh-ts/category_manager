import 'package:category_manager/features/categories/domain/category_helpers.dart';
import 'package:category_manager/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Category category({
    required int id,
    required String name,
    int? parentId,
  }) {
    return Category(
      id: id,
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
    ];

    test('rejects the same name under the same parent', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
        name: 'fiction',
        parentId: 1,
      );

      expect(isDuplicate, isTrue);
    });

    test('allows the same name under a different parent', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
        name: 'Fiction',
        parentId: null,
      );

      expect(isDuplicate, isFalse);
    });

    test('ignores the category being edited', () {
      final isDuplicate = hasDuplicateSibling(
        flatList: flatList,
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
  });
}
