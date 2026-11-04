import 'entities/category.dart';

String normalizeCategoryName(String name) {
  return name.trim().toLowerCase();
}

/// Turns a flat adjacency list (`parentId`) into a nested tree.
/// Groups siblings by parent first, then attaches children starting at roots (`null`).
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
  required int userId,
  required String name,
  required int? parentId,
  int? excludeId,
}) {
  final normalizedName = normalizeCategoryName(name);

  for (final category in flatList) {
    if (excludeId != null && category.id == excludeId) {
      continue;
    }
    if (category.userId != userId) {
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

/// Rejects self-parent and moving a node under one of its own descendants
/// (that would create a cycle in the hierarchy).
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

/// Children-first, then [id]. Safe delete order under SQLite foreign keys.
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

/// DFS list of matching category nodes.
/// Empty [query] returns every node; otherwise name contains the query.
List<Category> collectMatchingCategories(
  List<Category> tree,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final matches = <Category>[];

  void walk(List<Category> nodes) {
    for (final category in nodes) {
      final nameMatches = normalizedQuery.isEmpty ||
          category.name.toLowerCase().contains(normalizedQuery);
      if (nameMatches) {
        matches.add(category.copyWith(children: const []));
      }
      walk(category.children);
    }
  }

  walk(tree);
  return matches;
}

/// Takes the first [count] siblings for load-more paging.
List<Category> takeFirstCategories(List<Category> items, int count) {
  if (count <= 0) {
    return const [];
  }
  if (count >= items.length) {
    return items;
  }
  return items.take(count).toList();
}

/// Search page: keep each match plus its ancestors so a deep hit stays
/// reachable in the UI without loading unrelated siblings.
List<Category> buildTreeFromMatches(
  List<Category> flatList,
  List<Category> matchesOnPage,
) {
  if (matchesOnPage.isEmpty) {
    return const [];
  }

  final byId = <int, Category>{};
  for (final category in flatList) {
    byId[category.id] = category;
  }

  final selectedIds = <int>{};
  for (final match in matchesOnPage) {
    // Walk parentId toward the root and mark every ancestor.
    Category? current = byId[match.id] ?? match;
    while (current != null) {
      selectedIds.add(current.id);
      final parentId = current.parentId;
      if (parentId == null) {
        break;
      }
      current = byId[parentId];
    }
  }

  final subset = flatList
      .where((category) => selectedIds.contains(category.id))
      .map((category) => category.copyWith(children: const []))
      .toList();

  return buildCategoryTree(subset);
}
