import 'package:drift/drift.dart';

/// A user-editable rotation/placement (e.g. "ICU1", "ER", "Cardiac").
///
/// A shift on a given day is a rotation + a day/night flag. The day/night part
/// is shown by the tile's sun/moon + cyan/navy visual; this table supplies the
/// short label (and its colour) drawn on the tile.
class ShiftRotations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Short label shown on calendar tiles, e.g. "ICU1", "ER", "Cardiac".
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// Label colour (ARGB int). Defaults to orange; editable per rotation.
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFFFFB347))();

  /// Display order in the picker / editor.
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
