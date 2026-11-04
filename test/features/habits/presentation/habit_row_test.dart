import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habit_row.dart';

import 'habit_widget_helpers.dart';

void main() {
  testWidgets('a tick row shows the cue, the streak and the spares',
      (WidgetTester tester) async {
    await tester.pumpWidget(habitTestApp(
        HabitRow(
            view: testView(
                cue: 'After dinner',
                sparesPerWeek: 1,
                streak: 6,
                sparesLeft: 1)),
        FakeHabitActions()));
    expect(find.text('Read 20 min'), findsOneWidget);
    expect(
        find.textContaining('After dinner', findRichText: true), findsOneWidget);
    expect(find.textContaining('6 days', findRichText: true), findsOneWidget);
    expect(find.textContaining('1 spare left', findRichText: true),
        findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
  });

  testWidgets('the round button ticks the habit', (WidgetTester tester) async {
    final FakeHabitActions fake = FakeHabitActions();
    await tester.pumpWidget(habitTestApp(HabitRow(view: testView()), fake));
    await tester.tap(find.bySemanticsLabel('Tick Read 20 min'));
    expect(fake.calls, ['tick 1']);
  });

  testWidgets('a count row shows 5 of 8 glasses and a + that adds the step',
      (WidgetTester tester) async {
    final FakeHabitActions fake = FakeHabitActions();
    await tester.pumpWidget(habitTestApp(
        HabitRow(
            view: testView(
                name: 'Water',
                kind: HabitKind.count,
                goal: 8,
                unit: 'glasses',
                today: DayState.partial,
                value: 5)),
        fake));
    expect(find.textContaining('5 of 8 glasses', findRichText: true),
        findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(fake.calls, ['add 1 1']);
  });

  testWidgets('a few times a week shows the week count',
      (WidgetTester tester) async {
    await tester.pumpWidget(habitTestApp(
        HabitRow(
            view: testView(
                name: 'Gym',
                schedule: HabitSchedule.perWeek,
                perWeek: 2,
                weekCount: 1)),
        FakeHabitActions()));
    expect(find.textContaining('1 of 2 this week', findRichText: true),
        findsOneWidget);
  });
}
