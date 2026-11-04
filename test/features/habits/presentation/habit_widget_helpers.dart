import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_stats.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/models/habit_day_view.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';

/// Records what the habit widgets asked for, instead of touching a database.
class FakeHabitActions implements HabitActions {
  final List<String> calls = [];

  @override
  Future<void> tick(int habitId) async => calls.add('tick $habitId');

  @override
  Future<void> addAmount(int habitId, int amount) async =>
      calls.add('add $habitId $amount');

  @override
  Future<bool> setAmount(int habitId, String day, String typed) async {
    calls.add('set $habitId $day $typed');
    return true;
  }

  /// Every habit the editor saved, as it was saved.
  final List<HabitModel> saved = [];

  @override
  Future<int> save(HabitModel habit) async {
    calls.add('save ${habit.name}');
    saved.add(habit);
    return habit.id == 0 ? 99 : habit.id;
  }
}

/// A day view with the numbers a test wants, without running the rules.
HabitDayView testView({
  int id = 1,
  String name = 'Read 20 min',
  HabitKind kind = HabitKind.tick,
  int goal = 1,
  String? unit,
  HabitSchedule schedule = HabitSchedule.daily,
  int? perWeek,
  int sparesPerWeek = 0,
  HabitSection section = HabitSection.any,
  String? cue,
  DayState today = DayState.pending,
  int value = 0,
  int streak = 0,
  int weekCount = 0,
  int sparesLeft = 0,
}) =>
    HabitDayView(
      habit: HabitModel(
        id: id,
        name: name,
        createdAt: DateTime(2026, 10, 1, 10),
        kind: kind,
        goal: goal,
        unit: unit,
        schedule: schedule,
        perWeek: perWeek,
        sparesPerWeek: sparesPerWeek,
        section: section,
        cue: cue,
      ),
      history: const HabitHistory(entries: {}),
      summary: HabitSummary(
        today: today,
        todayValue: value,
        streak: streak,
        streakUnit: schedule == HabitSchedule.perWeek
            ? StreakUnit.weeks
            : StreakUnit.days,
        strengthPercent: 50,
        weekCount: weekCount,
        sparesLeft: sparesLeft,
      ),
    );

/// [child] in a scrolling page, with [fake] standing in for the actions.
Widget habitTestApp(Widget child, FakeHabitActions fake) => ProviderScope(
      overrides: [
        habitActionsProvider.overrideWithValue(fake),
        habitTodayProvider.overrideWith(FixedToday.new),
      ],
      child: MaterialApp(
        home: Scaffold(body: ListView(children: [child])),
      ),
    );

/// "Today" pinned to Wednesday 4 November 2026.
class FixedToday extends HabitToday {
  @override
  String build() => '2026-11-04';
}
