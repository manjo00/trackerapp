import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/database/database_provider.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:life_tracker/features/notes/presentation/widgets/checkbox_block_view.dart';
import 'package:life_tracker/features/notes/presentation/widgets/text_block_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Leaving the note editor must keep what was typed, even when the line was
/// never left first (no Enter, no tap elsewhere).
///
/// Regression (2026-11-01, Tester chat): a new note with one typed line
/// vanished on Back. The leave-time cleanup read the line as still empty
/// (its save only ran on focus loss, after the read) and deleted it, and then
/// the note itself as empty.
void main() {
  late AppDatabase db;
  late NotesDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });

  tearDown(() => db.close());

  /// Opens [noteId] in the real editor, pushed over a plain home page so
  /// Back has somewhere to go.
  Future<void> openEditor(WidgetTester tester, int noteId) async {
    SharedPreferences.setMockInitialValues({
      'coach_seen_tips': <String>['noteEditor.arrange', 'noteEditor.menu'],
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NoteEditorScreen(noteId: noteId),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder lineField() => find.descendant(
        of: find.byType(TextBlockView),
        matching: find.byType(TextField),
      );

  /// Android's Back button (or gesture). Unlike tapping the app bar's arrow, it
  /// is not a tap outside the line, so the line keeps focus while the editor
  /// closes; that is the path that lost notes on the phone.
  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  /// The app stops being in front (Android reports "inactive" first).
  void leaveApp(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }

  void resumeApp(WidgetTester tester) =>
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  /// Lets the database streams' cleanup timers run before the test ends.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a new note keeps its typed first line after Back',
      (tester) async {
    final int noteId = await dao.createNote(now: DateTime(2026, 11, 1));
    await openEditor(tester, noteId);

    await tester.tap(find.text('Tap here to start writing…'));
    await tester.pumpAndSettle();
    await tester.enterText(lineField(), 'Buy milk');
    await tester.pump();

    await systemBack(tester);

    expect(await dao.getNote(noteId), isNotNull,
        reason: 'the note must not be deleted as empty');
    final List<NoteBlock> blocks = await dao.getBlocks(noteId);
    expect(blocks.map((b) => b.content), ['Buy milk']);
    await closeApp(tester);
  });

  testWidgets('a typed line is saved as soon as the app is left',
      (tester) async {
    final int noteId = await dao.createNote(now: DateTime(2026, 11, 1));
    await openEditor(tester, noteId);
    await tester.tap(find.text('Tap here to start writing…'));
    await tester.pumpAndSettle();
    await tester.enterText(lineField(), 'Gym at six');
    await tester.pump();

    // Home button, app switcher or the notification shade: Android may then
    // close the app at any time without the line ever losing focus.
    leaveApp(tester);
    await tester.pump();

    final List<NoteBlock> blocks = await dao.getBlocks(noteId);
    expect(blocks.map((b) => b.content), ['Gym at six']);
    resumeApp(tester);
    await closeApp(tester);
  });

  testWidgets('a typed checklist line is saved as soon as the app is left',
      (tester) async {
    final int noteId = await dao.createNote(now: DateTime(2026, 11, 1));
    await dao.addBlock(
        noteId: noteId, type: NoteBlockType.checkbox, orderIndex: 0);
    await openEditor(tester, noteId);
    final Finder checklistField = find.descendant(
      of: find.byType(CheckboxBlockView),
      matching: find.byType(TextField),
    );
    await tester.tap(checklistField);
    await tester.pump();
    await tester.enterText(checklistField, 'Pack the charger');
    await tester.pump();

    leaveApp(tester);
    await tester.pump();

    final List<NoteBlock> blocks = await dao.getBlocks(noteId);
    expect(blocks.map((b) => b.content), ['Pack the charger']);
    resumeApp(tester);
    await closeApp(tester);
  });

  testWidgets('a freshly added line gets the cursor', (tester) async {
    final int noteId = await dao.createNote(now: DateTime(2026, 11, 1));
    await openEditor(tester, noteId);

    await tester.tap(find.text('Tap here to start writing…'));
    await tester.pumpAndSettle();

    final EditableText line =
        tester.widget<EditableText>(find.descendant(
      of: find.byType(TextBlockView),
      matching: find.byType(EditableText),
    ));
    expect(line.focusNode.hasFocus, isTrue);
    await closeApp(tester);
  });

  testWidgets('an untouched new note is still removed on Back',
      (tester) async {
    final int noteId = await dao.createNote(now: DateTime(2026, 11, 1));
    await openEditor(tester, noteId);

    await systemBack(tester);

    expect(await dao.getNote(noteId), isNull);
    await closeApp(tester);
  });
}
