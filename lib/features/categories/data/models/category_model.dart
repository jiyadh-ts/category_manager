import 'package:drift/drift.dart';

class CategoryEntries extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId => integer()();

  TextColumn get name => text()();

  IntColumn get parentId => integer().nullable().references(
        CategoryEntries,
        #id,
      )();

  DateTimeColumn get createdAt => dateTime()();
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.parentId,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String name;
  final int? parentId;
  final DateTime createdAt;
}
