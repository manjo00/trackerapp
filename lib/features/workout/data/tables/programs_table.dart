import 'package:drift/drift.dart';

/// A training program, e.g. "My PPL Split" or "Upper/Lower".
///
/// Only one program should have [isActive] = true at a time.
/// The split type controls how sessions are scheduled:
///   'rotating' — sessions are cycled in order (Day 1, Day 2, Day 3, …)
///   'weekly'   — sessions are pinned to specific days of the week
class Programs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// User-facing name, e.g. "My PPL Split".
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Optional description or notes about the program.
  TextColumn get description => text().nullable()();

  /// Whether this is the currently active program.
  /// Only one row should have this set to true at a time.
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(false))();

  /// 'rotating' | 'weekly'
  TextColumn get splitType =>
      text().withDefault(const Constant('rotating'))();

  /// A reusable template the user saved from one of their own programs (v22).
  /// Templates never appear in the program list and are never active — they
  /// live in the "My templates" shelf and are copied into a real program on
  /// use. Mirrors `notes.isTemplate`.
  BoolColumn get isTemplate =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
}
