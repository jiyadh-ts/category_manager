import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/categories/data/models/category_model.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CategoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        if (from < 2) {
          // Pre-multi-user rows have no recoverable owner. Preserve them with
          // user_id = 0 (orphan). The first authenticated user can claim them
          // via claimOrphanCategories — rows are never deleted here.
          await customStatement(
            'ALTER TABLE categories ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
      beforeOpen: (OpeningDetails details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Assigns legacy orphan categories (user_id = 0) to [userId].
  /// Used once after upgrade so existing data is kept and attributed.
  Future<int> claimOrphanCategories(int userId) {
    return (update(categoryEntries)..where((row) => row.userId.equals(0)))
        .write(CategoryEntriesCompanion(userId: Value(userId)));
  }

  Future<List<CategoryModel>> getCategories(int userId) async {
    final query = select(categoryEntries)
      ..where((row) => row.userId.equals(userId));
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  Future<CategoryModel?> getCategoryById(int userId, int id) async {
    final query = select(categoryEntries)
      ..where((row) => row.userId.equals(userId) & row.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapRow(row);
  }

  Future<int> insertCategory({
    required int userId,
    required String name,
    int? parentId,
    required DateTime createdAt,
  }) {
    return into(categoryEntries).insert(
      CategoryEntriesCompanion.insert(
        userId: userId,
        name: name,
        parentId: Value(parentId),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> updateCategory({
    required int userId,
    required int id,
    required String name,
    int? parentId,
  }) async {
    await (update(categoryEntries)
          ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
        .write(
      CategoryEntriesCompanion(
        name: Value(name),
        parentId: Value(parentId),
      ),
    );
  }

  Future<void> deleteCategories(int userId, List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }

    await transaction(() async {
      for (final id in ids) {
        await (delete(categoryEntries)
              ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
            .go();
      }
    });
  }

  CategoryModel _mapRow(CategoryEntry row) {
    return CategoryModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      parentId: row.parentId,
      createdAt: row.createdAt,
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'category_manager',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Using ${result.chosenImplementation} due to unsupported '
              'browser features: ${result.missingFeatures}',
            );
          }
        },
      ),
    );
  }
}
