import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/habits/data/tables/habit_completions_table.dart';
import '../../features/habits/data/tables/habits_table.dart';

// build_runner writes app_database.g.dart next to this file.
// Never edit that file manually — always regenerate with build_runner.
part 'app_database.g.dart';

/// The single SQLite database for the whole app.
///
/// [DriftDatabase] lists every table and every DAO.  build_runner uses this
/// annotation to generate the SQL schema and the connection wiring.
///
/// How to open it:
/// ```dart
/// final db = AppDatabase();   // opens (or creates) life_tracker.db on device
/// ```
///
/// How to close it (important — call this when the app exits):
/// ```dart
/// await db.close();
/// ```
@DriftDatabase(tables: [Habits, HabitCompletions], daos: [HabitsDao])
class AppDatabase extends _$AppDatabase {
  /// Opens (or creates) the SQLite file at the path returned by
  /// [_openConnection].
  AppDatabase() : super(_openConnection());

  /// Used in tests to run queries against an in-memory database that is
  /// thrown away after each test — no files written to disk.
  AppDatabase.forTesting(super.executor);

  /// Schema version.  Increment this (and add a [MigrationStrategy]) any
  /// time you change a table definition after the app has shipped.
  @override
  int get schemaVersion => 1;
}

/// Builds the [NativeDatabase] that reads/writes the SQLite file.
///
/// [getApplicationDocumentsDirectory] returns the device's private documents
/// folder — the OS guarantees only our app can read it.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'life_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
