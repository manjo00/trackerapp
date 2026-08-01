import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/section_reorder.dart';

NoteBlock _b(int id,
        {String type = 'text', int heading = 0, bool collapsed = false}) =>
    NoteBlock(
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
      collapsed: collapsed,
    );

void main() {
  test('nothing collapsed: a line moves like a plain reorder', () {
    final blocks = [_b(10), _b(11), _b(12), _b(13)];
    // move id10 (visible index 0) down to slot 2 (post-removal convention)
    expect(reorderVisible(blocks, {}, 0, 2), [11, 12, 10, 13]);
  });

  test('a line dropped elsewhere is re-parented by position', () {
    final blocks = [_b(1, heading: 1), _b(2), _b(3, heading: 1), _b(4)];
    // drag id4 up to sit right under the first heading (visible slot 1)
    expect(reorderVisible(blocks, {}, 3, 1), [1, 4, 2, 3]);
  });

  test('a collapsed heading carries its hidden section when moved', () {
    // Bed 1 (collapsed) hides ids 2,3; Bed 2 is id 4 with line 5.
    final blocks = [
      _b(1, heading: 1, collapsed: true),
      _b(2), _b(3), // hidden under id1
      _b(4, heading: 1),
      _b(5),
    ];
    final hidden = {2, 3};
    // visible = [1,4,5]; drag the collapsed bed (visible 0) to the end (slot 2)
    expect(reorderVisible(blocks, hidden, 0, 2), [4, 5, 1, 2, 3]);
  });

  test('moving another tile leaves a collapsed bed intact', () {
    final blocks = [
      _b(1, heading: 1, collapsed: true),
      _b(2), _b(3), // hidden
      _b(4, heading: 1),
    ];
    final hidden = {2, 3};
    // visible = [1,4]; move id4 above the collapsed bed (slot 0)
    expect(reorderVisible(blocks, hidden, 1, 0), [4, 1, 2, 3]);
  });
}
