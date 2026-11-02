import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/database/database_provider.dart';
import 'package:life_tracker/features/tasks/data/models/task_model.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';
import 'package:life_tracker/features/tasks/presentation/providers/lists_providers.dart';
import 'package:life_tracker/features/tasks/presentation/screens/add_task_screen.dart';

/// The full task screen offers a 4th reminder, a custom amount before the due
/// time, under the three standard ones (Ahmed, 2026-11-02).
void main() {
  Future<void> openTask(WidgetTester tester, String leads) async {
    // Tall enough that the reminder ticks are built without scrolling, and wide
    // enough for the test font, whose square letters overflow the date row on
    // a phone-wide screen.
    tester.view.physicalSize = const Size(1600, 4000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        taskListsProvider.overrideWith((ref) => Stream.value(const [])),
        labelsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        home: AddTaskScreen(
          task: TaskModel(
            id: 1,
            title: 'Pay rent',
            dueDate: '2026-11-10',
            dueTime: '18:00',
            priority: TaskPriority.medium,
            isCompleted: false,
            createdAt: DateTime(2026, 11, 2),
            reminderEnabled: true,
            reminderLeadTimes: leads,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  bool ticked(WidgetTester tester, String title) =>
      tester.widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, title))
          .value ??
      false;

  testWidgets('reopening a task shows its custom reminder ticked',
      (tester) async {
    await openTask(tester, '1440,30');

    expect(ticked(tester, '1 day before'), isTrue);
    expect(ticked(tester, 'Custom: 30 minutes before'), isTrue);
  });

  testWidgets('ticking Custom asks for the amount and shows it',
      (tester) async {
    await openTask(tester, '180');
    expect(ticked(tester, 'Custom'), isFalse);

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        '45');
    await tester.pump(); // "Set" turns on once the typed amount is shown
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(ticked(tester, 'Custom: 45 minutes before'), isTrue);
    expect(ticked(tester, '3 hours before'), isTrue);
  });
}
