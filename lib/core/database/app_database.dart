import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/habits/data/tables/habit_completions_table.dart';
import '../../features/habits/data/tables/habits_table.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../../features/tasks/data/tables/tasks_table.dart';

part 'app_database.g.dart';

/// The single SQLite database for the whole app.
///
/// ## Adding a new feature checklist
/// 1. Create a table class in `features/{feature}/data/tables/`
/// 2. Create a DAO class in `features/{feature}/data/dao/`
/// 3. Add both to the lists in the [@DriftDatabase] annotation below
/// 4. Bump [schemaVersion] and add a migration step in [migration]
/// 5. Run `dart run build_runner build --delete-conflicting-outputs`
@DriftDatabase(
  tables: [Habits, HabitCompletions, Tasks],
  daos: [HabitsDao, TasksDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used in tests — runs against an in-memory DB, nothing written to disk.
  AppDatabase.forTesting(super.executor);

  /// Increment every time a table is added, removed, or changed.
  ///
  /// v1 → initial schema (habits, habit_completions)
  /// v2 → added tasks table
  @override
  int get schemaVersion => 2;

  /// Drift calls this when an existing device upgrades from an older version.
  ///
  /// Each `if (from < N)` block is additive — a device jumping from v1 to v3
  /// would run all intermediate blocks in order.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // Fresh install — create all tables at once.
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Added in v2: tasks table.
            await m.createTable(tasks);
          }
        },
      );
}

/// Builds the [NativeDatabase] pointing at the SQLite file on device.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'life_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
