import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/section_fold.dart';

/// Builds a NoteBlock. [heading] 1..3 makes it a heading; [indent] is the
/// outline depth that decides what belongs to what.
NoteBlock _b(
  int id, {
  String type = 'text',
  int heading = 0,
  int indent = 0,
  bool collapsed = false,
}) =>
    NoteBlock(
      id: id,
      noteId: 1,
      type: type,
      content: 't',
      checked: false,
      orderIndex: id,
      headingLevel: heading,
      highlighted: false,
      bold: false,
      italic: false,
      collapsed: collapsed,
      indent: indent,
    );

void main() {
  test('no headings → nothing hidden', () {
    final f = computeSectionFold([_b(1), _b(2)]);
    expect(f.hiddenIds, isEmpty);
    expect(f.hiddenCountByHeadingId, isEmpty);
  });

  test('a collapsed heading hides the lines nested under it', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, indent: 1), _b(3, indent: 1), // hidden
      _b(4, heading: 1), // next bed, visible
      _b(5, indent: 1), // its line, visible
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2});
  });

  test('collapsing an outer bed hides the bed nested inside it', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, heading: 2, indent: 1, collapsed: true),
      _b(3, indent: 2),
      _b(4, heading: 1),
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2}); // rolls up to the visible bed
  });

  test('collapsing only the inner bed hides just its lines', () {
    final f = computeSectionFold([
      _b(1, heading: 1),
      _b(2, heading: 2, indent: 1, collapsed: true),
      _b(3, indent: 2),
      _b(4, heading: 1),
    ]);
    expect(f.hiddenIds, {3});
    expect(f.hiddenCountByHeadingId, {2: 1});
  });

  test('a trailing collapsed bed runs to the end of the note', () {
    final f = computeSectionFold([
      _b(1),
      _b(2, heading: 1, collapsed: true),
      _b(3, indent: 1), _b(4, indent: 1),
    ]);
    expect(f.hiddenIds, {3, 4});
    expect(f.hiddenCountByHeadingId, {2: 2});
  });

  test('a collapsed heading with nothing under it hides nothing', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, heading: 1),
    ]);
    expect(f.hiddenIds, isEmpty);
    expect(f.hiddenCountByHeadingId, isEmpty);
  });

  test('a top-level line after a bed is NOT swallowed by it', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, indent: 1), // hidden
      _b(3), // dragged out to top level → stays visible
    ]);
    expect(f.hiddenIds, {2});
    expect(f.hiddenCountByHeadingId, {1: 1});
  });

  test('checkbox and photo lines under a collapsed bed hide too', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, type: 'checkbox', indent: 1),
      _b(3, type: 'photo', indent: 1),
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2});
  });
}
