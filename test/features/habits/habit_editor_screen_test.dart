import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/database/database_provider.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/data/repositories/habits_repository.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';
import 'package:life_tracker/features/habits/presentation/screens/habit_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/habit_widget_helpers.dart';

void main() {
  late SharedPreferences prefs;
  late FakeHabitActions fake;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'week_starts_sunday': true});
    prefs = await SharedPreferences.getInstance();
    fake = FakeHabitActions();
  });

  /// A tall phone-sized screen, so the whole form is built and on screen.
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget editor({HabitModel? habit, List<Override> extra = const []}) =>
      ProviderScope(
        overrides: [
          habitActionsProvider.overrideWithValue(fake),
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...extra,
        ],
        child: MaterialApp(home: HabitEditorScreen(habit: habit)),
      );

  Future<void> save(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('a new every-day habit saves with 1 spare day',
      (WidgetTester tester) async {
    tallScreen(tester);
    await tester.pumpWidget(editor());
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Read');
    await save(tester, 'Save habit');
    final HabitModel h = fake.saved.single;
    expect((h.id, h.name, h.kind, h.schedule, h.sparesPerWeek),
        (0, 'Read', HabitKind.tick, HabitSchedule.daily, 1));
  });

  testWidgets('A few times a week hides spare days and saves perWeek',
      (WidgetTester tester) async {
    tallScreen(tester);
    await tester.pumpWidget(editor());
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Gym');
    await tester.tap(find.text('A few times a week'));
    await tester.pump();
    expect(find.text('Spare days a week'), findsNothing);
    await save(tester, 'Save habit');
    final HabitModel h = fake.saved.single;
    expect((h.schedule, h.perWeek, h.sparesPerWeek),
        (HabitSchedule.perWeek, 3, 0));
  });

  testWidgets('chosen days saves the mask and needs at least one day',
      (WidgetTester tester) async {
    tallScreen(tester);
    await tester.pumpWidget(editor());
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Walk');
    await tester.tap(find.text('Chosen days'));
    await tester.pump();
    // Untick Tuesday (bit 2) and Thursday (bit 8): 127 - 2 - 8 = 117.
    await tester.tap(find.byKey(const ValueKey('day-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('day-4')));
    await tester.pump();
    await save(tester, 'Save habit');
    expect(fake.saved.single.weekdayMask, 117);

    // A fresh editor with every day unticked can't be saved.
    fake.saved.clear();
    await tester.pumpWidget(Container());
    await tester.pumpWidget(editor());
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Walk');
    await tester.tap(find.text('Chosen days'));
    await tester.pump();
    for (int d = 1; d <= 7; d++) {
      await tester.tap(find.byKey(ValueKey('day-$d')));
      await tester.pump();
    }
    await tester.pump();
    await save(tester, 'Save habit');
    expect(fake.saved, isEmpty);
    expect(find.text('Pick at least one day'), findsOneWidget);
  });

  testWidgets('a count habit saves goal, unit and step',
      (WidgetTester tester) async {
    tallScreen(tester);
    await tester.pumpWidget(editor());
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Water');
    await tester.tap(find.text('Count'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal per day'), '8');
    await tester.enterText(find.widgetWithText(TextFormField, 'Unit'), 'glasses');
    await save(tester, 'Save habit');
    final HabitModel h = fake.saved.single;
    expect((h.kind, h.goal, h.unit, h.step),
        (HabitKind.count, 8, 'glasses', 1));
  });

  // ── Count units ──

  Future<void> newCount(WidgetTester tester, String name) async {
    tallScreen(tester);
    await tester.pumpWidget(editor());
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
    await tester.tap(find.text('Count'));
    await tester.pump();
  }

  testWidgets('the ml chip fills a goal of 2,000 and a step of 250',
      (WidgetTester tester) async {
    await newCount(tester, 'Water');
    await tester.tap(find.byKey(const ValueKey('unit-ml')));
    await tester.pump();
    expect(
        tester.widget<ChoiceChip>(find.byKey(const ValueKey('unit-ml'))).selected,
        isTrue);
    await save(tester, 'Save habit');
    final HabitModel h = fake.saved.single;
    expect((h.goal, h.unit, h.step), (2000, 'ml', 250));
  });

  testWidgets('a unit chip keeps a goal already typed',
      (WidgetTester tester) async {
    await newCount(tester, 'Duaa');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal per day'), '3');
    await tester.tap(find.byKey(const ValueKey('unit-times')));
    await tester.pump();
    await save(tester, 'Save habit');
    final HabitModel h = fake.saved.single;
    expect((h.goal, h.unit, h.step), (3, 'times', 1));
  });

  testWidgets('a goal can go up to 99,999', (WidgetTester tester) async {
    await newCount(tester, 'Walk');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal per day'), '10000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Unit'), 'steps');
    await save(tester, 'Save habit');
    expect((fake.saved.single.goal, fake.saved.single.unit), (10000, 'steps'));

    fake.saved.clear();
    await tester.pumpWidget(Container());
    await newCount(tester, 'Walk');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Goal per day'), '100000');
    await save(tester, 'Save habit');
    expect(fake.saved, isEmpty);
    expect(find.text('1 to 99,999'), findsOneWidget);
  });

  testWidgets('editing keeps the id', (WidgetTester tester) async {
    tallScreen(tester);
    await tester.pumpWidget(editor(
        habit: HabitModel(
            id: 5, name: 'Old', createdAt: DateTime(2026, 10, 1, 10))));
    expect(find.text('Edit habit'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'New');
    await save(tester, 'Save changes');
    expect((fake.saved.single.id, fake.saved.single.name), (5, 'New'));
  });

  testWidgets('Delete habit sends it to Recently deleted',
      (WidgetTester tester) async {
    tallScreen(tester);
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final int id = await tester.runAsync(() => HabitsRepository(HabitsDao(db))
            .saveHabit(HabitModel(
                id: 0, name: 'Old', createdAt: DateTime(2026, 10, 1, 10)))) ??
        0;
    await tester.pumpWidget(editor(
        habit: HabitModel(
            id: id, name: 'Old', createdAt: DateTime(2026, 10, 1, 10)),
        extra: [appDatabaseProvider.overrideWithValue(db)]));
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    final Habit row = (await tester.runAsync(
        () => (db.select(db.habits)..where((h) => h.id.equals(id))).getSingle()))!;
    expect(row.deletedAt, isNotNull);
    expect(fake.saved, isEmpty);
  });
}
