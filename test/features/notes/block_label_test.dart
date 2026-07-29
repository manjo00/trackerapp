import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/notes/domain/block_label.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 29, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  Future<NoteBlock> makeBlock(NoteBlockType type, String? content) async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: type, content: content, orderIndex: 0);
    final blocks = await dao.watchBlocks(note).first;
    return blocks.firstWhere((b) => b.id == id);
  }

  test('text block shows its trimmed content', () async {
    final b = await makeBlock(NoteBlockType.text, '  Vent settings noted  ');
    expect(blockLabel(b), 'Vent settings noted');
  });

  test('checkbox block shows its content', () async {
    final b = await makeBlock(NoteBlockType.checkbox, 'Order x-ray');
    expect(blockLabel(b), 'Order x-ray');
  });

  test('photo block is labelled "Photo" regardless of filename', () async {
    final b = await makeBlock(NoteBlockType.photo, 'abc.jpg');
    expect(blockLabel(b), 'Photo');
  });

  test('empty text and checkbox get muted placeholders', () async {
    final t = await makeBlock(NoteBlockType.text, '   ');
    final c = await makeBlock(NoteBlockType.checkbox, '');
    expect(blockLabel(t), 'Empty line');
    expect(blockLabel(c), 'Checklist item');
  });
}
