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
    MovableToday.day = '2026-11-04';
  });

  /// The Habits screen with [views] as today's habits, inside a small router
  /// so the + button and the empty state can open the editor. "Today" is
  /// [MovableToday.day] (Wed 4 Nov unless a test moves it).
  ///
  /// [visible] stands for the tab being in front: false is what another tab
  /// or a screen on top does to it (its tickers stop).
  Widget wrap(List<HabitDayView> views,
      {FakeHabitActions? fake, ValueNotifier<bool>? visible}) {
    final GoRouter router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => ValueListenableBuilder<bool>(
                valueListenable: visible ?? ValueNotifier<bool>(true),
                builder: (_, bool on, Widget? child) =>
                    TickerMode(enabled: on, child: child!),
                child: const HabitListScreen(),
              )),
      GoRoute(
        path: '/habits/add',
        builder: (_, __) => const Scaffold(body: Text('Add habit stub')),
      ),
    ]);
    return ProviderScope(
      overrides: [
        habitDayViewsProvider.overrideWithValue(AsyncData(views)),
        habitTodayProvider.overrideWith(MovableToday.new),
        habitActionsProvider.overrideWithValue(fake ?? FakeHabitActions()),
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

  // ── Ticking a past day from the week strip ──

  List<HabitDayView> twoHabits() => [
        testView(
            id: 1,
            name: 'Stretch',
            today: DayState.kept,
            entries: const {
              '2026-11-03': HabitEntry(1),
              '2026-11-04': HabitEntry(1),
            }),
        // Not ticked today or yesterday.
        testView(id: 3, name: 'Read', section: HabitSection.sleep),
      ];

  testWidgets('tapping yesterday shows that day to tick, and Back to today '
      'returns', (WidgetTester tester) async {
    final FakeHabitActions fake = FakeHabitActions();
    await tester.pumpWidget(wrap(twoHabits(), fake: fake));
    await tester.pump();
    // Open today's Done fold: a picked day starts with its folds closed.
    await tester.tap(find.text('Done today · 1'));
    await tester.pump();
    expect(find.text('Stretch'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Yesterday · Tue 3 Nov'), findsOneWidget);
    expect(find.text('Back to today'), findsOneWidget);
    expect(find.text('Done on Tue · 1'), findsOneWidget);
    expect(find.text('Stretch'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Tick Read'));
    expect(fake.calls, ['tick 3 2026-11-03']);

    await tester.tap(find.text('Back to today'));
    await tester.pump();
    expect(find.text('Wed 4 Nov'), findsOneWidget);
    expect(find.text('Back to today'), findsNothing);
    expect(find.text('Done today · 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a picked day that falls out of reach goes back to today',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(twoHabits()));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Back to today'), findsOneWidget);
    // Twelve days later, Tue 3 Nov is older than last week.
    MovableToday.day = '2026-11-16';
    ProviderScope.containerOf(tester.element(find.byType(HabitListScreen)))
        .invalidate(habitTodayProvider);
    await tester.pump();
    expect(find.text('Mon 16 Nov'), findsOneWidget);
    expect(find.text('Back to today'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('leaving the screen or the app brings today back',
      (WidgetTester tester) async {
    final ValueNotifier<bool> visible = ValueNotifier<bool>(true);
    await tester.pumpWidget(wrap(twoHabits(), visible: visible));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Back to today'), findsOneWidget);

    // Another tab, or the editor on top, then back to Habits.
    visible.value = false;
    await tester.pump();
    visible.value = true;
    await tester.pump();
    expect(find.text('Back to today'), findsNothing);
    expect(find.text('Wed 4 Nov'), findsOneWidget);

    // The app sent to the background and opened again.
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Back to today'), findsOneWidget);
    for (final AppLifecycleState s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(find.text('Back to today'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });
}

/// A "today" a test can move: Wed 4 Nov 2026 unless set.
class MovableToday extends HabitToday {
  static String day = '2026-11-04';

  @override
  String build() => day;
}
