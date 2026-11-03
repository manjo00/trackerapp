import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/database/changed_elsewhere.dart';
import 'package:life_tracker/features/tasks/data/dao/lists_dao.dart';
import 'package:life_tracker/features/tasks/data/dao/tasks_dao.dart';
import 'package:life_tracker/features/tasks/data/repositories/tasks_repository.dart';
import 'package:path/path.dart' as p;

/// Since 2026-11-03 the widget's quick-add sheet runs in a window of its own,
/// with its own connection to the app's database file, as the live
/// notification's buttons already did. drift re-runs a screen's queries only
/// after writes made through the same connection, so a screen left open in
/// the app would keep missing a task the sheet added, until told to re-read.
void main() {
  late Directory dir;
  late AppDatabase app;
  late AppDatabase sheet;
  final List<StreamSubscription<Object?>> subs = [];

  // Two databases in one isolate are the point here (two windows, two
  // connections to one file), so drift's warning about that is expected.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(
      () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  setUp(() async {
    // The test's own scratch folder, removed again in tearDown.
    dir = await Directory.systemTemp.createTemp('uplan_two_windows');
    final File file = File(p.join(dir.path, 'life_tracker.db'));
    app = AppDatabase.forTesting(NativeDatabase(file));
    sheet = AppDatabase.forTesting(NativeDatabase(file));
  });

  tearDown(() async {
    for (final StreamSubscription<Object?> sub in subs) {
      await sub.cancel();
    }
    subs.clear();
    await app.close();
    await sheet.close();
    await dir.delete(recursive: true);
  });

  /// Waits up to two seconds for [ok], looking every 10 ms.
  Future<bool> soon(bool Function() ok) async {
    final DateTime end = DateTime.now().add(const Duration(seconds: 2));
    while (!ok()) {
      if (DateTime.now().isAfter(end)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return true;
  }

  test('a list screen shows a task the sheet added, once told', () async {
    final int listId = await ListsDao(app).insertList(
        TaskListsCompanion.insert(name: 'Errands', createdAt: DateTime.now()));
    final List<List<String>> seen = [];
    subs.add(TasksDao(app)
        .watchTasksForList(listId)
        .listen((tasks) => seen.add([for (final Task t in tasks) t.title])));
    expect(await soon(() => seen.isNotEmpty), isTrue);

    await TasksRepository(TasksDao(sheet)).addTask('Milk', listId: listId);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(seen.last, isEmpty,
        reason: "the app's queries don't hear the sheet's connection");

    app.markTasksChangedElsewhere();
    expect(await soon(() => seen.last.contains('Milk')), isTrue);
  });

  test("the sheet's list chips show a list the app added, once told",
      () async {
    final List<List<String>> seen = [];
    subs.add(ListsDao(sheet)
        .watchLists()
        .listen((lists) => seen.add([for (final TaskList l in lists) l.name])));
    expect(await soon(() => seen.isNotEmpty), isTrue);

    await ListsDao(app).insertList(
        TaskListsCompanion.insert(name: 'Gym', createdAt: DateTime.now()));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(seen.last, isNot(contains('Gym')),
        reason: "the sheet's queries don't hear the app's connection");

    sheet.markTasksChangedElsewhere();
    expect(await soon(() => seen.last.contains('Gym')), isTrue);
  });
}
