import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/note_preview.dart';
import 'package:life_tracker/features/notes/domain/note_sort.dart';

/// The two pure pieces of the notes quick-wins bundle: how a notebook orders
/// its notes, and which photo a card shows once a cover can be chosen.
void main() {
  final DateTime t0 = DateTime(2026, 9, 1, 9);

  Note note({
    required int id,
    String title = '',
    bool starred = false,
    int editedHoursAgo = 0,
    int createdHoursAgo = 0,
    int? coverBlockId,
  }) =>
      Note(
        id: id,
        notebookId: null,
        title: title,
        createdAt: t0.subtract(Duration(hours: createdHoursAgo)),
        updatedAt: t0.subtract(Duration(hours: editedHoursAgo)),
        archivedAt: null,
        deletedAt: null,
        isTemplate: false,
        isFavorite: starred,
        coverBlockId: coverBlockId,
      );

  NoteBlock block(int id, String type, String? content) => NoteBlock(
        id: id,
        noteId: 1,
        type: type,
        content: content,
        checked: false,
        orderIndex: id,
        headingLevel: 0,
        highlighted: false,
        bold: false,
        italic: false,
        collapsed: false,
        indent: 0,
      );

  group('sortNotes', () {
    // Edited order: a (freshest), b, c. Created order differs on purpose.
    final Note a = note(id: 1, title: 'Zebra', editedHoursAgo: 0, createdHoursAgo: 5);
    final Note b = note(id: 2, title: 'apple', editedHoursAgo: 1, createdHoursAgo: 1, starred: true);
    final Note c = note(id: 3, title: '', editedHoursAgo: 2, createdHoursAgo: 0);
    final List<Note> shuffled = [c, a, b];

    test('last edited is the default and puts the freshest first', () {
      expect(sortNotes(shuffled, NoteSort.edited).map((n) => n.id), [1, 2, 3]);
    });

    test('date created is a different order from last edited', () {
      expect(sortNotes(shuffled, NoteSort.created).map((n) => n.id), [3, 2, 1]);
    });

    test('name ignores case and puts untitled notes last', () {
      expect(sortNotes(shuffled, NoteSort.name).map((n) => n.id), [2, 1, 3]);
    });

    test('starred first, then by last edited', () {
      expect(sortNotes(shuffled, NoteSort.starred).map((n) => n.id), [2, 1, 3]);
    });

    test('does not mutate the input', () {
      final List<Note> input = [c, a, b];
      sortNotes(input, NoteSort.name);
      expect(input.map((n) => n.id), [3, 1, 2]);
    });

    test('fromKey falls back to the default for anything unknown', () {
      expect(NoteSort.fromKey('starred'), NoteSort.starred);
      expect(NoteSort.fromKey('bogus'), NoteSort.edited);
      expect(NoteSort.fromKey(null), NoteSort.edited);
    });
  });

  group('sortNotebooks', () {
    Notebook nb({
      required int id,
      required String name,
      bool starred = false,
      int createdHoursAgo = 0,
    }) =>
        Notebook(
          id: id,
          name: name,
          colorValue: 0,
          icon: '📓',
          orderIndex: id,
          createdAt: t0.subtract(Duration(hours: createdHoursAgo)),
          archivedAt: null,
          deletedAt: null,
          isFavorite: starred,
        );

    // Created order: work (newest), home, ideas (oldest). Activity differs:
    // "ideas" had a note edited just now, "home" is starred.
    final Notebook work = nb(id: 1, name: 'Work', createdHoursAgo: 1);
    final Notebook home = nb(id: 2, name: 'home', createdHoursAgo: 5, starred: true);
    final Notebook ideas = nb(id: 3, name: 'Ideas', createdHoursAgo: 48);
    final Map<int, DateTime> lastEdit = {3: t0}; // ideas edited most recently
    final List<Notebook> shuffled = [home, ideas, work];

    test('last edited counts a note edit inside the notebook as activity', () {
      // ideas is the oldest notebook but has the freshest note.
      expect(sortNotebooks(shuffled, NoteSort.edited, lastEdit).map((n) => n.id),
          [3, 1, 2]);
    });

    test('an empty notebook falls back to its own creation time', () {
      expect(sortNotebooks(shuffled, NoteSort.edited, const {}).map((n) => n.id),
          [1, 2, 3]);
    });

    test('date created ignores note activity', () {
      expect(sortNotebooks(shuffled, NoteSort.created, lastEdit).map((n) => n.id),
          [1, 2, 3]);
    });

    test('name is case-insensitive', () {
      expect(sortNotebooks(shuffled, NoteSort.name, lastEdit).map((n) => n.id),
          [2, 3, 1]);
    });

    test('starred first, then by activity', () {
      expect(sortNotebooks(shuffled, NoteSort.starred, lastEdit).map((n) => n.id),
          [2, 3, 1]);
    });
  });

  group('notePreview cover photo', () {
    final List<NoteBlock> blocks = [
      block(10, 'text', 'Shopping for the weekend'),
      block(11, 'photo', 'first.jpg'),
      block(12, 'photo', 'second.jpg'),
    ];

    test('with no choice the first photo is the cover', () {
      expect(notePreview(blocks).firstPhotoFilename, 'first.jpg');
    });

    test('a chosen block becomes the cover', () {
      expect(
        notePreview(blocks, coverBlockId: 12).firstPhotoFilename,
        'second.jpg',
      );
    });

    test('a chosen block that no longer exists falls back to the first', () {
      // The cover photo was removed from the note: the stored id points at
      // nothing, and the card must not go blank or show a broken image.
      expect(
        notePreview(blocks, coverBlockId: 99).firstPhotoFilename,
        'first.jpg',
      );
    });

    test('the photo count is unaffected by the cover choice', () {
      expect(notePreview(blocks, coverBlockId: 12).photoCount, 2);
    });
  });
}
