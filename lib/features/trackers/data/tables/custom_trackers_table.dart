import 'package:drift/drift.dart';

/// One user-created tracker instance.
///
/// [templateType] drives the UI and logging logic:
///   'daily_checklist' — a fixed set of items checked once per day
///                       (prayers, medications, study chapters, water glasses)
///   'session_log'     — free-form rows with named fields per session
///                       (gym: exercise + sets + reps + weight)
class CustomTrackers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// User-facing name, e.g. "Morning Routine" or "Gym Workouts".
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Optional longer description shown on the detail screen.
  TextColumn get description => text().nullable()();

  /// Drives the UI: 'daily_checklist' | 'session_log'
  TextColumn get templateType => text()();

  /// Emoji or short string used as the tracker icon, e.g. '🏋️'.
  TextColumn get icon => text()();

  /// [Color.value] integer — the tracker's accent colour.
  IntColumn get colorValue => integer()();

  DateTimeColumn get createdAt => dateTime()();
}
