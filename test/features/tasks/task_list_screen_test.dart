import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:life_tracker/features/tasks/data/models/task_model.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';
import 'package:life_tracker/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:life_tracker/features/tasks/presentation/screens/task_list_screen.dart';
import 'package:life_tracker/features/tasks/presentation/widgets/empty_tasks_placeholder.dart';
import 'package:life_tracker/features/tasks/presentation/widgets/task_tile.dart';

// ── Test helpers ──────────────────────────────────────────────────────────

/// Builds a minimal [TaskModel] for test use.
TaskModel _task(
  int id,
  String title, {
  bool done = false,
  String? dueDate,
  TaskPriority priority = TaskPriority.medium,
}) =>
    TaskModel(
      id: id,
      title: title,
      isCompleted: done,
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime(2026, 5, 27, id),
    );

/// Wraps [TaskListScreen] with the providers and router it needs.
///
/// Overrides [allTasksProvider] with a fixed list so no real database
/// is involved. Adds a stub route for `/tasks/add` so the FAB can
/// navigate without throwing.
Widget _wrap(Widget child, {required List<TaskModel> tasks}) {
  final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: '/tasks/add',
        builder: (_, __) => const Scaffold(body: Text('Add task stub')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      allTasksProvider.overrideWith(
        (ref) => Stream.value(tasks),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('TaskListScreen', () {
    testWidgets('shows empty placeholder when there are no tasks',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const TaskListScreen(), tasks: []));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyTasksPlaceholder), findsOneWidget);
      expect(find.byType(TaskTile), findsNothing);
    });

    testWidgets('renders one TaskTile per task with correct titles',
        (WidgetTester tester) async {
      final List<TaskModel> tasks = [
        _task(1, 'Buy groceries'),
        _task(2, 'Call dentist'),
      ];

      await tester.pumpWidget(_wrap(const TaskListScreen(), tasks: tasks));
      await tester.pumpAndSettle();

      expect(find.byType(TaskTile), findsNWidgets(2));
      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
    });

    testWidgets('FAB is present with correct tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const TaskListScreen(), tasks: []));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Add task'), findsOneWidget);
    });

    testWidgets('completed task title has strikethrough decoration',
        (WidgetTester tester) async {
      final List<TaskModel> tasks = [
        _task(1, 'Finished task', done: true),
      ];

      await tester.pumpWidget(_wrap(const TaskListScreen(), tasks: tasks));
      await tester.pumpAndSettle();

      final Finder textFinder = find.text('Finished task');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });
}
