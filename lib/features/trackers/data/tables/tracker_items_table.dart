import 'package:drift/drift.dart';
import 'custom_trackers_table.dart';

/// One item/field belonging to a tracker.
///
/// For 'daily_checklist': each item is a checkbox row
///   (e.g. "Fajr", "Morning Medication", "Chapter 3").
/// For 'session_log': each item is a column in the logging form
///   (e.g. "Exercise", "Sets", "Reps", "Weight (kg)").
class TrackerItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get trackerId =>
      integer().references(CustomTrackers, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// How this item's value is collected and displayed:
  ///   'checkbox' — boolean (done / not done)
  ///   'number'   — numeric input (sets, reps, weight, count)
  ///   'text'     — free text (exercise name, notes)
  TextColumn get fieldType => text()();

  /// Display order within the tracker — lower = shown first.
  IntColumn get sortOrder => integer()();
}
