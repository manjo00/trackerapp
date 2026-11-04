import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/models/habit_day_view.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';
import 'package:life_tracker/features/habits/presentation/screens/habit_list_screen.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habits_week_strip.dart';
import 'package:life_tracker/features/shifts/data/models/work_shift_model.dart';
import 'package:life_tracker/features/shifts/presentation/providers/shifts_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/habit_widget_helpers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'week_starts_sunday': true});
    prefs = await SharedPreferences.getInstance();
  });

  /// The Habits screen with [views] as today's habits, inside a small router
  /// so the + button and the empty state can open the editor.
  Widget wrap(List<HabitDayView> views) {
    final GoRouter router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const HabitListScreen()),
      GoRoute(
        path: '/habits/add',
        builder: (_, __) => const Scaffold(body: Text('Add habit stub')),
      ),
    ]);
    return ProviderScope(
      overrides: [
        habitDayViewsProvider.overrideWithValue(AsyncData(views)),
        habitTodayProvider.overrideWith(FixedToday.new),
        habitActionsProvider.overrideWithValue(FakeHabitActions()),
        shiftsByDateProvider.overrideWith(
            (ref) => Stream.value(const <String, WorkShiftModel>{})),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows the sections, the week strip and the done count',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap([
      testView(
          id: 1,
          name: 'Stretch',
          section: HabitSection.wake,
          today: DayState.kept),
      testView(
          id: 2,
          name: 'Water',
          kind: HabitKind.count,
          goal: 8,
          unit: 'glasses',
          today: DayState.partial,
          value: 5),
      testView(id: 3, name: 'Read', section: HabitSection.sleep),
    ]));
    await tester.pump();
    expect(find.text('Wed 4 Nov'), findsOneWidget);
    expect(find.text('Day off'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.byType(HabitsWeekStrip), findsOneWidget);
    expect(find.text('ANY TIME'), findsOneWidget);
    expect(find.text('BEFORE SLEEP'), findsOneWidget);
    expect(find.text('Done today · 1'), findsOneWidget);
    // Let the coach tip's 350 ms timer run before the test ends.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the empty state offers Add your first habit',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const []));
    await tester.pump();
    expect(find.text('No habits yet'), findsOneWidget);
    await tester.tap(find.text('Add your first habit'));
    await tester.pumpAndSettle();
    expect(find.text('Add habit stub'), findsOneWidget);
  });

  testWidgets('the + button opens the editor', (WidgetTester tester) async {
    await tester.pumpWidget(wrap([testView()]));
    await tester.pump();
    await tester.tap(find.byTooltip('Add habit'));
    await tester.pumpAndSettle();
    expect(find.text('Add habit stub'), findsOneWidget);
  });
}
