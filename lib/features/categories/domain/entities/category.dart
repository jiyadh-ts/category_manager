class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.parentId,
    required this.createdAt,
    this.children = const [],
  });

  final int id;
  final int userId;
  final String name;
  final int? parentId;
  final DateTime createdAt;
  final List<Category> children;

  Category copyWith({
    int? id,
    int? userId,
    String? name,
    int? parentId,
    DateTime? createdAt,
    List<Category>? children,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }
}
