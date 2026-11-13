import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/workout/data/dao/program_dao.dart';
import 'package:life_tracker/features/workout/data/dao/workout_dao.dart';
import 'package:life_tracker/features/workout/data/repositories/program_repository.dart';
import 'package:life_tracker/features/workout/presentation/providers/program_providers.dart';
import 'package:life_tracker/features/workout/presentation/screens/program_session_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved workout in My Workouts gets a new name from its ✎ screen: tap the
/// name at the top, type the new one, Save (Ahmed's ask, 2026-11-13).
void main() {
  late AppDatabase db;
  late ProgramRepository repo;
  int programId = -1;
  int sessionId = -1;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProgramRepository(ProgramDao(db), WorkoutDao(db));
  });
  tearDown(() => db.close());

  /// Saves "Chest & arms" in My Workouts and opens its ✎ screen.
  Future<void> openEditor(WidgetTester tester) async {
    final (int, int)? ids =
        await tester.runAsync(() => repo.createMyWorkout('Chest & arms'));
    programId = ids?.$1 ?? -1;
    sessionId = ids?.$2 ?? -1;
    await tester.pumpWidget(ProviderScope(
      overrides: [programRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: ProgramSessionEditorScreen(
          programId: programId,
          sessionId: sessionId,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// The name in the database. Call it after [closeScreen]: a read made while
  /// the screen's database stream is open waits on it forever.
  Future<String?> savedName(WidgetTester tester) async =>
      (await tester.runAsync(
              () => ProgramDao(db).getProgramSessionById(sessionId)))
          ?.name;

  /// Taps the name at the top, types [name] and presses [button].
  Future<void> rename(WidgetTester tester, String name,
      {String button = 'Save'}) async {
    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), name);
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  /// Unmounts the screen, then lets drift's stream-closing timer run, so no
  /// timer is left pending when the test ends.
  Future<void> closeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('the name opens Rename, filled in with the current name',
      (WidgetTester tester) async {
    await openEditor(tester);
    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename workout'), findsOneWidget);
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.controller?.text, 'Chest & arms');
    await closeScreen(tester);
  });

  testWidgets('Save renames it, trimmed, and the title follows',
      (WidgetTester tester) async {
    await openEditor(tester);
    await rename(tester, '  Chest day  ');

    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Chest & arms'), findsNothing);
    await closeScreen(tester);
    expect(await savedName(tester), 'Chest day');
  });

  testWidgets('Cancel and an empty name keep the old name',
      (WidgetTester tester) async {
    await openEditor(tester);
    await rename(tester, 'Back day', button: 'Cancel');
    expect(find.text('Chest & arms'), findsOneWidget);
    expect(find.text('Rename workout'), findsNothing);

    await rename(tester, '   ');
    expect(find.text('Chest & arms'), findsOneWidget);
    await closeScreen(tester);
    expect(await savedName(tester), 'Chest & arms');
  });
}
