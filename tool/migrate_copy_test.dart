import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

/// Opens the database file named by UPLAN_DB with the current code, so its
/// migrations run the way they do when the app opens it after an update. For
/// trying a schema bump on a COPY of a real database — never the original:
///
///   flutter test tool/migrate_copy_test.dart --dart-define=UPLAN_DB=<copy>
void main() {
  test('open (and upgrade) a database copy', () async {
    const String path = String.fromEnvironment('UPLAN_DB');
    if (path.isEmpty) {
      markTestSkipped('Pass --dart-define=UPLAN_DB=<a database copy>.');
      return;
    }
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(File(path)));
    final int version = (await db.customSelect('PRAGMA user_version').getSingle())
        .read<int>('user_version');
    expect(version, db.schemaVersion);
    await db.close();
  });
}
