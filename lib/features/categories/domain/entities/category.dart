class Category {
  const Category({
    required this.id,
    required this.name,
    required this.parentId,
    required this.createdAt,
    this.children = const [],
  });

  final int id;
  final String name;
  final int? parentId;
  final DateTime createdAt;
  final List<Category> children;

  Category copyWith({
    int? id,
    String? name,
    int? parentId,
    DateTime? createdAt,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }
}
