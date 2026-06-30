import 'package:drift/drift.dart';

/// A weekly training target for one muscle group (Push, Pull, Legs, …).
///
/// The scoreboard compares these targets against what you actually logged this
/// week (computed from [WorkoutSets] joined to the exercise library's muscle
/// tags). [frequency] is the ideal sessions/week; [setsPerSession] the ideal
/// sets each time. On a short week the app lowers the effective frequency to fit
/// your free days and adds [compensationStep] sets per dropped session.
class MuscleTargets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable key for the group: 'push' | 'pull' | 'legs' | 'forearms' | 'core'.
  TextColumn get groupKey => text().withLength(min: 1, max: 30)();

  /// Ideal sessions per week that should train this group.
  IntColumn get frequency => integer().withDefault(const Constant(2))();

  /// Ideal working sets for this group in a single session.
  IntColumn get setsPerSession => integer().withDefault(const Constant(3))();

  /// Extra sets/session added for each session the week is short by
  /// (partial volume compensation on tight weeks).
  IntColumn get compensationStep => integer().withDefault(const Constant(1))();

  /// Display order on the scoreboard / editor.
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
