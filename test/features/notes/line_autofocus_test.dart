import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/presentation/widgets/checkbox_block_view.dart';
import 'package:life_tracker/features/notes/presentation/widgets/text_block_view.dart';

/// A freshly added note line must get the cursor even when the note's lines
/// arrive from the database before the editor marks the new line for focus.
///
/// Regression (2026-11-01, Tester chat): on the emulator, tapping "Tap here to
/// start writing…" made an empty line with no cursor and no keyboard. The new
/// line was first built without `autofocus`, and a line only looked at
/// `autofocus` once, when it was first built.
NoteBlock _block(String type) => NoteBlock(
      id: 7,
      noteId: 1,
      type: type,
      content: '',
      checked: false,
      orderIndex: 0,
      headingLevel: 0,
      highlighted: false,
      bold: false,
      italic: false,
      collapsed: false,
      indent: 0,
    );

Future<void> _pump(WidgetTester tester, Widget line) => tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: Scaffold(body: line))),
    );

bool _lineHasFocus(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

void main() {
  testWidgets('a text line takes the cursor when marked after it was built',
      (tester) async {
    final NoteBlock block = _block('text');
    await _pump(tester, TextBlockView(block: block));
    await tester.pump();
    expect(_lineHasFocus(tester), isFalse);

    await _pump(tester, TextBlockView(block: block, autofocus: true));
    await tester.pump();
    expect(_lineHasFocus(tester), isTrue);
  });

  testWidgets('a checklist line takes the cursor when marked after it was built',
      (tester) async {
    final NoteBlock block = _block('checkbox');
    await _pump(tester, CheckboxBlockView(block: block));
    await tester.pump();
    expect(_lineHasFocus(tester), isFalse);

    await _pump(tester, CheckboxBlockView(block: block, autofocus: true));
    await tester.pump();
    expect(_lineHasFocus(tester), isTrue);
  });
}
