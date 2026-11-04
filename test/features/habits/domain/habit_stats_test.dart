import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/habit_day.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_stats.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';

import 'habit_test_helpers.dart';

int streakOf(HabitModel h, HabitHistory hist, {String today = kToday}) =>
    currentStreak(h, hist, today: today, weekStartsSunday: true);

int strengthOf(HabitModel h, HabitHistory hist, {String today = kToday}) =>
    strengthPercent(h, hist, today: today, weekStartsSunday: true);

void main() {
  group('streak', () {
    final HabitModel daily = testHabit();

    test('today not ticked yet never breaks the streak', () {
      final Map<String, int> week = ticksFrom('2026-10-28', '2026-11-03');
      expect(streakOf(daily, testHistory(week)), 7);
      expect(streakOf(daily, testHistory({...week, kToday: 1})), 8);
    });

    test('a spare day covers one miss a week', () {
      final HabitModel spare = testHabit(sparesPerWeek: 1);
      final HabitHistory hist = testHistory(
          ticksFrom('2026-10-25', '2026-11-03', except: {'2026-10-28'}));
      expect(streakOf(spare, hist), 9);
      expect(
          sparesLeft(spare, hist, today: kToday, weekStartsSunday: true), 1);
    });

    test('without a spare left the streak stops', () {
      final HabitModel spare = testHabit(sparesPerWeek: 1);
      final HabitHistory hist = testHistory(ticksFrom('2026-10-25', '2026-11-03',
          except: {'2026-10-27', '2026-10-29'}));
      expect(streakOf(spare, hist), 6);
    });

    test('rest days and pauses are skipped', () {
      final HabitHistory hist = testHistory(
        ticksFrom('2026-10-28', '2026-11-03',
            except: {'2026-10-30', '2026-10-31', '2026-11-01'}),
        breaks: {'2026-10-30': EntryStatus.rest},
        pauses: const [PauseRange('2026-10-31', '2026-11-01')],
      );
      expect(streakOf(daily, hist), 4);
    });

    test('a few times a week counts weeks', () {
      final HabitModel twice =
          testHabit(schedule: HabitSchedule.perWeek, perWeek: 2);
      final Map<String, int> ticks = {
        '2026-10-18': 1, '2026-10-19': 1, // reached
        '2026-10-25': 1, '2026-10-26': 1, // reached
        '2026-11-01': 1, // this week, 1 of 2 so far
      };
      expect(streakOf(twice, testHistory(ticks)), 2);
      expect(streakOf(twice, testHistory({...ticks, '2026-11-03': 1})), 3);
    });
  });

  group('strength', () {
    test('ten kept days from the first day give 40', () {
      final HabitModel h = testHabit(createdAt: DateTime(2026, 10, 25, 10));
      expect(strengthOf(h, testHistory(ticksFrom('2026-10-25', '2026-11-03'))),
          40);
    });

    test('a miss after twenty kept days gives 61', () {
      final HabitModel h = testHabit(createdAt: DateTime(2026, 10, 14, 10));
      expect(strengthOf(h, testHistory(ticksFrom('2026-10-14', '2026-11-02'))),
          61);
    });

    test('a half count after twenty kept days gives 63', () {
      final HabitModel h = testHabit(
          kind: HabitKind.count,
          goal: 8,
          createdAt: DateTime(2026, 10, 14, 10));
      expect(
          strengthOf(
              h,
              testHistory(
                  {...ticksFrom('2026-10-14', '2026-11-02', value: 8),
                    '2026-11-03': 4})),
          63);
    });

    test('a rest day changes nothing', () {
      final HabitModel h = testHabit(createdAt: DateTime(2026, 10, 24, 10));
      expect(
          strengthOf(
              h,
              testHistory(ticksFrom('2026-10-25', '2026-11-03'),
                  breaks: {'2026-10-24': EntryStatus.rest})),
          40);
    });

    test('a spare-covered miss lowers strength like a miss', () {
      final HabitModel h = testHabit(
          sparesPerWeek: 1, createdAt: DateTime(2026, 10, 14, 10));
      expect(strengthOf(h, testHistory(ticksFrom('2026-10-14', '2026-11-02'))),
          61);
    });
  });

  test('nothing before the first day counts', () {
    // "3 a week", created on Friday 30 October, ticked once on Saturday.
    final HabitModel h = testHabit(
        schedule: HabitSchedule.perWeek,
        perWeek: 3,
        createdAt: DateTime(2026, 10, 30, 10));
    final HabitHistory hist = testHistory({'2026-10-31': 1});
    expect(dayState(h, hist, '2026-10-29', today: kToday, weekStartsSunday: true),
        DayState.beforeStart);
    for (String d = '2026-10-30'; d.compareTo(kToday) <= 0; d = addDays(d, 1)) {
      expect(dayState(h, hist, d, today: kToday, weekStartsSunday: true),
          isNot(DayState.missed),
          reason: d);
    }
    expect(streakOf(h, hist), 0);
    expect(strengthOf(h, hist), 6);
  });

  test('a changed schedule re-scores the past', () {
    // Ticked on Mondays, Wednesdays and Fridays only.
    final HabitHistory hist = testHistory({
      '2026-10-26': 1, '2026-10-28': 1, '2026-10-30': 1, '2026-11-02': 1,
    });
    expect(streakOf(testHabit(), hist), 0);
    expect(
        streakOf(
            testHabit(schedule: HabitSchedule.weekdays, weekdayMask: 21), hist),
        4);
  });

  test('spare days left this week', () {
    final HabitModel h = testHabit(sparesPerWeek: 2);
    final HabitHistory hist = testHistory({'2026-11-01': 1, '2026-11-03': 1});
    expect(sparesLeft(h, hist, today: kToday, weekStartsSunday: true), 1);
    expect(
        sparesLeft(testHabit(schedule: HabitSchedule.perWeek, perWeek: 2), hist,
            today: kToday, weekStartsSunday: true),
        0);
  });

  test('summarize puts the day together', () {
    final HabitSummary s = summarize(
        testHabit(), testHistory(ticksFrom('2026-10-28', '2026-11-03')),
        today: kToday, weekStartsSunday: true);
    expect((s.today, s.streak, s.streakUnit, s.weekCount),
        (DayState.pending, 7, StreakUnit.days, 3));
  });

  group('the gym fixture', () {
    // His weekly workout counts (Sunday weeks from 28 June 2026), placed on
    // made-up days: the repo is public, so his real dates stay out of it.
    const List<int> counts = [
      5, 1, 2, 1, 0, 2, 4, 1, 2, 0, 3, 2, 2, 2, 0, 0, 0, 1, //
    ];
    final HabitModel gym = testHabit(
        schedule: HabitSchedule.perWeek,
        perWeek: 2,
        createdAt: DateTime(2026, 6, 28, 10));
    final Map<String, int> ticks = {'2026-11-01': 1};
    for (int w = 0; w < counts.length; w++) {
      final String sunday = addDays('2026-06-28', 7 * w);
      for (int d = 0; d < counts[w]; d++) {
        ticks[addDays(sunday, d)] = 1;
      }
    }
    final HabitHistory hist = testHistory(ticks);

    test('strength is 45 now and was 76 at the start of October', () {
      expect(strengthOf(gym, hist), 45);
      expect(strengthOf(gym, hist, today: '2026-10-04'), 76);
    });

    test('no streak running, 1 of 2 this week', () {
      expect(streakOf(gym, hist), 0);
      expect(weekCount(gym, hist, today: kToday, weekStartsSunday: true), 1);
    });
  });
}
