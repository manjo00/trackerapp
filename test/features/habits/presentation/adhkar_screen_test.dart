import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/data/adhkar_store.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/adhkar_progress.dart';
import 'package:life_tracker/features/habits/domain/dhikr.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/adhkar_haptics.dart';
import 'package:life_tracker/features/habits/presentation/providers/adhkar_providers.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';
import 'package:life_tracker/features/habits/presentation/screens/adhkar_screen.dart';

import 'habit_widget_helpers.dart';

/// Hands the counter its starting counts and records every save.
class FakeAdhkarActions implements AdhkarActions {
  FakeAdhkarActions(this.start);

  final AdhkarProgress start;

  /// "<day> <finished before>-><finished after>" per save.
  final List<String> saves = [];
  AdhkarProgress? last;

  @override
  Future<AdhkarProgress> open(HabitModel habit, String day) async => start;

  @override
  AdhkarProgress load(int habitId, String day, List<Dhikr> items) => start;

  @override
  Future<void> save(HabitModel habit, String day, AdhkarProgress before,
      AdhkarProgress after) async {
    saves.add('$day ${before.finished}->${after.finished}');
    last = after;
  }
}

class FakeHaptics implements AdhkarHaptics {
  final List<String> calls = [];

  @override
  Future<void> tick() async => calls.add('tick');

  @override
  Future<void> finished() async => calls.add('finished');
}

HabitModel _habit(AdhkarList list) => HabitModel(
      id: 7,
      name: list == AdhkarList.morning ? "Morning du'as" : "Night du'as",
      createdAt: DateTime(2026, 11, 1, 9),
      kind: HabitKind.count,
      goal: list.items.length,
      unit: "du'as",
      autoSource: list.source,
    );

Future<(FakeAdhkarActions, FakeHaptics)> _pumpCounter(WidgetTester tester,
    {AdhkarList list = AdhkarList.morning, AdhkarProgress? start}) async {
  final FakeAdhkarActions actions =
      FakeAdhkarActions(start ?? AdhkarProgress.empty(list.items));
  final FakeHaptics haptics = FakeHaptics();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      adhkarActionsProvider.overrideWithValue(actions),
      adhkarHapticsProvider.overrideWithValue(haptics),
      habitTodayProvider.overrideWith(FixedToday.new),
    ],
    child: MaterialApp(home: AdhkarScreen(habit: _habit(list))),
  ));
  await tester.pumpAndSettle();
  return (actions, haptics);
}

Finder _count(String text) => find.text(text, findRichText: true);

Future<void> _tapToCount(WidgetTester tester) async {
  await tester.tap(find.byKey(AdhkarScreen.tapArea));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300)); // the pop-up's entry
}

void main() {
  final List<Dhikr> morning = AdhkarList.morning.items;

  testWidgets('opens on the first du\'a not done yet, with its count',
      (WidgetTester tester) async {
    await _pumpCounter(tester,
        start: AdhkarProgress.empty(morning).tapped(0)); // Ayat al-Kursi done
    expect(find.text('سورة الإخلاص'), findsOneWidget);
    expect(find.text(morning[1].text), findsOneWidget); // the whole surah
    expect(_count('0 / 3'), findsOneWidget);
    expect(find.text("Du'a 2 of 21"), findsOneWidget);
    expect(find.text('1 of 21 done'), findsOneWidget);
  });

  testWidgets('a tap anywhere counts one, with a light tick, and is saved',
      (WidgetTester tester) async {
    final (FakeAdhkarActions actions, FakeHaptics haptics) =
        await _pumpCounter(tester,
            start: AdhkarProgress.empty(morning).tapped(0));
    await _tapToCount(tester);
    expect(_count('1 / 3'), findsOneWidget);
    expect(haptics.calls, ['tick']);
    expect(actions.saves, ['2026-11-04 1->1']);
  });

  testWidgets(
      'reaching the count buzzes and shows the pop-up; taps then count nothing',
      (WidgetTester tester) async {
    final (FakeAdhkarActions actions, FakeHaptics haptics) =
        await _pumpCounter(tester);
    await _tapToCount(tester); // Ayat al-Kursi, once
    expect(haptics.calls, ['tick', 'finished']);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('سورة الإخلاص'), findsOneWidget, reason: 'the next one');
    expect(actions.saves, ['2026-11-04 0->1']);

    await tester.tapAt(const Offset(30, 400)); // a blind tap, off the pop-up
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    expect(actions.saves, hasLength(1));
  });

  testWidgets('the pop-up\'s button wakes after 0.8 s and opens the next du\'a',
      (WidgetTester tester) async {
    await _pumpCounter(tester);
    await _tapToCount(tester);
    await tester.tap(find.text("Next du'a"));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget, reason: 'too soon: ignored');

    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text("Next du'a"));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    expect(find.text("Du'a 2 of 21"), findsOneWidget);
    expect(_count('0 / 3'), findsOneWidget);
  });

  testWidgets('the last du\'a of the night finishes the list',
      (WidgetTester tester) async {
    final List<Dhikr> night = AdhkarList.night.items;
    final (FakeAdhkarActions actions, _) = await _pumpCounter(tester,
        list: AdhkarList.night,
        start: AdhkarProgress.empty(night).allDone().untapped(night.length - 1));
    expect(_count('99 / 100'), findsOneWidget);
    await _tapToCount(tester);
    expect(find.text('All done'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(actions.saves, ['2026-11-04 18->19']);
    expect(actions.last!.complete, isTrue);
  });

  testWidgets('−1 takes a mistaken tap back', (WidgetTester tester) async {
    final (FakeAdhkarActions actions, _) = await _pumpCounter(tester,
        start: AdhkarProgress.empty(morning).tapped(0).tapped(1).tapped(1));
    expect(_count('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Take one back'));
    await tester.pump();
    expect(_count('1 / 3'), findsOneWidget);
    expect(actions.saves, ['2026-11-04 1->1']);
  });

  testWidgets('the arrows move between du\'as without counting',
      (WidgetTester tester) async {
    final (FakeAdhkarActions actions, _) = await _pumpCounter(tester);
    await tester.tap(find.byTooltip("Next du'a"));
    await tester.pump();
    expect(find.text("Du'a 2 of 21"), findsOneWidget);
    await tester.tap(find.byTooltip("Previous du'a"));
    await tester.pump();
    expect(find.text("Du'a 1 of 21"), findsOneWidget);
    expect(actions.saves, isEmpty);
  });

  testWidgets('the list of all du\'as jumps to the one picked',
      (WidgetTester tester) async {
    await _pumpCounter(tester);
    await tester.tap(find.byTooltip("All du'as"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(morning[2].title)); // سورة الفلق
    await tester.pumpAndSettle();
    expect(find.text("Du'a 3 of 21"), findsOneWidget);
    expect(find.text(morning[2].text), findsOneWidget);
  });

  testWidgets('start again asks first, then clears today\'s counts',
      (WidgetTester tester) async {
    final (FakeAdhkarActions actions, _) = await _pumpCounter(tester,
        start: AdhkarProgress.empty(morning).tapped(0).tapped(1));
    await tester.tap(find.byTooltip('Start again'));
    await tester.pumpAndSettle();
    expect(find.text('Start this list again?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Start again'));
    await tester.pumpAndSettle();
    expect(actions.saves, ['2026-11-04 1->0']);
    expect(find.text("Du'a 1 of 21"), findsOneWidget);
    expect(_count('0 / 1'), findsOneWidget);
  });
}
