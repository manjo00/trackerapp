import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/note_outline.dart';

NoteBlock _b(int id, {String type = 'text', int heading = 0, String content = 't'}) =>
    NoteBlock(
      id: id,
      noteId: 1,
      type: type,
      content: content,
      checked: false,
      orderIndex: 0,
      headingLevel: heading,
      highlighted: false,
      bold: false,
      italic: false,
      collapsed: false,
    );

void main() {
  group('blockDepths', () {
    test('lines under a heading are one level deeper', () {
      final d = blockDepths([
        _b(1, heading: 1), // H1  → 0
        _b(2), // line → 1
        _b(3), // line → 1
        _b(4, heading: 1), // next H1 → 0
        _b(5), // line → 1
      ]);
      expect(d, {1: 0, 2: 1, 3: 1, 4: 0, 5: 1});
    });

    test('a nested heading and its lines go one level deeper again', () {
      final d = blockDepths([
        _b(1, heading: 1), // H1  → 0
        _b(2, heading: 2), // H2  → 1
        _b(3), // under H2 → 2
        _b(4, heading: 1), // back to H1 → 0
      ]);
      expect(d, {1: 0, 2: 1, 3: 2, 4: 0});
    });

    test('lines before any heading stay at the base margin', () {
      final d = blockDepths([_b(1), _b(2, heading: 1), _b(3)]);
      expect(d, {1: 0, 2: 0, 3: 1});
    });
  });

  group('lineStartsRtl', () {
    test('Latin / digits / empty read left-to-right', () {
      expect(lineStartsRtl('Bed 9 vent'), isFalse);
      expect(lineStartsRtl('123 test'), isFalse);
      expect(lineStartsRtl(''), isFalse);
    });

    test('Arabic reads right-to-left', () {
      expect(lineStartsRtl('سرير ٩'), isTrue);
      expect(lineStartsRtl('غرفة 3'), isTrue);
    });
  });
}
