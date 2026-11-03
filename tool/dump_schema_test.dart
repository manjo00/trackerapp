import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

/// Writes the current schema (every CREATE statement of a fresh database) to
/// `test/core/database/fixtures/schema_v<version>.sql`. Run it before a
/// schema bump, so the migration test can open a database of the old version:
///
///   flutter test tool/dump_schema_test.dart
void main() {
  test('dump the current schema', () async {
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
    final List<String> statements = [
      for (final row in await db
          .customSelect('SELECT sql FROM sqlite_master WHERE sql IS NOT NULL '
              "AND name NOT LIKE 'sqlite_%' ORDER BY rowid")
          .get())
        row.read<String>('sql'),
    ];
    final File out = File(
        'test/core/database/fixtures/schema_v${db.schemaVersion}.sql');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync('${statements.join(';\n')};\n');
    await db.close();
  });
}
