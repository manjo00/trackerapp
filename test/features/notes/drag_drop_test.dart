import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/drag_drop.dart';

NoteBlock _b(int id,
        {int heading = 0, int indent = 0, bool collapsed = false}) =>
    NoteBlock(
      id: id,
      noteId: 1,
      type: 'text',
      content: 't$id',
      checked: false,
      orderIndex: id,
      headingLevel: heading,
      highlighted: false,
      bold: false,
      italic: false,
      collapsed: collapsed,
      indent: indent,
    );

NoteBlock _photo(int id, {int indent = 0}) =>
    _b(id, indent: indent).copyWith(type: 'photo', content: const Value('x.jpg'));

/// A two-bed note plus a free line at the end:
///   1 H1 "Bed 1"      indent 0
///     2 line          indent 1
///     3 line          indent 1
///   4 H1 "Bed 2"      indent 0
///     5 line          indent 1
///   6 free line       indent 0
List<NoteBlock> _note() => [
      _b(1, heading: 1),
      _b(2, indent: 1),
      _b(3, indent: 1),
      _b(4, heading: 1),
      _b(5, indent: 1),
      _b(6),
    ];

void main() {
  group('structure helpers', () {
    test('bedSize covers a heading and everything nested under it', () {
      final n = _note();
      expect(bedSize(n, 0), 3); // Bed 1 + 2 lines
      expect(bedSize(n, 3), 2); // Bed 2 + 1 line
      expect(bedSize(n, 1), 1); // a plain line moves alone
    });

    test('containerIdOf finds the owning bed', () {
      final n = _note();
      expect(containerIdOf(n, 1), 1);
      expect(containerIdOf(n, 4), 4);
      expect(containerIdOf(n, 5), isNull); // free line
    });
  });

  group('dropping', () {
    test('a line dragged to the end leaves its bed (top level)', () {
      final a = applyDrop(
          full: _note(), hiddenIds: {}, draggedId: 2, gap: 5, enteredBedId: null)!;
      expect(a.orderedIds, [1, 3, 4, 5, 6, 2]);
      expect(a.indentById[2], 0); // out
    });

    test('dropping into another bed without holding snaps out after it', () {
      final a = applyDrop(
          full: _note(), hiddenIds: {}, draggedId: 6, gap: 2, enteredBedId: null)!;
      // lands between the beds, top level — Bed 1 is never split
      expect(a.orderedIds, [1, 2, 3, 6, 4, 5]);
      expect(a.indentById[6], 0);
    });

    test('holding over a header lets you nest inside it', () {
      final a = applyDrop(
          full: _note(), hiddenIds: {}, draggedId: 6, gap: 2, enteredBedId: 1)!;
      expect(a.orderedIds, [1, 2, 6, 3, 4, 5]);
      expect(a.indentById[6], 1); // inside Bed 1
    });

    test('dragging a heading carries its whole bed', () {
      final a = applyDrop(
          full: _note(), hiddenIds: {}, draggedId: 4, gap: 0, enteredBedId: null)!;
      expect(a.orderedIds, [4, 5, 1, 2, 3, 6]);
      expect(a.indentById[5], 1); // its line stays nested
    });

    test('a collapsed bed carries its hidden lines', () {
      final blocks = [
        _b(1, heading: 1, collapsed: true),
        _b(2, indent: 1), _b(3, indent: 1), // hidden
        _b(4, heading: 1), _b(5, indent: 1), _b(6),
      ];
      final a = applyDrop(
          full: blocks, hiddenIds: {2, 3}, draggedId: 1, gap: 3, enteredBedId: null)!;
      expect(a.orderedIds, [4, 5, 6, 1, 2, 3]);
      expect(a.indentById[2], 1);
    });


    test('a line leaves its bed by dragging DOWN past the last line', () {
      // The bug: "end of Bed 1" and "just after Bed 1" are the same gap, and
      // the tie used to break toward staying in — so the only way out was to
      // drag ABOVE the heading.
      final a = applyDrop(
          full: _note(), hiddenIds: {}, draggedId: 2, gap: 2, enteredBedId: null)!;
      expect(a.orderedIds, [1, 3, 2, 4, 5, 6]);
      expect(a.indentById[2], 0, reason: 'dragged down past the bed → out');
    });

    test('a photo can be dragged out downwards too (the reported case)', () {
      final blocks = [
        _b(1, heading: 1),
        _b(2, indent: 1),
        _photo(3, indent: 1), // tall photo, last line of the bed
        _b(4, heading: 1),
      ];
      // drop it just after its own bed's last line
      final a = applyDrop(
          full: blocks, hiddenIds: {}, draggedId: 2, gap: 2, enteredBedId: null)!;
      expect(a.indentById[2], 0);
    });

    test('reordering in the MIDDLE of a bed still keeps you in it', () {
      final blocks = [
        _b(1, heading: 1),
        _b(2, indent: 1), _b(3, indent: 1), _b(4, indent: 1),
        _b(5, heading: 1),
      ];
      // move id2 between id3 and id4 — strictly inside the bed
      final a = applyDrop(
          full: blocks, hiddenIds: {}, draggedId: 2, gap: 2, enteredBedId: null)!;
      expect(a.orderedIds, [1, 3, 2, 4, 5]);
      expect(a.indentById[2], 1, reason: 'still inside its bed');
    });

    test('dropping a line back where it started changes nothing', () {
      // Guards the fix: the LAST line of a bed sits exactly at the boundary,
      // so a no-move drop must not eject it.
      final blocks = [
        _b(1, heading: 1),
        _b(2, indent: 1), _b(3, indent: 1),
        _b(4, heading: 1),
      ];
      final a = applyDrop(
          full: blocks, hiddenIds: {}, draggedId: 3, gap: 2, enteredBedId: null)!;
      expect(a.orderedIds, [1, 2, 3, 4]);
      expect(a.indentById[3], 1, reason: 'unmoved last line stays in its bed');
    });

    test('nesting deeper: a line held into a sub-bed goes two levels in', () {
      final blocks = [
        _b(1, heading: 1), // site
        _b(2, heading: 2, indent: 1), // bed inside the site
        _b(3, indent: 2), // its line
        _b(4), // free line
      ];
      final a = applyDrop(
          full: blocks, hiddenIds: {}, draggedId: 4, gap: 2, enteredBedId: 2)!;
      expect(a.orderedIds, [1, 2, 4, 3]);
      expect(a.indentById[4], 2);
    });
  });
}
