import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 29);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  test('new blocks default to unformatted body', () async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 0);
    final b = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == id);
    expect(b.headingLevel, 0);
    expect(b.highlighted, false);
    expect(b.bold, false);
    expect(b.italic, false);
  });

  test('divider type round-trips and parses', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note,
        type: NoteBlockType.divider,
        content: null,
        orderIndex: 0);
    final b = (await dao.watchBlocks(note).first).first;
    expect(NoteBlockType.parse(b.type), NoteBlockType.divider);
  });
}
