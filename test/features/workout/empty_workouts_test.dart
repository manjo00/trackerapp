import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:life_tracker/features/workout/data/dao/workout_dao.dart';
import 'package:life_tracker/features/workout/data/models/workout_session_model.dart';
import 'package:life_tracker/features/workout/data/repositories/workout_repository.dart';
import 'package:life_tracker/features/workout/presentation/providers/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A workout with nothing logged isn't a workout: Discard removes it, and the
/// history, Recent Sessions and the week's count leave out the ones already
/// saved (their rows stay in the database). A discarded workout with logged
/// sets stays, because those sets are real training.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WorkoutDao dao;
  late WorkoutRepository repo;
  late ProviderContainer container;
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  ActiveWorkout workout() => container.read(activeWorkoutProvider.notifier);

  Future<List<int>> savedWorkoutIds() async => [
        for (final WorkoutSession s in await db.select(db.workoutSessions).get())
          s.id,
      ];

  /// Saves a workout dated today with one set per entry (filled in or not),
  /// as a workout left behind would be, and returns its id.
  Future<int> savedWorkout(String name, List<bool> filledSets) async {
    final int id = await dao.insertSession(WorkoutSessionsCompanion.insert(
      name: Value(name),
      date: today,
      createdAt: DateTime.now(),
    ));
    for (int i = 0; i < filledSets.length; i++) {
      await dao.insertSet(WorkoutSetsCompanion.insert(
        sessionId: id,
        exerciseName: 'Row',
        setNumber: i + 1,
        reps: Value(filledSets[i] ? 8 : null),
        weightKg: Value(filledSets[i] ? 40.0 : null),
      ));
    }
    return id;
  }

  List<int> idsOf(List<WorkoutSessionModel> sessions) =>
      [for (final WorkoutSessionModel s in sessions) s.id];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = WorkoutDao(db);
    repo = WorkoutRepository(dao);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      workoutRepositoryProvider.overrideWithValue(repo),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('discarding a workout with nothing logged removes it', () async {
    await workout().start();
    await workout().ensureTargetSets('Row', 3); // opened, never filled in
    await workout().discard();
    expect(await savedWorkoutIds(), isEmpty);
  });

  test('discarding a workout with logged sets keeps it', () async {
    await workout().start();
    await workout().addSet(exerciseName: 'Row', reps: 8, weightKg: 40);
    await workout().discard();
    expect(await savedWorkoutIds(), hasLength(1));
  });

  group('workouts with nothing logged are left out', () {
    late int logged;

    setUp(() async {
      logged = await savedWorkout('Push', [true, false]);
      await savedWorkout('Started, no sets', []);
      await savedWorkout('Opened, never filled in', [false, false]);
    });

    test('of the history and Recent Sessions', () async {
      expect(idsOf(await repo.watchAllSessions().first), [logged]);
    });

    test('of the stats', () async {
      expect(idsOf(await repo.getAllSessions()), [logged]);
    });

    test("of the week's count", () async {
      container.listen(sessionsThisWeekProvider, (_, __) {});
      expect(await container.read(sessionsThisWeekProvider.future), 1);
    });

    test('but stay in the database', () async {
      expect(await savedWorkoutIds(), hasLength(3));
    });
  });
}
