import 'package:drift/drift.dart';

/// One block on the Home dashboard, in [orderIndex] order (v21).
///
/// [type] stores a HomeBlockType name ('urgent', 'pinnedNote', …) — unknown
/// values are skipped at render time so an older build never crashes on a
/// newer layout. [configJson] carries per-block settings as a small JSON
/// object (pinned note: `{"noteId": 5}`); NULL = the block needs none.
///
/// Deliberately **no foreign keys**: a pinned note that gets deleted should
/// render a "choose another note" placeholder, not silently cascade the block
/// off the dashboard.
class HomeBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().withLength(min: 1, max: 32)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get configJson => text().nullable()();
}
