class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.parentId,
    required this.createdAt,
    this.childCount = 0,
    this.path,
    this.children = const [],
  });

  final int id;
  final int userId;
  final String name;
  final int? parentId;
  final DateTime createdAt;

  /// Total direct children in the database (not just the loaded page).
  final int childCount;

  /// Breadcrumb path when returned from search (e.g. `A > B > C`).
  final String? path;

  final List<Category> children;

  Category copyWith({
    int? id,
    int? userId,
    String? name,
    int? parentId,
    DateTime? createdAt,
    int? childCount,
    String? path,
    bool clearPath = false,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      childCount: childCount ?? this.childCount,
      path: clearPath ? null : path ?? this.path,
      children: children ?? this.children,
    );
  }
}

class CategoryStats {
  const CategoryStats({
    required this.total,
    required this.roots,
  });

  final int total;
  final int roots;

  int get nested => total > roots ? total - roots : 0;
}

class CategorySearchPage {
  const CategorySearchPage({
    required this.tree,
    required this.totalMatches,
  });

  final List<Category> tree;
  final int totalMatches;
}
