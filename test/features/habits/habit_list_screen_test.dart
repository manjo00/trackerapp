import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/data/models/habit_with_status.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';
import 'package:life_tracker/features/habits/presentation/screens/habit_list_screen.dart';
import 'package:life_tracker/features/habits/presentation/widgets/empty_habits_placeholder.dart';
import 'package:life_tracker/features/habits/presentation/widgets/habit_tile.dart';

// ── Test helpers ──────────────────────────────────────────────────────────

/// Builds a minimal [HabitModel] for use in tests.
HabitModel _habit(int id, String name) => HabitModel(
      id: id,
      name: name,
      createdAt: DateTime(2026, 5, 26),
      targetPerWeek: 7,
    );

/// Builds a [HabitWithStatus] with sensible defaults.
HabitWithStatus _item(int id, String name, {bool done = false, int streak = 0}) =>
    HabitWithStatus(
      habit: _habit(id, name),
      isDoneToday: done,
      streak: streak,
    );

/// Wraps the widget under test with the providers, theme, and router
/// that [HabitListScreen] needs to function.
Widget _wrap(
  Widget child, {
  required List<HabitWithStatus> habits,
}) {
  // A minimal GoRouter so context.push('/habits/add') doesn't throw.
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: '/habits/add',
        builder: (_, __) => const Scaffold(body: Text('Add habit stub')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      // Override the real stream provider with a fixed list.
      // AsyncValue.data(...) mimics "stream emitted data".
      habitsWithStatusProvider.overrideWith(
        (ref) => Stream.value(habits),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('HabitListScreen', () {
    testWidgets('shows empty placeholder when there are no habits',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HabitListScreen(), habits: []));

      // pumpAndSettle waits for all animations and async work to finish.
      await tester.pumpAndSettle();

      expect(find.byType(EmptyHabitsPlaceholder), findsOneWidget);
      expect(find.byType(HabitTile), findsNothing);
    });

    testWidgets('renders one HabitTile per habit', (WidgetTester tester) async {
      final List<HabitWithStatus> habits = [
        _item(1, 'Read'),
        _item(2, 'Exercise'),
      ];

      await tester.pumpWidget(_wrap(const HabitListScreen(), habits: habits));
      await tester.pumpAndSettle();

      // Should find exactly two tiles.
      expect(find.byType(HabitTile), findsNWidgets(2));

      // Habit names should be visible.
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
    });

    testWidgets('FAB is present with correct tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HabitListScreen(), habits: []));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Add habit'), findsOneWidget);
    });

    testWidgets('completed habit shows strikethrough text',
        (WidgetTester tester) async {
      final List<HabitWithStatus> habits = [
        _item(1, 'Morning run', done: true, streak: 3),
      ];

      await tester.pumpWidget(_wrap(const HabitListScreen(), habits: habits));
      await tester.pumpAndSettle();

      // Find the Text widget that holds the habit name and check decoration.
      final Finder textFinder = find.text('Morning run');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(
        textWidget.style?.decoration,
        TextDecoration.lineThrough,
      );
    });
  });
}
