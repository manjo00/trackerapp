import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/tasks/presentation/providers/lists_providers.dart';
import 'package:life_tracker/features/tasks/presentation/screens/quick_add_task_screen.dart';

/// The home-screen widget's quick-add sheet must sit on the keyboard, with the
/// home screen still showing above it.
///
/// Regression (2026-11-01, Tester chat): with the keyboard up the sheet
/// stretched to the top of the screen, because the keyboard's height was added
/// twice (the Scaffold already lifts its body above the keyboard, and the sheet
/// padded itself by the same height again).
void main() {
  testWidgets('opening the keyboard lifts the sheet by its height, not twice',
      (tester) async {
    // A Flip-sized screen: 1080 x 2640 pixels at 2.625 = 411 x 1006.
    tester.view.physicalSize = const Size(1080, 2640);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [taskListsProvider.overrideWith((ref) => Stream.value(const []))],
      child: const MaterialApp(home: QuickAddTaskScreen()),
    ));
    await tester.pump();
    final Finder send = find.byIcon(Icons.arrow_upward_rounded);
    final double bottomWithoutKeyboard = tester.getBottomLeft(send).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2.625);
    await tester.pump();
    final double bottomWithKeyboard = tester.getBottomLeft(send).dy;

    expect(bottomWithoutKeyboard - bottomWithKeyboard, closeTo(300, 1));
  });
}
