import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 10, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  test('notebook + note appear in their streams, filtered by notebook',
      () async {
    final nbA = await dao.createNotebook(
        name: 'A', colorValue: 0xFF000000, icon: '📓', now: now);
    final nbB = await dao.createNotebook(
        name: 'B', colorValue: 0xFF000000, icon: '📓', now: now);

    expect((await dao.watchNotebooks().first).length, 2);

    final note = await dao.createNote(notebookId: nbA, now: now);
    expect((await dao.watchNotes(nbA).first).map((n) => n.id), [note]);
    expect(await dao.watchNotes(nbB).first, isEmpty);

    final unfiled = await dao.createNote(notebookId: null, now: now);
    expect((await dao.watchNotes(null).first).map((n) => n.id), [unfiled]);
  });

  test('blocks return in order; checkbox toggle persists', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'a', orderIndex: 0);
    final cb = await dao.addBlock(
        noteId: note,
        type: NoteBlockType.checkbox,
        content: 'b',
        orderIndex: 1);
    await dao.addBlock(
        noteId: note,
        type: NoteBlockType.photo,
        content: 'img_1.jpg',
        orderIndex: 2);

    final blocks = await dao.watchBlocks(note).first;
    expect(blocks.map((b) => b.type), ['text', 'checkbox', 'photo']);

    await dao.setBlockChecked(cb, true);
    final after = await dao.watchBlocks(note).first;
    expect(after.firstWhere((b) => b.id == cb).checked, true);
  });

  test('deleting a note cascades its blocks', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 0);
    await dao.deleteNote(note);
    expect(await dao.watchBlocks(note).first, isEmpty);
  });

  test('reorderBlocks rewrites orderIndex to the new top-to-bottom order',
      () async {
    final note = await dao.createNote(now: now);
    final a = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'a', orderIndex: 0);
    final b = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'b', orderIndex: 1);
    final c = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'c', orderIndex: 2);

    await dao.reorderBlocks([c, a, b]); // move c to the top
    final ordered = await dao.watchBlocks(note).first;
    expect(ordered.map((x) => x.content), ['c', 'a', 'b']);
  });

  test('insertBlockAfter drops a block in the middle and shifts the rest',
      () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'a', orderIndex: 0);
    final b = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'b', orderIndex: 1);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'c', orderIndex: 2);

    // Enter pressed on "b" → a new "b2" line appears right after it.
    final bBlock = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == b);
    await dao.insertBlockAfter(
        noteId: note,
        type: NoteBlockType.text,
        content: 'b2',
        afterOrderIndex: bBlock.orderIndex);

    final ordered = await dao.watchBlocks(note).first;
    expect(ordered.map((x) => x.content), ['a', 'b', 'b2', 'c']);
  });

  test('setBlockFormat updates only the given flags', () async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 0);

    await dao.setBlockFormat(id, headingLevel: 2, bold: true);
    var b = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == id);
    expect(b.headingLevel, 2);
    expect(b.bold, true);
    expect(b.highlighted, false); // untouched
    expect(b.italic, false); // untouched

    await dao.setBlockFormat(id, highlighted: true);
    b = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == id);
    expect(b.highlighted, true);
    expect(b.headingLevel, 2); // still set
    expect(b.content, 'x'); // content never touched
  });

  test('deleting a notebook moves its notes to Unfiled (notebookId NULL)',
      () async {
    final nb = await dao.createNotebook(
        name: 'A', colorValue: 0xFF000000, icon: '📓', now: now);
    final note = await dao.createNote(notebookId: nb, now: now);
    await dao.deleteNotebook(nb);
    expect(await dao.watchNotes(nb).first, isEmpty);
    expect((await dao.watchNotes(null).first).map((n) => n.id), [note]);
  });

  test('watchLastNoteEditByNotebook returns the latest edit per notebook',
      () async {
    final nb = await dao.createNotebook(
        name: 'A', colorValue: 0, icon: '📓', now: DateTime(2026, 1, 1));
    final n1 = await dao.createNote(notebookId: nb, now: DateTime(2026, 1, 2));
    await dao.createNote(notebookId: nb, now: DateTime(2026, 1, 5));
    await dao.touchNote(n1, DateTime(2026, 1, 10)); // now the newest edit

    final map = await dao.watchLastNoteEditByNotebook().first;
    expect(map[nb], DateTime(2026, 1, 10));

    // A notebook with no notes is absent from the map.
    final empty = await dao.createNotebook(
        name: 'B', colorValue: 0, icon: '📓', now: DateTime(2026, 1, 1));
    final map2 = await dao.watchLastNoteEditByNotebook().first;
    expect(map2.containsKey(empty), false);
  });

  test('archived notebook and note leave the active streams', () async {
    final nb = await dao.createNotebook(
        name: 'A', colorValue: 0xFF000000, icon: '📓', now: now);
    final note = await dao.createNote(notebookId: nb, now: now);
    await dao.setNotebookArchived(nb, now);
    await dao.setNoteArchived(note, now);
    expect(await dao.watchNotebooks().first, isEmpty);
    expect(await dao.watchNotes(nb).first, isEmpty);
  });

  test('new blocks default to collapsed = false', () async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'Bed 1', orderIndex: 0);
    expect((await dao.getBlock(id))!.collapsed, isFalse);
  });

  test('setBlockCollapsed persists both ways', () async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'Bed 1', orderIndex: 0);
    await dao.setBlockCollapsed(id, true);
    expect((await dao.getBlock(id))!.collapsed, isTrue);
    await dao.setBlockCollapsed(id, false);
    expect((await dao.getBlock(id))!.collapsed, isFalse);
  });

  test('setAllHeadingsCollapsed flips only heading blocks', () async {
    final note = await dao.createNote(now: now);
    final h = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'H', orderIndex: 0);
    await dao.setBlockFormat(h, headingLevel: 1);
    final body = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 1);

    await dao.setAllHeadingsCollapsed(note, true);
    expect((await dao.getBlock(h))!.collapsed, isTrue);
    expect((await dao.getBlock(body))!.collapsed, isFalse); // body untouched
  });
}
