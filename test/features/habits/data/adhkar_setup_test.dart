import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/habits/data/adhkar_setup.dart';
import 'package:life_tracker/features/habits/data/adhkar_store.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/data/repositories/habits_repository.dart';
import 'package:life_tracker/features/habits/domain/adhkar_progress.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late HabitsRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HabitsRepository(HabitsDao(db));
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  Future<List<HabitModel>> active() => repo.watchActiveHabits().first;

  HabitModel byList(List<HabitModel> habits, AdhkarList list) =>
      habits.singleWhere((HabitModel h) => h.autoSource == list.source);

  group('adding the two du\'a habits', () {
    test('the first start adds Morning and Night du\'as as count habits',
        () async {
      await ensureAdhkarHabits(repo, prefs, now: DateTime(2026, 11, 13, 20));
      final List<HabitModel> habits = await active();
      expect(habits, hasLength(2));

      final HabitModel m = byList(habits, AdhkarList.morning);
      expect(m.name, "Morning du'as");
      expect(m.kind, HabitKind.count);
      expect(m.goal, 21);
      expect(m.unit, "du'as");
      expect(m.step, 1);
      expect(m.section, HabitSection.wake);
      expect(m.icon, 'wb_sunny');
      expect(m.schedule, HabitSchedule.daily);
      expect(m.sparesPerWeek, 1);
      expect(m.createdAt, DateTime(2026, 11, 13, 20));

      final HabitModel n = byList(habits, AdhkarList.night);
      expect(n.name, "Night du'as");
      expect(n.goal, 19);
      expect(n.section, HabitSection.sleep);
      expect(n.icon, 'bedtime');
    });

    test('later starts add nothing more', () async {
      await ensureAdhkarHabits(repo, prefs);
      await ensureAdhkarHabits(repo, prefs);
      expect(await active(), hasLength(2));
    });

    test('a du\'a habit he deleted never comes back', () async {
      await ensureAdhkarHabits(repo, prefs);
      await repo.deleteHabit(byList(await active(), AdhkarList.night).id);
      await ensureAdhkarHabits(repo, prefs);
      final List<HabitModel> habits = await active();
      expect(habits, hasLength(1));
      expect(habits.single.autoSource, AdhkarList.morning.source);
    });

    test('a goal that no longer matches its list is put right', () async {
      await ensureAdhkarHabits(repo, prefs);
      final HabitModel m = byList(await active(), AdhkarList.morning);
      await repo.saveHabit(m.copyWith(goal: 20));
      await ensureAdhkarHabits(repo, prefs);
      expect(byList(await active(), AdhkarList.morning).goal, 21);
    });
  });

  group('today\'s counts', () {
    test('saved counts come back for the same day, and a new day starts at 0',
        () async {
      final AdhkarStore store = AdhkarStore(prefs);
      final AdhkarProgress p =
          AdhkarProgress.empty(AdhkarList.morning.items).tapped(1).tapped(1);
      await store.save(7, '2026-11-13', p);
      expect(store.load(7, '2026-11-13', AdhkarList.morning.items).countOf(1),
          2);
      expect(store.load(7, '2026-11-14', AdhkarList.morning.items).finished,
          0);
      expect(store.load(8, '2026-11-13', AdhkarList.morning.items).finished,
          0);
    });

    test('a damaged save reads as nothing counted', () async {
      await prefs.setString('adhkar_counts_7', '{not json');
      expect(
          AdhkarStore(prefs)
              .load(7, '2026-11-13', AdhkarList.morning.items)
              .finished,
          0);
    });

    test('the habit\'s day value follows the number of finished du\'as',
        () async {
      await ensureAdhkarHabits(repo, prefs);
      final HabitModel m = byList(await active(), AdhkarList.morning);
      final AdhkarActions actions = AdhkarActions(repo, AdhkarStore(prefs));
      const String day = '2026-11-13';
      Future<int?> value() async =>
          (await repo.watchHistorySince(day).first).of(m.id).entries[day]?.value;

      final AdhkarProgress p0 = AdhkarProgress.empty(AdhkarList.morning.items);
      final AdhkarProgress p1 = p0.tapped(0);
      await actions.save(m, day, p0, p1);
      expect(await value(), 1);

      final AdhkarProgress p2 = p1.tapped(1);
      await actions.save(m, day, p1, p2);
      expect(await value(), 1, reason: 'one of 3 taps finishes nothing new');

      final AdhkarProgress p3 = p2.untapped(0);
      await actions.save(m, day, p2, p3);
      expect(await value(), isNull, reason: '0 finished removes the day');

      final AdhkarProgress all = p3.allDone();
      await actions.save(m, day, p3, all);
      expect(await value(), 21);
      expect(actions.load(m.id, day, AdhkarList.morning.items).complete, isTrue);
    });

    test('opening reads the saved counts, or all done when the day is kept',
        () async {
      await ensureAdhkarHabits(repo, prefs);
      final HabitModel n = byList(await active(), AdhkarList.night);
      final AdhkarActions actions = AdhkarActions(repo, AdhkarStore(prefs));
      const String day = '2026-11-13';
      final AdhkarProgress one =
          AdhkarProgress.empty(AdhkarList.night.items).tapped(0);
      await actions.save(n, day, AdhkarProgress.empty(one.items), one);
      expect((await actions.open(n, day)).finished, 1);

      await repo.setValue(n.id, day, 19); // marked done somewhere else
      expect((await actions.open(n, day)).complete, isTrue);
    });

    test('a habit edited away from a count of its list is put right', () async {
      await ensureAdhkarHabits(repo, prefs);
      final HabitModel n = byList(await active(), AdhkarList.night);
      await repo.saveHabit(n.copyWith(kind: HabitKind.tick, goal: 1));
      await ensureAdhkarHabits(repo, prefs);
      final HabitModel fixed = byList(await active(), AdhkarList.night);
      expect(fixed.kind, HabitKind.count);
      expect(fixed.goal, 19);
    });

    test('a day marked done somewhere else opens with every du\'a done', () {
      final AdhkarProgress saved =
          AdhkarProgress.empty(AdhkarList.night.items).tapped(0);
      expect(saved.shown(dayKept: true).complete, isTrue);
      expect(saved.shown(dayKept: false).finished, 1);
    });
  });
}
