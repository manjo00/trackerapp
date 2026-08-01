import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/section_reorder.dart';

/// Builds a NoteBlock; `heading` 0 = normal line, 1..3 = heading level.
NoteBlock _b(int id, {String type = 'text', int heading = 0}) => NoteBlock(
      id: id,
      noteId: 1,
      type: type,
      content: 't',
      checked: false,
      orderIndex: 0,
      headingLevel: heading,
      highlighted: false,
      bold: false,
      italic: false,
      collapsed: false,
    );

void main() {
  group('sectionGroupSize', () {
    test('a normal line is a group of one', () {
      final blocks = [_b(1), _b(2), _b(3)];
      expect(sectionGroupSize(blocks, 1), 1);
    });

    test('a heading includes its run until the next same-or-higher heading', () {
      final blocks = [
        _b(1, heading: 1), // H1  (index 0)
        _b(2), _b(3), // its lines
        _b(4, heading: 2), // nested H2
        _b(5), // its line
        _b(6, heading: 1), // next H1 ends the first section
      ];
      expect(sectionGroupSize(blocks, 0), 5); // H1 + 2 lines + H2 + 1 line
      expect(sectionGroupSize(blocks, 3), 2); // H2 + its 1 line
    });

    test('a trailing heading runs to the end', () {
      final blocks = [_b(1), _b(2, heading: 1), _b(3), _b(4)];
      expect(sectionGroupSize(blocks, 1), 3);
    });
  });

  group('reorderWithSections', () {
    test('moving a normal line matches plain reorder', () {
      final blocks = [_b(10), _b(11), _b(12), _b(13)];
      // move id10 (index0) down to slot 2 (post-removal convention)
      expect(reorderWithSections(blocks, 0, 2), [11, 12, 10, 13]);
    });

    test('a line can be re-parented under a different heading', () {
      final blocks = [
        _b(1, heading: 1), // H1
        _b(2), // under H1
        _b(3, heading: 1), // H2-as-H1 (second bed)
        _b(4), // under second bed
      ];
      // drag line id4 (index3) up to sit right under the first heading (slot 1)
      expect(reorderWithSections(blocks, 3, 1), [1, 4, 2, 3]);
    });

    test('a line can be dragged out to the top level', () {
      final blocks = [_b(1, heading: 1), _b(2), _b(3)];
      // drag id2 (index1) above the heading (slot 0)
      expect(reorderWithSections(blocks, 1, 0), [2, 1, 3]);
    });

    test('dragging a heading moves its whole section', () {
      final blocks = [
        _b(1, heading: 1), _b(2), _b(3), // first bed (H1 + 2 lines)
        _b(4, heading: 1), _b(5), // second bed (H1 + 1 line)
      ];
      // drag the first bed's heading (index0) to the end
      expect(reorderWithSections(blocks, 0, 4), [4, 5, 1, 2, 3]);
    });

    test('dragging a sub-heading moves its sub-section only', () {
      final blocks = [
        _b(1, heading: 1), // H1
        _b(2, heading: 2), _b(3), // H2 + line
        _b(4, heading: 1), // next bed
      ];
      // move the H2 section (index1, size 2) to the very top
      expect(reorderWithSections(blocks, 1, 0), [2, 3, 1, 4]);
    });

    test('dropping a heading inside its own section is a no-op', () {
      final blocks = [_b(1, heading: 1), _b(2), _b(3), _b(4, heading: 1)];
      expect(reorderWithSections(blocks, 0, 1), [1, 2, 3, 4]);
    });
  });
}
