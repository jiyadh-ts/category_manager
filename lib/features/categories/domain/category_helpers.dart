import 'entities/category.dart';

String normalizeCategoryName(String name) {
  return name.trim().toLowerCase();
}

List<Category> buildCategoryTree(List<Category> flatList) {
  final childrenByParentId = <int?, List<Category>>{};

  for (final category in flatList) {
    final siblings = childrenByParentId[category.parentId];
    if (siblings == null) {
      childrenByParentId[category.parentId] = [category];
    } else {
      siblings.add(category);
    }
  }

  List<Category> buildChildren(int? parentId) {
    final children = childrenByParentId[parentId];
    if (children == null) {
      return const [];
    }

    final builtChildren = <Category>[];
    for (final child in children) {
      builtChildren.add(
        child.copyWith(children: buildChildren(child.id)),
      );
    }
    return builtChildren;
  }

  return buildChildren(null);
}

List<Category> searchCategories(List<Category> tree, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return tree;
  }

  final matches = <Category>[];
  for (final category in tree) {
    final matchingChildren = searchCategories(category.children, query);
    final nameMatches = category.name.toLowerCase().contains(normalizedQuery);
    if (nameMatches || matchingChildren.isNotEmpty) {
      matches.add(category.copyWith(children: matchingChildren));
    }
  }
  return matches;
}

String getCategoryPath(List<Category> flatList, int id) {
  final categoriesById = <int, Category>{};
  for (final category in flatList) {
    categoriesById[category.id] = category;
  }

  final names = <String>[];
  Category? current = categoriesById[id];

  while (current != null) {
    names.insert(0, current.name);
    final parentId = current.parentId;
    if (parentId == null) {
      break;
    }
    current = categoriesById[parentId];
  }

  return names.join(' > ');
}

bool hasDuplicateSibling({
  required List<Category> flatList,
  required String name,
  required int? parentId,
  int? excludeId,
}) {
  final normalizedName = normalizeCategoryName(name);

  for (final category in flatList) {
    if (excludeId != null && category.id == excludeId) {
      continue;
    }
    if (category.parentId != parentId) {
      continue;
    }
    if (normalizeCategoryName(category.name) == normalizedName) {
      return true;
    }
  }

  return false;
}

bool isValidParent({
  required List<Category> flatList,
  required int categoryId,
  required int? newParentId,
}) {
  if (newParentId == null) {
    return true;
  }

  if (newParentId == categoryId) {
    return false;
  }

  var parentExists = false;
  for (final category in flatList) {
    if (category.id == newParentId) {
      parentExists = true;
      break;
    }
  }
  if (!parentExists) {
    return false;
  }

  final descendantIds = collectDescendantIds(flatList, categoryId);
  return !descendantIds.contains(newParentId);
}

List<int> collectDescendantIds(List<Category> flatList, int id) {
  final ids = <int>[];
  _collectChildrenFirst(flatList, id, ids);
  ids.add(id);
  return ids;
}

void _collectChildrenFirst(
  List<Category> flatList,
  int parentId,
  List<int> ids,
) {
  for (final category in flatList) {
    if (category.parentId == parentId) {
      _collectChildrenFirst(flatList, category.id, ids);
      ids.add(category.id);
    }
  }
}

int countCategories(List<Category> tree) {
  var total = 0;
  for (final category in tree) {
    total += 1;
    total += countCategories(category.children);
  }
  return total;
}
