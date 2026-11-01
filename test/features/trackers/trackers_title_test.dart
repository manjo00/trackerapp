import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/trackers/presentation/providers/trackers_providers.dart';
import 'package:life_tracker/features/trackers/presentation/screens/trackers_screen.dart';

/// Trackers is a tab inside the app's shell, which already shows the tab's
/// title in its own top bar, like Habits, Lists and Planner.
///
/// Regression (2026-11-01, Tester chat, from the looks seat): the Trackers
/// tab drew a second "Trackers" bar under the shell's, wasting about 56 dp.
void main() {
  testWidgets('the Trackers tab draws no title bar of its own', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        trackersWithProgressProvider
            .overrideWith((ref) => Stream.value(const [])),
      ],
      child: const MaterialApp(home: TrackersScreen()),
    ));
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('New tracker'), findsOneWidget,
        reason: 'the add button stays');
  });
}
