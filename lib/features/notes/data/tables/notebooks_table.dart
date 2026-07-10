import 'package:drift/drift.dart';

/// A user-created folder of notes (e.g. "Rounds", "Cardiology", "Medications").
///
/// Mirrors the Lists conventions: an emoji [icon], a [colorValue] chip, and a
/// nullable [archivedAt] (NULL = active) so Phase 2 can wire it into the
/// Archived screen without another migration.
class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF8AB4F8))();
  TextColumn get icon => text().withDefault(const Constant('📓'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  /// When set, the notebook is archived — hidden from active views but
  /// recoverable. NULL = active.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
