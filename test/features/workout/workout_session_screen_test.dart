import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/workout/data/models/workout_session_model.dart';
import 'package:life_tracker/features/workout/presentation/providers/workout_providers.dart';
import 'package:life_tracker/features/workout/presentation/screens/workout_session_screen.dart';

import 'workout_history_test_data.dart';

/// The workout page in look B: the kilos lifted as the headline and their
/// change since the last workout of the same plan, then every exercise in the
/// order it was done, with its sets and how its best set changed.
void main() {
  Future<void> pumpPage(WidgetTester tester, int id,
      {List<WorkoutSessionModel>? history}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        allWorkoutSessionsProvider.overrideWith(
            (ref) => Stream.value(history ?? [pushToday, pushBefore])),
      ],
      child: MaterialApp(home: WorkoutSessionScreen(sessionId: id)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the headline is the kilos lifted, then when and how long',
      (tester) async {
    await pumpPage(tester, 77);
    expect(find.text('1,910 kg'), findsOneWidget);
    expect(find.text('lifted · Tue, 3 Nov · started 12:49 · 52 min'),
        findsOneWidget);
    expect(find.text('4 sets · 2 records'), findsOneWidget);
  });

  testWidgets('it compares the kilos with the last workout of the plan',
      (tester) async {
    await pumpPage(tester, 77);
    expect(find.text('+635 kg vs last Push'), findsOneWidget);
  });

  testWidgets('exercises come in the order done, each with its change',
      (tester) async {
    await pumpPage(tester, 77);
    final double legPress = tester.getTopLeft(find.text('Leg Press')).dy;
    final double legCurl = tester.getTopLeft(find.text('Leg Curl')).dy;
    final double row = tester.getTopLeft(find.text('Row')).dy;
    expect(legPress < legCurl && legCurl < row, isTrue);
    expect(find.text('+5 kg'), findsOneWidget);
    expect(find.text('+5 kg, 2 fewer reps'), findsOneWidget);
    expect(find.text('+2 reps'), findsOneWidget);
  });

  testWidgets('each change sits at the right edge', (tester) async {
    await pumpPage(tester, 77);
    final double width = tester.getSize(find.byType(Scaffold)).width;
    expect(tester.getTopRight(find.text('+5 kg')).dx, closeTo(width - 16, 1));
  });

  testWidgets('every set shows, records marked, with the first tick time',
      (tester) async {
    await pumpPage(tester, 77);
    expect(find.text('70 × 8'), findsOneWidget);
    expect(find.text('80 × 8'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNWidgets(2));
    expect(find.text('12:55'), findsOneWidget);
  });

  testWidgets('the first workout of a plan has nothing to compare',
      (tester) async {
    await pumpPage(tester, 71);
    expect(find.textContaining('vs last'), findsNothing);
    expect(find.text('+2 reps'), findsNothing);
  });

  testWidgets('a workout that is gone says so', (tester) async {
    await pumpPage(tester, 999);
    expect(find.text('This workout is no longer in your history.'),
        findsOneWidget);
  });
}
