import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/notes/domain/note_text_style.dart';

void main() {
  test('heading font sizes by level', () {
    expect(noteHeadingFontSize(0), 16);
    expect(noteHeadingFontSize(1), 26);
    expect(noteHeadingFontSize(2), 22);
    expect(noteHeadingFontSize(3), 19);
    expect(noteHeadingFontSize(9), 16); // unknown → body
  });
}
