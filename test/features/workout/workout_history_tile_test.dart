import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/workout/presentation/widgets/workout_history_tile.dart';

import 'workout_history_test_data.dart';

/// A history row in look B: the kilos lifted big, then the name and date, the
/// sets and records, and the change since the last workout of the same plan.
void main() {
  Future<void> pumpTile(WidgetTester tester,
      {bool withPrevious = true, VoidCallback? onTap}) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WorkoutHistoryTile(
          session: pushToday,
          previous: withPrevious ? pushBefore : null,
          onTap: onTap,
        ),
      ),
    ));
  }

  testWidgets('shows the kilos big, then name, date, sets and records',
      (tester) async {
    await pumpTile(tester);
    expect(find.text('1.9 t'), findsOneWidget);
    expect(find.text('lifted'), findsOneWidget);
    expect(find.text('Push · Tue, 3 Nov'), findsOneWidget);
    expect(find.text('4 sets · 2 records'), findsOneWidget);
  });

  testWidgets('says how the kilos compare with the last workout of its plan',
      (tester) async {
    await pumpTile(tester);
    expect(find.text('50% more than last time'), findsOneWidget);
  });

  testWidgets('the first workout of a plan has no comparison', (tester) async {
    await pumpTile(tester, withPrevious: false);
    expect(find.textContaining('than last time'), findsNothing);
  });

  testWidgets('tapping it opens the workout', (tester) async {
    int taps = 0;
    await pumpTile(tester, onTap: () => taps++);
    await tester.tap(find.text('Push · Tue, 3 Nov'));
    expect(taps, 1);
  });
}
