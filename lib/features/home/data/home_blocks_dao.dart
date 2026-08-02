import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'home_block_type.dart';
import 'tables/home_blocks_table.dart';

part 'home_blocks_dao.g.dart';

/// Queries for the Home dashboard's block rows (v21).
///
/// Constructed directly (`HomeBlocksDao(db)`) like NotesDao/ListsDao — not in
/// the generated `daos:` list.
@DriftAccessor(tables: [HomeBlocks])
class HomeBlocksDao extends DatabaseAccessor<AppDatabase>
    with _$HomeBlocksDaoMixin {
  HomeBlocksDao(super.db);

  /// All blocks in dashboard order.
  Stream<List<HomeBlock>> watchBlocks() => (select(homeBlocks)
        ..orderBy([
          (b) => OrderingTerm.asc(b.orderIndex),
          (b) => OrderingTerm.asc(b.id),
        ]))
      .watch();

  Future<List<HomeBlock>> getBlocks() => (select(homeBlocks)
        ..orderBy([
          (b) => OrderingTerm.asc(b.orderIndex),
          (b) => OrderingTerm.asc(b.id),
        ]))
      .get();

  /// One-time hand-off from the legacy prefs layout: if the table is empty,
  /// insert [legacy] in order. Safe to call on every launch (no-op after the
  /// first); runs in a transaction so two racing callers can't double-seed.
  Future<void> ensureSeeded(List<HomeBlockType> legacy) =>
      transaction(() async {
        final List<HomeBlock> existing = await select(homeBlocks).get();
        if (existing.isNotEmpty) return;
        for (int i = 0; i < legacy.length; i++) {
          await into(homeBlocks).insert(HomeBlocksCompanion.insert(
            type: legacy[i].name,
            orderIndex: Value(i),
          ));
        }
      });

  /// Appends a block at the end of the dashboard. Returns its id.
  Future<int> addBlock(HomeBlockType type, {String? configJson}) =>
      transaction(() async {
        final max = homeBlocks.orderIndex.max();
        final row =
            await (selectOnly(homeBlocks)..addColumns([max])).getSingle();
        final int next = (row.read(max) ?? -1) + 1;
        return into(homeBlocks).insert(HomeBlocksCompanion.insert(
          type: type.name,
          orderIndex: Value(next),
          configJson: Value(configJson),
        ));
      });

  Future<void> deleteBlock(int id) =>
      (delete(homeBlocks)..where((b) => b.id.equals(id))).go();

  /// Rewrites dashboard order: [orderedIds] top-to-bottom become 0,1,2,…
  Future<void> reorderBlocks(List<int> orderedIds) => transaction(() async {
        for (int i = 0; i < orderedIds.length; i++) {
          await (update(homeBlocks)..where((b) => b.id.equals(orderedIds[i])))
              .write(HomeBlocksCompanion(orderIndex: Value(i)));
        }
      });

  /// Replaces a block's per-type settings (e.g. point a pinned-note block at a
  /// different note).
  Future<void> updateConfig(int id, String? configJson) =>
      (update(homeBlocks)..where((b) => b.id.equals(id)))
          .write(HomeBlocksCompanion(configJson: Value(configJson)));
}
