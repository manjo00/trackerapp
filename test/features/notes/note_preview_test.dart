import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/notes/domain/note_preview.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 28, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  Future<List<NoteBlock>> blocksFor(int noteId) => dao.watchBlocks(noteId).first;

  test('first photo, snippet from first text, and total photo count', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'Bed 9 vent', orderIndex: 0);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'a.jpg', orderIndex: 1);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'b.jpg', orderIndex: 2);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'later line', orderIndex: 3);

    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, 'a.jpg');
    expect(p.snippet, 'Bed 9 vent');
    expect(p.photoCount, 2);
  });

  test('checkbox text counts as snippet source; blank/whitespace ignored', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: '   ', orderIndex: 0);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.checkbox, content: 'take bloods', orderIndex: 1);

    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, isNull);
    expect(p.snippet, 'take bloods');
    expect(p.photoCount, 0);
  });

  test('photos only → empty snippet, first filename set', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'only.jpg', orderIndex: 0);

    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, 'only.jpg');
    expect(p.snippet, '');
    expect(p.photoCount, 1);
  });

  test('empty note → all defaults', () async {
    final note = await dao.createNote(now: now);
    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, isNull);
    expect(p.snippet, '');
    expect(p.photoCount, 0);
  });
}
