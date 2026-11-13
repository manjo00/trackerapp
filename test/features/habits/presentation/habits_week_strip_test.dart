import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habits_week_strip.dart';

import 'habit_widget_helpers.dart';

/// The week strip on the Habits screen picks the day the list shows: today
/// or a past day of this week or last week (‹ shows last week).
void main() {
  final FakeHabitActions fake = FakeHabitActions();
  const String today = '2026-11-04'; // a Wednesday; weeks start on Sunday

  test('today and the past days of this week and last week can be picked', () {
    bool sunday(String d) =>
        isPickableDay(d, today: today, weekStartsSunday: true);
    expect(sunday('2026-11-04'), isTrue); // today
    expect(sunday('2026-11-03'), isTrue); // yesterday
    expect(sunday('2026-11-01'), isTrue); // this week's Sunday
    expect(sunday('2026-10-25'), isTrue); // last week's Sunday
    expect(sunday('2026-10-24'), isFalse); // the week before
    expect(sunday('2026-11-05'), isFalse); // tomorrow
    // With Monday weeks, last week starts on Monday 26 October.
    expect(isPickableDay('2026-10-26', today: today, weekStartsSunday: false),
        isTrue);
    expect(isPickableDay('2026-10-25', today: today, weekStartsSunday: false),
        isFalse);
  });

  Widget strip({
    String? selected,
    int weekOffset = 0,
    List<String>? picks,
    List<int>? weeks,
  }) =>
      habitTestApp(
          HabitsWeekStrip(
            views: [testView()],
            today: today,
            shifts: const {},
            weekStartsSunday: true,
            selected: selected,
            weekOffset: weekOffset,
            onPick: picks?.add,
            onWeek: weeks?.add,
          ),
          fake);

  testWidgets('tapping a past day picks it; a later day does nothing',
      (WidgetTester tester) async {
    final List<String> picks = [];
    await tester.pumpWidget(strip(picks: picks, weeks: []));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('4'));
    expect(picks, ['2026-11-03', '2026-11-04']);
  });

  testWidgets('the arrows page between this week and last week',
      (WidgetTester tester) async {
    final List<String> picks = [];
    final List<int> weeks = [];
    await tester.pumpWidget(strip(picks: picks, weeks: weeks));
    await tester.tap(find.byTooltip('Last week'));
    expect(weeks, [-1]);

    await tester.pumpWidget(strip(weekOffset: -1, picks: picks, weeks: weeks));
    for (int d = 25; d <= 31; d++) {
      expect(find.text('$d'), findsOneWidget);
    }
    await tester.tap(find.text('31'));
    expect(picks, ['2026-10-31']);
    await tester.tap(find.byTooltip('This week'));
    expect(weeks, [-1, 0]);
  });

  testWidgets('a picked day is marked selected for screen readers',
      (WidgetTester tester) async {
    await tester.pumpWidget(strip(selected: '2026-11-03', picks: [], weeks: []));
    expect(
        tester.getSemantics(find.bySemanticsLabel('Tuesday 3 November')),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true));
    expect(
        tester.getSemantics(find.bySemanticsLabel('Today, Wednesday 4 November')),
        isSemantics(isSelected: false, isButton: true));
  });
}
