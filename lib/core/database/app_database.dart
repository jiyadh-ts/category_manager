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

  Future<List<CategoryModel>> getRootCategories({
    required int userId,
    required int limit,
    int offset = 0,
  }) {
    return _getSiblings(
      userId: userId,
      parentId: null,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<CategoryModel>> getChildCategories({
    required int userId,
    required int parentId,
    required int limit,
    int offset = 0,
  }) {
    return _getSiblings(
      userId: userId,
      parentId: parentId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<CategoryModel>> _getSiblings({
    required int userId,
    required int? parentId,
    required int limit,
    required int offset,
  }) async {
    final query = select(categoryEntries)
      ..where((row) {
        final userMatch = row.userId.equals(userId);
        final parentMatch = parentId == null
            ? row.parentId.isNull()
            : row.parentId.equals(parentId);
        return userMatch & parentMatch;
      })
      ..orderBy([(row) => OrderingTerm.asc(row.id)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return Future.wait(rows.map(_mapRowWithChildCount));
  }

  Future<int> countAll(int userId) async {
    final countExp = categoryEntries.id.count();
    final query = selectOnly(categoryEntries)
      ..addColumns([countExp])
      ..where(categoryEntries.userId.equals(userId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> countRoots(int userId) async {
    final countExp = categoryEntries.id.count();
    final query = selectOnly(categoryEntries)
      ..addColumns([countExp])
      ..where(
        categoryEntries.userId.equals(userId) &
            categoryEntries.parentId.isNull(),
      );
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> countChildren(int userId, int parentId) async {
    final countExp = categoryEntries.id.count();
    final query = selectOnly(categoryEntries)
      ..addColumns([countExp])
      ..where(
        categoryEntries.userId.equals(userId) &
            categoryEntries.parentId.equals(parentId),
      );
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<List<CategoryModel>> searchCategories({
    required int userId,
    required String query,
    required int limit,
    int offset = 0,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final pattern = '%$normalized%';
    final selectQuery = select(categoryEntries)
      ..where(
        (row) =>
            row.userId.equals(userId) & row.name.lower().like(pattern),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.id)])
      ..limit(limit, offset: offset);

    final rows = await selectQuery.get();
    return Future.wait(rows.map(_mapRowWithChildCount));
  }

  Future<int> countSearchMatches({
    required int userId,
    required String query,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 0;
    }

    final pattern = '%$normalized%';
    final countExp = categoryEntries.id.count();
    final selectQuery = selectOnly(categoryEntries)
      ..addColumns([countExp])
      ..where(
        categoryEntries.userId.equals(userId) &
            categoryEntries.name.lower().like(pattern),
      );
    final row = await selectQuery.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<CategoryModel?> getCategoryById(int userId, int id) async {
    final query = select(categoryEntries)
      ..where((row) => row.userId.equals(userId) & row.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapRowWithChildCount(row);
  }

  /// Root → … → self (inclusive).
  Future<List<CategoryModel>> getAncestorChain(int userId, int id) async {
    final chain = <CategoryModel>[];
    var currentId = id;

    while (true) {
      final current = await getCategoryById(userId, currentId);
      if (current == null) {
        break;
      }
      chain.insert(0, current);
      final parentId = current.parentId;
      if (parentId == null) {
        break;
      }
      currentId = parentId;
    }

    return chain;
  }

  /// Parent-before-child snapshot of [rootId] and descendants (for undo).
  Future<List<CategoryModel>> getSubtreeFlat(int userId, int rootId) async {
    final root = await getCategoryById(userId, rootId);
    if (root == null) {
      return const [];
    }

    final result = <CategoryModel>[root];
    final queue = <int>[rootId];

    while (queue.isNotEmpty) {
      final parentId = queue.removeAt(0);
      final childrenQuery = select(categoryEntries)
        ..where(
          (row) =>
              row.userId.equals(userId) & row.parentId.equals(parentId),
        )
        ..orderBy([(row) => OrderingTerm.asc(row.id)]);
      final children = await childrenQuery.get();
      for (final child in children) {
        final model = await _mapRowWithChildCount(child);
        result.add(model);
        queue.add(child.id);
      }
    }

    return result;
  }

  Future<bool> hasSiblingWithName({
    required int userId,
    required String name,
    required int? parentId,
    int? excludeId,
  }) async {
    final normalized = name.trim().toLowerCase();
    final query = select(categoryEntries)
      ..where((row) {
        final userMatch = row.userId.equals(userId);
        final parentMatch = parentId == null
            ? row.parentId.isNull()
            : row.parentId.equals(parentId);
        final nameMatch = row.name.lower().equals(normalized);
        var predicate = userMatch & parentMatch & nameMatch;
        if (excludeId != null) {
          predicate = predicate & row.id.equals(excludeId).not();
        }
        return predicate;
      })
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row != null;
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

  /// Inserts [snapshot] in order, remapping old ids to new auto-increment ids.
  /// Returns oldId -> newId.
  Future<Map<int, int>> restoreCategories({
    required int userId,
    required List<CategoryModel> snapshot,
  }) async {
    final idMap = <int, int>{};
    if (snapshot.isEmpty) {
      return idMap;
    }

    await transaction(() async {
      for (final category in snapshot) {
        // Remap parents inside the snapshot; keep external parents as-is.
        final remappedParent = category.parentId == null
            ? null
            : (idMap.containsKey(category.parentId)
                ? idMap[category.parentId]
                : category.parentId);
        final newId = await into(categoryEntries).insert(
          CategoryEntriesCompanion.insert(
            userId: userId,
            name: category.name,
            parentId: Value(remappedParent),
            createdAt: category.createdAt,
          ),
        );
        idMap[category.id] = newId;
      }
    });

    return idMap;
  }

  Future<CategoryModel> _mapRowWithChildCount(CategoryEntry row) async {
    final childCount = await countChildren(row.userId, row.id);
    return CategoryModel(
      id: row.id,
      userId: row.userId,
      name: row.name,
      parentId: row.parentId,
      createdAt: row.createdAt,
      childCount: childCount,
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
