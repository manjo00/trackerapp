import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/database/database_provider.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/habit_rules.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:life_tracker/features/habits/presentation/models/habit_day_view.dart';
import 'package:life_tracker/features/habits/presentation/providers/habits_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DateTime now;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'week_starts_sunday': true});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    now = DateTime(2026, 11, 4, 16, 5);
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      habitClockProvider.overrideWithValue(() => now),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  HabitActions actions() => container.read(habitActionsProvider);

  Future<int> addHabit({HabitKind kind = HabitKind.tick, int goal = 1}) =>
      actions().save(HabitModel(
          id: 0,
          name: 'Test',
          createdAt: DateTime(2026, 11, 1, 9),
          kind: kind,
          goal: goal));

  /// The habit's day view once [ready] holds (the database streams are async).
  Future<HabitDayView> viewOf(int id, bool Function(HabitDayView v) ready) async {
    final ProviderSubscription<AsyncValue<List<HabitDayView>>> keep =
        container.listen(habitDayViewsProvider, (_, __) {});
    try {
      for (int i = 0; i < 100; i++) {
        final List<HabitDayView>? views =
            container.read(habitDayViewsProvider).valueOrNull;
        for (final HabitDayView v in views ?? const <HabitDayView>[]) {
          if (v.habit.id == id && ready(v)) return v;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('the view of habit $id never got there');
    } finally {
      keep.close();
    }
  }

  test('a tick moves today from pending to kept', () async {
    final int id = await addHabit();
    await viewOf(id, (v) => v.summary.today == DayState.pending);
    await actions().tick(id);
    await viewOf(id, (v) => v.summary.today == DayState.kept);
  });

  test('a tick at 01:30 counts for the day before', () async {
    now = DateTime(2026, 11, 5, 1, 30);
    container.invalidate(habitTodayProvider);
    final int id = await addHabit();
    await actions().tick(id);
    final List<HabitCompletion> rows =
        await db.select(db.habitCompletions).get();
    expect(rows.single.date, '2026-11-04');
  });

  test("the Planner's toggle without a date uses the habit day", () async {
    now = DateTime(2026, 11, 5, 1, 30);
    container.invalidate(habitTodayProvider);
    final int id = await addHabit();
    await container.read(toggleCompletionProvider.notifier).toggle(id);
    expect((await db.select(db.habitCompletions).get()).single.date,
        '2026-11-04');
  });

  test('the day flips at 04:00 without a restart', () {
    now = DateTime(2026, 11, 5, 3, 59);
    container.invalidate(habitTodayProvider);
    expect(container.read(habitTodayProvider), '2026-11-04');
    now = DateTime(2026, 11, 5, 4, 1);
    container.invalidate(habitTodayProvider);
    expect(container.read(habitTodayProvider), '2026-11-05');
  });

  test('+ adds the step and turns kept at the goal', () async {
    final int id = await addHabit(kind: HabitKind.count, goal: 8);
    await actions().addAmount(id, 2);
    await viewOf(id,
        (v) => v.summary.today == DayState.partial && v.summary.todayValue == 2);
    expect(await actions().setAmount(id, '2026-11-04', '7'), isTrue);
    await actions().addAmount(id, 1);
    await viewOf(id,
        (v) => v.summary.today == DayState.kept && v.summary.todayValue == 8);
  });

  test('typed amounts', () async {
    final int id = await addHabit(kind: HabitKind.count, goal: 8);
    Future<List<int>> values() async =>
        [for (final r in await db.select(db.habitCompletions).get()) r.value];

    expect(await actions().setAmount(id, '2026-11-04', ''), isFalse);
    expect(await actions().setAmount(id, '2026-11-04', '-2'), isFalse);
    expect(await actions().setAmount(id, '2026-11-04', '100000'), isFalse);
    expect(await values(), isEmpty);
    expect(await actions().setAmount(id, '2026-11-04', '12'), isTrue);
    expect(await values(), [12]);
    // Up to 99,999, so 2,000 ml or 10,000 steps fit.
    expect(await actions().setAmount(id, '2026-11-04', '1000'), isTrue);
    expect(await values(), [1000]);
    expect(await actions().setAmount(id, '2026-11-04', '99999'), isTrue);
    expect(await values(), [99999]);
    expect(await actions().setAmount(id, '2026-11-04', '0'), isTrue);
    expect(await values(), isEmpty);
  });

  test('a tick on a past day saves that day and leaves today alone', () async {
    final int id = await addHabit();
    await actions().tick(id, day: '2026-11-03');
    expect([for (final r in await db.select(db.habitCompletions).get()) r.date],
        ['2026-11-03']);
    final HabitDayView v = await viewOf(id, (v) => v.history.entries.isNotEmpty);
    expect(v.summary.today, DayState.pending);
    expect(
        v.onDay('2026-11-03', today: '2026-11-04', weekStartsSunday: true).state,
        DayState.kept);
    // Ticking it again takes the tick back.
    await actions().tick(id, day: '2026-11-03');
    expect(await db.select(db.habitCompletions).get(), isEmpty);
  });

  test('+ on a past day adds to that day', () async {
    final int id = await addHabit(kind: HabitKind.count, goal: 8);
    await actions().addAmount(id, 3, day: '2026-11-02');
    final List<HabitCompletion> rows =
        await db.select(db.habitCompletions).get();
    expect((rows.single.date, rows.single.value), ('2026-11-02', 3));
  });
}
