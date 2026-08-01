import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/section_fold.dart';

/// Builds a NoteBlock row for the pure helper. Named args match the generated
/// data class; only the fields the fold cares about are parameterised.
NoteBlock _b(
  int id, {
  String type = 'text',
  int heading = 0,
  bool collapsed = false,
  int order = 0,
}) =>
    NoteBlock(
      id: id,
      noteId: 1,
      type: type,
      content: 't',
      checked: false,
      orderIndex: order,
      headingLevel: heading,
      highlighted: false,
      bold: false,
      italic: false,
      collapsed: collapsed,
      indent: 0,
    );

void main() {
  test('no headings → nothing hidden', () {
    final f = computeSectionFold([_b(1), _b(2, order: 1)]);
    expect(f.hiddenIds, isEmpty);
    expect(f.hiddenCountByHeadingId, isEmpty);
  });

  test('flat: a collapsed heading hides its run until the next same-level heading',
      () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true), // A
      _b(2, order: 1), _b(3, order: 2), // hidden
      _b(4, heading: 1, order: 3), // B (visible)
      _b(5, order: 4), // visible
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2});
  });

  test('nested: collapsing H1 hides its H2 and that H2\'s content', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, heading: 2, order: 1, collapsed: true),
      _b(3, order: 2),
      _b(4, heading: 1, order: 3),
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2}); // count rolls up to the visible H1
  });

  test('collapsing only an inner H2 hides just its run', () {
    final f = computeSectionFold([
      _b(1, heading: 1),
      _b(2, heading: 2, order: 1, collapsed: true),
      _b(3, order: 2),
      _b(4, heading: 1, order: 3),
    ]);
    expect(f.hiddenIds, {3});
    expect(f.hiddenCountByHeadingId, {2: 1});
  });

  test('trailing collapsed section runs to end of note', () {
    final f = computeSectionFold([
      _b(1, order: 0),
      _b(2, heading: 1, order: 1, collapsed: true),
      _b(3, order: 2), _b(4, order: 3),
    ]);
    expect(f.hiddenIds, {3, 4});
    expect(f.hiddenCountByHeadingId, {2: 2});
  });

  test('collapsed heading with nothing under it hides nothing (0 count)', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, heading: 1, order: 1),
    ]);
    expect(f.hiddenIds, isEmpty);
    expect(f.hiddenCountByHeadingId, isEmpty);
  });

  test('non-text blocks under a collapsed heading are hidden too', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, type: 'checkbox', order: 1),
      _b(3, type: 'photo', order: 2),
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2});
  });
}
