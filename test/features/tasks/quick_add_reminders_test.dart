import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/database/database_provider.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';
import 'package:life_tracker/features/tasks/presentation/providers/lists_providers.dart';
import 'package:life_tracker/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:life_tracker/features/tasks/presentation/screens/quick_add_task_screen.dart';

/// The widget's quick-add sheet offers the same reminders as the full task
/// screen (1 day, 3 hours, 5 minutes before) plus a custom amount, as a row of
/// chips under the date and time (Ahmed, 2026-11-02: look B).
void main() {
  Future<_FakeAddTask> openSheet(WidgetTester tester) async {
    final _FakeAddTask addTask = _FakeAddTask();
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Sending closes the activity through the platform channel.
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        taskListsProvider.overrideWith((ref) => Stream.value(const [])),
        addTaskProvider.overrideWith(() => addTask),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: QuickAddTaskScreen()),
    ));
    await tester.pump();
    return addTask;
  }

  Future<void> setCustom(WidgetTester tester, String amount,
      {String? unit}) async {
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        amount);
    if (unit != null) await tester.tap(find.text(unit));
    await tester.pump(); // "Set" turns on once the typed amount is shown
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String title) async {
    await tester.enterText(find.byType(TextField).first, title);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    // The send button spins until Android closes the activity, which can't
    // happen in a test, so don't wait for the screen to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('the chosen reminders are saved with the task', (tester) async {
    final _FakeAddTask addTask = await openSheet(tester);
    await tester.tap(find.text('3 h'));
    await tester.pump();
    await setCustom(tester, '30');
    expect(find.text('30 min'), findsOneWidget);

    await send(tester, 'Pay rent');

    expect(addTask.saved, [(reminderEnabled: true, reminderLeadTimes: '180,30')]);
  });

  testWidgets('without reminders the task is saved without any',
      (tester) async {
    final _FakeAddTask addTask = await openSheet(tester);

    await send(tester, 'Pay rent');

    expect(addTask.saved, [(reminderEnabled: false, reminderLeadTimes: null)]);
  });

  testWidgets('a custom amount in hours shows as hours', (tester) async {
    await openSheet(tester);
    await setCustom(tester, '2', unit: 'hours');
    expect(find.text('2 h'), findsOneWidget);
  });

  testWidgets('tapping the custom chip again removes it', (tester) async {
    await openSheet(tester);
    await setCustom(tester, '30');
    await tester.tap(find.text('30 min'));
    await tester.pump();
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('a custom amount equal to a standard one ticks that one',
      (tester) async {
    final _FakeAddTask addTask = await openSheet(tester);
    await setCustom(tester, '5');
    expect(find.text('Custom'), findsOneWidget);

    await send(tester, 'Pay rent');

    expect(addTask.saved, [(reminderEnabled: true, reminderLeadTimes: '5')]);
  });

  testWidgets('says a date is needed when reminders have none',
      (tester) async {
    await openSheet(tester);
    expect(find.text('Set a date for reminders to go off'), findsNothing);
    await tester.tap(find.text('1 day'));
    await tester.pump();
    expect(find.text('Set a date for reminders to go off'), findsOneWidget);
  });
}

class _FakeAddTask extends AddTask {
  final List<({bool reminderEnabled, String? reminderLeadTimes})> saved = [];

  @override
  Future<int?> add(
    String title, {
    String? note,
    String? dueDate,
    String? dueTime,
    TaskPriority priority = TaskPriority.medium,
    bool reminderEnabled = false,
    String? reminderLeadTimes,
    int? listId,
    int? sectionId,
    int? durationMinutes,
  }) async {
    saved.add((
      reminderEnabled: reminderEnabled,
      reminderLeadTimes: reminderLeadTimes,
    ));
    return 7;
  }
}
