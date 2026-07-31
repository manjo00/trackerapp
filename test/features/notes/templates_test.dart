import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/images/image_storage_service.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/notes/data/repositories/notes_repository.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  late NotesRepository repo;
  final now = DateTime(2026, 7, 29, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
    repo = NotesRepository(dao, ImageStorageService());
  });
  tearDown(() async => db.close());

  test('templates are excluded from notebook views and listed separately',
      () async {
    final normal = await dao.createNote(now: now);
    final tmpl = await dao.createNote(now: now, isTemplate: true);
    expect((await dao.watchNotes(null).first).map((n) => n.id), [normal]);
    expect((await dao.watchTemplates().first).map((n) => n.id), [tmpl]);
  });

  test('insertBlocksAt drops a batch in the middle and shifts the rest',
      () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'a', orderIndex: 0);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'b', orderIndex: 1);

    await dao.insertBlocksAt(note, 1, [
      NoteBlocksCompanion.insert(
          noteId: 0, type: 'text', content: const Value('x')),
      NoteBlocksCompanion.insert(
          noteId: 0, type: 'text', content: const Value('y')),
    ]);

    final ordered = await dao.watchBlocks(note).first;
    expect(ordered.map((b) => b.content), ['a', 'x', 'y', 'b']);
  });

  test('saveAsTemplate + newNoteFromTemplate preserve blocks, formatting, order',
      () async {
    // Source note: a bold H2 heading, then a checked checkbox.
    final src = await dao.createNote(now: now);
    await dao.updateNoteTitle(src, 'Round', now);
    final h = await dao.addBlock(
        noteId: src, type: NoteBlockType.text, content: 'Bed 9', orderIndex: 0);
    await dao.setBlockFormat(h, headingLevel: 2, bold: true);
    final c = await dao.addBlock(
        noteId: src,
        type: NoteBlockType.checkbox,
        content: 'Bloods',
        orderIndex: 1);
    await dao.setBlockChecked(c, true);

    final tmpl = await repo.saveAsTemplate(src, now: now);
    // Template is hidden from notebooks + carries the copy.
    expect((await dao.watchNotes(null).first).map((n) => n.id), [src]);
    final tmplBlocks = await dao.watchBlocks(tmpl).first;
    expect(tmplBlocks.map((b) => b.content), ['Bed 9', 'Bloods']);
    expect(tmplBlocks[0].headingLevel, 2);
    expect(tmplBlocks[0].bold, true);
    expect(tmplBlocks[1].checked, true);

    // Instantiate into a fresh note.
    final made = await repo.newNoteFromTemplate(tmpl, now: now);
    final madeNote = (await dao.getNote(made))!;
    expect(madeNote.title, 'Round');
    expect(madeNote.isTemplate, false);
    final madeBlocks = await dao.watchBlocks(made).first;
    expect(madeBlocks.map((b) => b.content), ['Bed 9', 'Bloods']);
    expect(madeBlocks[0].headingLevel, 2);
    expect(madeBlocks[0].bold, true);
    expect(madeBlocks[1].checked, true);
  });

  test('insertTemplateInto splices a template after a position', () async {
    final tmpl = await dao.createNote(now: now, isTemplate: true);
    await dao.addBlock(
        noteId: tmpl, type: NoteBlockType.text, content: 'T1', orderIndex: 0);

    final target = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: target, type: NoteBlockType.text, content: 'A', orderIndex: 0);
    await dao.addBlock(
        noteId: target, type: NoteBlockType.text, content: 'B', orderIndex: 1);
    final targetBlocks = await dao.watchBlocks(target).first;

    // Insert the template right after 'A' (orderIndex 0).
    await repo.insertTemplateInto(
        tmpl, target, targetBlocks.first.orderIndex,
        now: now);
    final after = await dao.watchBlocks(target).first;
    expect(after.map((b) => b.content), ['A', 'T1', 'B']);
  });
}
