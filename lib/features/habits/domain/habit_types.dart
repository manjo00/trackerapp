/// The small value types the habit rules work with. Pure Dart: no Flutter,
/// no database. Each enum knows the string it is stored as (`db`).
library;

/// A tick (done or not) or a count with a daily goal (8 glasses).
enum HabitKind {
  tick('tick'),
  count('count');

  const HabitKind(this.db);
  final String db;

  static HabitKind fromDb(String? s) =>
      values.firstWhere((v) => v.db == s, orElse: () => tick);
}

/// When a habit is due.
enum HabitSchedule {
  daily('daily'),
  weekdays('weekdays'),
  perWeek('per_week'),
  shifts('shifts');

  const HabitSchedule(this.db);
  final String db;

  static HabitSchedule fromDb(String? s) =>
      values.firstWhere((v) => v.db == s, orElse: () => daily);
}

/// The part of the day a habit is listed under on the Habits screen.
enum HabitSection {
  wake('wake'),
  any('any'),
  day('day'),
  sleep('sleep');

  const HabitSection(this.db);
  final String db;

  static HabitSection fromDb(String? s) =>
      values.firstWhere((v) => v.db == s, orElse: () => any);
}

/// What a saved day is: done (ticked or counted), or a planned break.
enum EntryStatus {
  done('done'),
  rest('rest'),
  sick('sick');

  const EntryStatus(this.db);
  final String db;

  static EntryStatus fromDb(String? s) =>
      values.firstWhere((v) => v.db == s, orElse: () => done);
}

/// One saved day of one habit: an amount (1 for a tick) and a status.
class HabitEntry {
  const HabitEntry(this.value, [this.status = EntryStatus.done]);

  final int value;
  final EntryStatus status;

  @override
  bool operator ==(Object other) =>
      other is HabitEntry && other.value == value && other.status == status;

  @override
  int get hashCode => Object.hash(value, status);
}

/// An "Away" range: both ends are habit days ('yyyy-MM-dd'), both included.
class PauseRange {
  const PauseRange(this.start, this.end);

  final String start;
  final String end;

  bool contains(String day) =>
      day.compareTo(start) >= 0 && day.compareTo(end) <= 0;
}

/// One habit's saved days (by habit day) and the Away ranges.
class HabitHistory {
  const HabitHistory({required this.entries, this.pauses = const []});

  final Map<String, HabitEntry> entries;
  final List<PauseRange> pauses;
}

/// Every habit's saved days from one query, plus the Away ranges they share.
class HabitHistories {
  const HabitHistories({required this.entriesByHabit, required this.pauses});

  final Map<int, Map<String, HabitEntry>> entriesByHabit;
  final List<PauseRange> pauses;

  /// The history of [habitId]; empty (but with the pauses) when it has none.
  HabitHistory of(int habitId) => HabitHistory(
      entries: entriesByHabit[habitId] ?? const {}, pauses: pauses);
}
