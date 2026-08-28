import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/notes/domain/note_search.dart';

/// Notes are usually written straight into the body with no title at all, so
/// the two things that matter here are: does searching look inside, and does an
/// untitled note still come back as something readable.
void main() {
  const NoteSearchItem shopping = NoteSearchItem(
    id: 1,
    title: 'Shopping',
    text: 'Milk\nBread\nCall the landlord about the boiler',
    notebookId: 2,
    notebookName: 'Home',
  );
  const NoteSearchItem untitled = NoteSearchItem(
    id: 2,
    title: '   ',
    text: 'Book the campsite\nBring the shopping bags',
    notebookId: null,
    notebookName: 'Unfiled',
  );
  const NoteSearchItem empty = NoteSearchItem(
    id: 3,
    title: '',
    text: '',
    notebookId: null,
    notebookName: 'Unfiled',
  );
  const List<NoteSearchItem> all = [shopping, untitled, empty];

  group('displayTitle', () {
    test('uses the title when there is one', () {
      expect(shopping.displayTitle, 'Shopping');
    });

    test('falls back to the first written line', () {
      expect(untitled.displayTitle, 'Book the campsite');
    });

    test('has something to say for a wholly empty note', () {
      expect(empty.displayTitle, 'Untitled note');
    });
  });

  group('searchNotes', () {
    test('finds a note by a line inside it', () {
      expect(searchNotes(all, 'campsite').map((n) => n.id), [2]);
    });

    test('finds a note by its title', () {
      expect(searchNotes(all, 'Shopping').map((n) => n.id), [1, 2]);
    });

    test('ranks the note titled Shopping above one that just mentions it', () {
      expect(searchNotes(all, 'shopping').first.id, 1);
    });

    test('matches the fallback title of an untitled note', () {
      expect(searchNotes(all, 'Book the').map((n) => n.id), [2]);
    });

    test('empty query returns everything unchanged', () {
      expect(searchNotes(all, '  '), all);
    });

    test('no match returns empty', () {
      expect(searchNotes(all, 'kayak'), isEmpty);
    });
  });

  group('noteMatchLine', () {
    test('returns the line that matched', () {
      expect(noteMatchLine(shopping, 'landlord'),
          'Call the landlord about the boiler');
    });

    test('returns null when the heading already shows the match', () {
      expect(noteMatchLine(shopping, 'shopping'), isNull);
      // The untitled note's heading IS its first line, so a match there is
      // already visible too.
      expect(noteMatchLine(untitled, 'campsite'), isNull);
    });

    test('returns null for an empty query', () {
      expect(noteMatchLine(shopping, ''), isNull);
    });
  });
}
