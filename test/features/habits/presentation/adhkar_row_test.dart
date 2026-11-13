import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/adhkar_progress.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/models/habit_day_view.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habit_row.dart';

import 'habit_widget_helpers.dart';

/// Morning du'as, 5 of 21 done today (or [today] as given).
HabitDayView _duaView({DayState today = DayState.partial, int value = 5}) {
  final HabitDayView v = testView(
    name: "Morning du'as",
    kind: HabitKind.count,
    goal: 21,
    unit: "du'as",
    today: today,
    value: value,
    entries: const {'2026-11-03': HabitEntry(4)},
  );
  return HabitDayView(
    habit: v.habit.copyWith(autoSource: AdhkarList.morning.source),
    history: v.history,
    summary: v.summary,
  );
}

/// [row] on a page with the two places a row can open, standing in for the
/// counter and the editor.
Widget _routerApp(Widget row, FakeHabitActions fake) => ProviderScope(
      overrides: [
        habitActionsProvider.overrideWithValue(fake),
        habitTodayProvider.overrideWith(FixedToday.new),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(
              path: '/',
              builder: (_, __) =>
                  Scaffold(body: ListView(children: [row]))),
          GoRoute(
              path: '/habits/adhkar',
              builder: (_, GoRouterState s) =>
                  Text('COUNTER ${(s.extra! as HabitModel).name}')),
          GoRoute(path: '/habits/edit', builder: (_, __) => const Text('EDITOR')),
        ]),
      ),
    );

void main() {
  testWidgets("today, tapping a du'a row opens its counter",
      (WidgetTester tester) async {
    await tester.pumpWidget(
        _routerApp(HabitRow(view: _duaView()), FakeHabitActions()));
    expect(find.textContaining('5 of 21', findRichText: true), findsOneWidget);
    await tester.tap(find.text("Morning du'as"));
    await tester.pumpAndSettle();
    expect(find.text("COUNTER Morning du'as"), findsOneWidget);
  });

  testWidgets("today, the du'a row's button opens the counter, never adds",
      (WidgetTester tester) async {
    final FakeHabitActions fake = FakeHabitActions();
    await tester.pumpWidget(_routerApp(HabitRow(view: _duaView()), fake));
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    await tester.tap(find.byTooltip("Count Morning du'as"));
    await tester.pumpAndSettle();
    expect(find.text("COUNTER Morning du'as"), findsOneWidget);
    expect(fake.calls, isEmpty);
  });

  testWidgets("a du'a row kept today still opens the counter from its tick",
      (WidgetTester tester) async {
    await tester.pumpWidget(_routerApp(
        HabitRow(view: _duaView(today: DayState.kept, value: 21)),
        FakeHabitActions()));
    await tester.tap(find.byTooltip("Count Morning du'as"));
    await tester.pumpAndSettle();
    expect(find.text("COUNTER Morning du'as"), findsOneWidget);
  });

  testWidgets("on a past day the du'a row keeps its + for that day",
      (WidgetTester tester) async {
    final FakeHabitActions fake = FakeHabitActions();
    final HabitDayView past = _duaView()
        .onDay('2026-11-03', today: '2026-11-04', weekStartsSunday: true);
    await tester.pumpWidget(_routerApp(HabitRow(view: past), fake));
    expect(find.byTooltip("Count Morning du'as"), findsNothing);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(fake.calls, ['add 1 1 2026-11-03']);
  });
}
