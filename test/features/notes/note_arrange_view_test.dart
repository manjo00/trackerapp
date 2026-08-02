import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/presentation/widgets/note_arrange_view.dart';

NoteBlock _b(int id, {int heading = 0, int indent = 0}) => NoteBlock(
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
      collapsed: false,
      indent: indent,
    );

/// Bed 1 (id 1) with line 2 · Bed 2 (id 3) with line 4 · free line 5.
List<NoteBlock> _note() => [
      _b(1, heading: 1),
      _b(2, indent: 1),
      _b(3, heading: 1),
      _b(4, indent: 1),
      _b(5),
    ];

void main() {
  late List<int>? order;
  late Map<int, int>? indents;

  Future<void> pumpView(WidgetTester tester, List<NoteBlock> blocks) async {
    order = null;
    indents = null;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NoteArrangeView(
          blocks: blocks,
          tileBuilder: (b, hidden, highlighted) => SizedBox(
            height: 56,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('t${b.id}'),
            ),
          ),
          onApply: (o, i) {
            order = o;
            indents = i;
          },
          onEnterBed: (_) {},
        ),
      ),
    ));
  }

  /// Long-press row [fromId], drag to [to], optionally holding there for
  /// [hold] (long enough to enter a bed), then release.
  Future<void> dragRow(
    WidgetTester tester, {
    required int fromId,
    required Offset to,
    Duration hold = Duration.zero,
  }) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text('t$fromId')));
    await tester.pump(const Duration(milliseconds: 600)); // long-press fires
    await gesture.moveTo(to);
    await tester.pump();
    if (hold > Duration.zero) {
      await gesture.moveTo(to + const Offset(0, 1)); // tiny jiggle, stays put
      await tester.pump(hold);
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dragging a line below the last bed takes it OUT (top level)',
      (tester) async {
    await pumpView(tester, _note());
    final Offset belowLast = tester.getCenter(find.text('t5')) + const Offset(0, 40);

    await dragRow(tester, fromId: 2, to: belowLast);

    expect(order, [1, 3, 4, 5, 2]);
    expect(indents?[2], 0, reason: 'it left Bed 1');
  });

  testWidgets('a plain drop into another bed does not split it', (tester) async {
    await pumpView(tester, _note());
    // Aim at Bed 2's line without holding over the header.
    final Offset intoBed2 = tester.getCenter(find.text('t4'));

    await dragRow(tester, fromId: 5, to: intoBed2);

    // Lands after Bed 2 rather than inside it, and Bed 2 stays whole.
    expect(order, [1, 2, 3, 4, 5]);
    expect(indents?[5], 0);
  });

  testWidgets('holding over a header enters that bed and nests inside',
      (tester) async {
    await pumpView(tester, _note());
    final Offset onBed2Header = tester.getCenter(find.text('t3'));

    await dragRow(
      tester,
      fromId: 5,
      to: onBed2Header,
      hold: const Duration(milliseconds: 700),
    );

    expect(order, [1, 2, 3, 5, 4]);
    expect(indents?[5], 1, reason: 'nested inside Bed 2');
  });

  testWidgets('dragging a heading carries its whole bed', (tester) async {
    await pumpView(tester, _note());
    final Offset top = tester.getCenter(find.text('t1')) - const Offset(0, 40);

    await dragRow(tester, fromId: 3, to: top);

    expect(order, [3, 4, 1, 2, 5]);
    expect(indents?[4], 1, reason: 'its line came along, still nested');
  });
}
