import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/workout/data/dao/workout_dao.dart';
import 'package:life_tracker/features/workout/data/models/program_exercise_model.dart';
import 'package:life_tracker/features/workout/data/repositories/workout_repository.dart';
import 'package:life_tracker/features/workout/presentation/providers/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starting a planned workout uses the smart order only when that workout's
/// switch is on; every Start button goes through ActiveWorkout.start.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;
  late int fullBody;
  const List<String> planned = ['A', 'B', 'C', 'D', 'E', 'F'];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final WorkoutDao dao = WorkoutDao(db);
    container = ProviderContainer(overrides: [
      workoutRepositoryProvider.overrideWithValue(WorkoutRepository(dao)),
    ]);
    final int program = await db.into(db.programs).insert(
        ProgramsCompanion.insert(name: 'Mine', createdAt: DateTime(2026, 10)));
    fullBody = await db.into(db.programSessions).insert(
        ProgramSessionsCompanion.insert(programId: program, name: 'Full body'));

    // One earlier workout in the plan's order: with six exercises, A and B
    // had the early slots.
    final int earlier = await dao.insertSession(WorkoutSessionsCompanion.insert(
      date: '2026-10-30',
      createdAt: DateTime(2026, 10, 30),
      programSessionId: Value(fullBody),
    ));
    for (final String name in planned) {
      await dao.insertSet(WorkoutSetsCompanion.insert(
        sessionId: earlier,
        exerciseName: name,
        setNumber: 1,
        reps: const Value(8),
        weightKg: const Value(40),
      ));
    }
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<ActiveWorkoutState> start() async {
    await container.read(activeWorkoutProvider.notifier).start(
          programSessionId: fullBody,
          programSessionName: 'Full body',
          programExercises: [
            for (int i = 0; i < planned.length; i++)
              ProgramExerciseModel(
                id: i + 1,
                programSessionId: fullBody,
                exerciseName: planned[i],
                orderIndex: i,
              ),
          ],
        );
    return container.read(activeWorkoutProvider).valueOrNull!;
  }

  List<String> namesOf(ActiveWorkoutState state) =>
      [for (final ProgramExerciseModel e in state.programExercises) e.exerciseName];

  test('with the switch off, the plan order stays', () async {
    final ActiveWorkoutState state = await start();
    expect(namesOf(state), planned);
    expect(state.smartOrder, isNull);
  });

  test('with the switch on, the exercises come in the smart order', () async {
    await container.read(smartOrderEnabledProvider(fullBody).notifier).set(true);
    final ActiveWorkoutState state = await start();
    expect(namesOf(state), ['F', 'E', 'D', 'C', 'B', 'A']);
    expect(state.smartOrder?.movedUp, ['F', 'E']);
  });

  test('the switch is remembered for that workout only', () async {
    await container.read(smartOrderEnabledProvider(fullBody).notifier).set(true);
    expect(await SmartOrderEnabled.isOn(fullBody), isTrue);
    expect(await SmartOrderEnabled.isOn(fullBody + 1), isFalse);
  });
}
