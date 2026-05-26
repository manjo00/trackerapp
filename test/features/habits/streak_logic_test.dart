import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/data/models/habit_completion_model.dart';
import 'package:life_tracker/features/habits/data/repositories/habits_repository.dart';

// HabitsRepository.calculateStreak is a static method — no database or
// instance needed.  We call it directly, like a plain utility function.

/// Helper — builds a [HabitCompletionModel] for a given date string.
HabitCompletionModel _c(String date) => HabitCompletionModel(
      id: 0,
      habitId: 1,
      date: date,
    );

/// Shorthand to call the static streak function with a string-based today.
int _streak(List<HabitCompletionModel> completions, String todayStr) =>
    HabitsRepository.calculateStreak(completions, DateTime.parse(todayStr));

void main() {
  group('HabitsRepository.calculateStreak', () {
    test('returns 0 for empty completions', () {
      expect(_streak([], '2026-05-26'), 0);
    });

    test('returns 1 when only today is completed', () {
      expect(_streak([_c('2026-05-26')], '2026-05-26'), 1);
    });

    test('returns 2 when today and yesterday are both completed', () {
      expect(
        _streak([_c('2026-05-26'), _c('2026-05-25')], '2026-05-26'),
        2,
      );
    });

    test('returns 1 when today is done but there is a gap yesterday', () {
      // Today ✓  yesterday ✗  day-before ✓  → streak is 1 (gap breaks it)
      expect(
        _streak([_c('2026-05-26'), _c('2026-05-24')], '2026-05-26'),
        1,
      );
    });

    test('returns 0 when today has no completion even if yesterday did', () {
      // A streak must START from today — yesterday alone doesn't count.
      expect(_streak([_c('2026-05-25')], '2026-05-26'), 0);
    });

    test('handles a 7-day unbroken streak correctly', () {
      final List<HabitCompletionModel> week = List.generate(
        7,
        (i) => _c(
          DateTime(2026, 5, 26)
              .subtract(Duration(days: i))
              .toIso8601String()
              .substring(0, 10),
        ),
      );
      expect(_streak(week, '2026-05-26'), 7);
    });
  });
}
