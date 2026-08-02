import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:life_tracker/features/tasks/data/models/task_model.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';
import 'package:life_tracker/features/tasks/presentation/providers/lists_providers.dart';
import 'package:life_tracker/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:life_tracker/features/tasks/presentation/widgets/task_detail_sheet.dart';
import 'package:life_tracker/features/tasks/presentation/widgets/task_tile.dart';

/// Records completion toggles instead of writing to a database, so these
/// tests can assert "tap did NOT complete" directly.
class _RecordingToggle extends ToggleTask {
  static final List<int> calls = [];

  @override
  Future<void> build() async {}

  @override
  Future<void> toggle(int id, {required bool currentlyCompleted}) async {
    calls.add(id);
  }
}

TaskModel _task(int id, String title) => TaskModel(
      id: id,
      title: title,
      isCompleted: false,
      priority: TaskPriority.medium,
      createdAt: DateTime(2026, 8, 1, 9),
    );

Widget _wrap(Widget child) {
  final GoRouter router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
    GoRoute(
        path: '/tasks/edit',
        builder: (_, __) => const Scaffold(body: Text('Edit stub'))),
    GoRoute(
        path: '/lists/:id',
        builder: (_, __) => const Scaffold(body: Text('List stub'))),
  ]);
  return ProviderScope(
    overrides: [
      toggleTaskProvider.overrideWith(_RecordingToggle.new),
      taskListsProvider.overrideWith((ref) => Stream.value(const [])),
      labelsProvider.overrideWith((ref) => Stream.value(const [])),
      labelIdsForTaskProvider
          .overrideWith((ref, taskId) => Stream.value(const <int>[])),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(_RecordingToggle.calls.clear);

  testWidgets('tapping the tile BODY opens the detail sheet, never completes',
      (tester) async {
    await tester.pumpWidget(_wrap(TaskTile(task: _task(1, 'Check vent'))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check vent'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailSheet), findsOneWidget);
    expect(_RecordingToggle.calls, isEmpty,
        reason: 'a body tap must never mark a task done');
  });

  testWidgets('tapping the CIRCLE completes without opening the sheet',
      (tester) async {
    await tester.pumpWidget(_wrap(TaskTile(task: _task(7, 'Check vent'))));
    await tester.pumpAndSettle();

    // The tile's single AnimatedContainer is the check circle.
    await tester.tap(find.descendant(
        of: find.byType(TaskTile), matching: find.byType(AnimatedContainer)));
    await tester.pumpAndSettle();

    expect(_RecordingToggle.calls, [7]);
    expect(find.byType(TaskDetailSheet), findsNothing);
  });

  testWidgets('sheet shows Captured for list-less tasks and Edit navigates',
      (tester) async {
    await tester.pumpWidget(_wrap(TaskTile(task: _task(3, 'Check vent'))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check vent'));
    await tester.pumpAndSettle();
    expect(find.text('Captured'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit stub'), findsOneWidget);
  });
}
