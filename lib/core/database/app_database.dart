import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/categories/data/models/category_model.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CategoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        // Schema version 1 has no upgrade steps.
      },
      beforeOpen: (OpeningDetails details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final rows = await select(categoryEntries).get();
    return rows.map(_mapRow).toList();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final query = select(categoryEntries)..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapRow(row);
  }

  Future<int> insertCategory({
    required String name,
    int? parentId,
    required DateTime createdAt,
  }) {
    return into(categoryEntries).insert(
      CategoryEntriesCompanion.insert(
        name: name,
        parentId: Value(parentId),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    int? parentId,
  }) async {
    await (update(categoryEntries)..where((row) => row.id.equals(id))).write(
      CategoryEntriesCompanion(
        name: Value(name),
        parentId: Value(parentId),
      ),
    );
  }

  Future<void> deleteCategories(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }

    await transaction(() async {
      for (final id in ids) {
        await (delete(categoryEntries)..where((row) => row.id.equals(id))).go();
      }
    });
  }

  CategoryModel _mapRow(CategoryEntry row) {
    return CategoryModel(
      id: row.id,
      name: row.name,
      parentId: row.parentId,
      createdAt: row.createdAt,
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'category_manager');
  }
}
