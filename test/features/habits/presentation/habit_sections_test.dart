import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/models/habit_day_view.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habit_sections.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habits_week_strip.dart';
import 'package:life_tracker/features/shifts/data/models/work_shift_model.dart';

import 'habit_widget_helpers.dart';

void main() {
  final FakeHabitActions fake = FakeHabitActions();

  Widget sections(List<HabitDayView> views) =>
      habitTestApp(HabitSections(views: views), fake);

  testWidgets('empty sections are hidden', (WidgetTester tester) async {
    await tester.pumpWidget(sections([
      testView(id: 1, name: 'Stretch', section: HabitSection.wake),
      testView(id: 2, name: 'Read', section: HabitSection.sleep),
    ]));
    // Shown in capitals, as on the looks page; read out as "Wake-up".
    expect(find.text('WAKE-UP'), findsOneWidget);
    expect(find.text('BEFORE SLEEP'), findsOneWidget);
    expect(find.text('ANY TIME'), findsNothing);
    expect(find.text('DAYTIME'), findsNothing);
  });

  testWidgets('kept habits fold under Done today after the pause',
      (WidgetTester tester) async {
    await tester.pumpWidget(sections([testView(id: 1, name: 'Stretch')]));
    await tester.pumpWidget(
        sections([testView(id: 1, name: 'Stretch', today: DayState.kept)]));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stretch'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Stretch'), findsNothing);
    expect(find.text('Done today · 1'), findsOneWidget);
    await tester.tap(find.text('Done today · 1'));
    await tester.pump();
    expect(find.text('Stretch'), findsOneWidget);
  });

  testWidgets('a habit not due today sits under Not due today with its reason',
      (WidgetTester tester) async {
    await tester.pumpWidget(sections([
      testView(
          id: 1,
          name: 'Walk',
          schedule: HabitSchedule.weekdays,
          today: DayState.notDue),
      testView(
          id: 2,
          name: 'Gym',
          schedule: HabitSchedule.perWeek,
          perWeek: 2,
          today: DayState.notDue),
    ]));
    expect(find.text('Walk'), findsNothing);
    await tester.tap(find.text('Not due today · 2'));
    await tester.pump();
    expect(find.textContaining('Not today', findRichText: true), findsOneWidget);
    expect(find.textContaining('Done for the week', findRichText: true),
        findsOneWidget);
  });

  testWidgets('no text is struck through', (WidgetTester tester) async {
    await tester.pumpWidget(sections([
      testView(id: 1, name: 'Stretch', today: DayState.kept),
      testView(id: 2, name: 'Read'),
    ]));
    await tester.tap(find.text('Done today · 1'));
    await tester.pump();
    for (final RichText text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((InlineSpan span) {
        expect(span.style?.decoration, isNot(TextDecoration.lineThrough));
        return true;
      });
      expect(text.text.style?.decoration, isNot(TextDecoration.lineThrough));
    }
  });

  testWidgets('the week strip shows 7 days, today marked, a sun on a day shift',
      (WidgetTester tester) async {
    await tester.pumpWidget(habitTestApp(
        HabitsWeekStrip(
          views: [testView()],
          today: '2026-11-04',
          weekStartsSunday: true,
          shifts: const {
            '2026-11-02': WorkShiftModel(
                id: 1,
                date: '2026-11-02',
                type: ShiftType.day,
                startTime: '07:00',
                endTime: '19:00'),
          },
        ),
        fake));
    for (int d = 1; d <= 7; d++) {
      expect(find.text('$d'), findsOneWidget);
    }
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Today')), findsOneWidget);
  });

  // ── A past day picked in the week strip (Tue 3 Nov; today Wed 4 Nov) ──

  HabitDayView tue(HabitDayView v) =>
      v.onDay('2026-11-03', today: '2026-11-04', weekStartsSunday: true);

  testWidgets('a picked day lists what is left and folds what was done or '
      'not due', (WidgetTester tester) async {
    await tester.pumpWidget(habitTestApp(
        HabitSections(dayLabel: 'Tue', views: [
          tue(testView(id: 1, name: 'Read')), // missed
          tue(testView(
              id: 2,
              name: 'Gym',
              schedule: HabitSchedule.perWeek,
              perWeek: 3)), // no tick yet that week: still open
          tue(testView(
              id: 3,
              name: 'Stretch',
              entries: const {'2026-11-03': HabitEntry(1)})), // kept
          tue(testView(
              id: 4,
              name: 'Walk',
              schedule: HabitSchedule.weekdays,
              weekdayMask: 1)), // Mondays only
        ]),
        fake));
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Stretch'), findsNothing);
    expect(find.text('Done on Tue · 1'), findsOneWidget);
    expect(find.text('Walk'), findsNothing);
    await tester.tap(find.text('Not due on Tue · 1'));
    await tester.pump();
    expect(find.textContaining('Not that day', findRichText: true),
        findsOneWidget);
  });

  testWidgets('a picked day with nothing due says so',
      (WidgetTester tester) async {
    // Tue 29 Sep, before the habit began (1 Oct).
    await tester.pumpWidget(habitTestApp(
        HabitSections(dayLabel: 'Tue', views: [
          testView().onDay('2026-09-29',
              today: '2026-11-04', weekStartsSunday: true),
        ]),
        fake));
    expect(find.text('Nothing was due on Tue'), findsOneWidget);
    expect(find.text('Read 20 min'), findsNothing);
  });
}
