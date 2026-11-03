import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/workout/data/dao/workout_dao.dart';
import 'package:life_tracker/features/workout/data/models/workout_set_model.dart';
import 'package:life_tracker/features/workout/data/repositories/workout_repository.dart';
import 'package:life_tracker/features/workout/presentation/providers/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ticking a set saves when it was done (the smart order and the history read
/// it); ticking it again clears that time. Finishing a workout saves when.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  ActiveWorkout workout() => container.read(activeWorkoutProvider.notifier);

  int sessionId() =>
      container.read(activeWorkoutProvider).valueOrNull?.sessionId ??
      fail('no active workout');

  /// Adds a filled-in set to the running workout and returns its id.
  Future<int> loggedSet(String name) async {
    final WorkoutSetModel? set =
        await workout().addSet(exerciseName: name, reps: 10, weightKg: 60);
    return set?.id ?? fail('no active workout');
  }

  Future<WorkoutSet> setRow(int id) =>
      (db.select(db.workoutSets)..where((s) => s.id.equals(id))).getSingle();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      workoutRepositoryProvider
          .overrideWithValue(WorkoutRepository(WorkoutDao(db))),
    ]);
    await workout().start();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('a tick saves the time it was tapped', () async {
    final int id = await loggedSet('Leg Press');
    final DateTime tapped = DateTime.now();
    expect(await workout().toggleSetComplete(id), isTrue);
    // Saved to the second.
    expect((await setRow(id)).completedAt?.difference(tapped).inSeconds.abs(),
        lessThanOrEqualTo(1));
  });

  test('tapping the tick again clears its time', () async {
    final int id = await loggedSet('Leg Press');
    await workout().toggleSetComplete(id);
    expect((await setRow(id)).completedAt, isNotNull);
    expect(await workout().toggleSetComplete(id), isFalse);
    expect((await setRow(id)).completedAt, isNull);
    expect(container.read(activeWorkoutProvider).valueOrNull?.isCompleted(id),
        isFalse);
  });

  test('finishing a workout saves when', () async {
    final int session = sessionId();
    await loggedSet('Leg Press');
    final DateTime tapped = DateTime.now();
    await workout().finish(name: 'Push');
    final WorkoutSession row = await (db.select(db.workoutSessions)
          ..where((s) => s.id.equals(session)))
        .getSingle();
    expect(row.finishedAt?.difference(tapped).inSeconds.abs(),
        lessThanOrEqualTo(1));
  });
}
