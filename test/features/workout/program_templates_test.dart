import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/workout/data/dao/program_dao.dart';
import 'package:life_tracker/features/workout/data/models/program_model.dart';
import 'package:life_tracker/features/workout/data/dao/workout_dao.dart';
import 'package:life_tracker/features/workout/data/repositories/program_repository.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProgramRepository(ProgramDao(db), WorkoutDao(db));
  });
  tearDown(() async => db.close());

  /// Builds a two-day program with one exercise slot on each day.
  Future<int> buildProgram() async {
    final int id =
        await repo.createProgram(name: 'My Split', splitType: 'rotating');
    final int push =
        await repo.addSession(programId: id, name: 'Push', orderIndex: 0);
    await repo.addExercise(
        programSessionId: push,
        exerciseName: 'Bench Press',
        targetSets: 4,
        targetReps: 8,
        restSeconds: 180,
        orderIndex: 0);
    final int pull =
        await repo.addSession(programId: id, name: 'Pull', orderIndex: 1);
    await repo.addExercise(
        programSessionId: pull,
        exerciseName: 'Barbell Row',
        targetSets: 3,
        targetReps: 10,
        restSeconds: 120,
        orderIndex: 0);
    return id;
  }

  test('a saved template is hidden from the program list', () async {
    final int id = await buildProgram();
    await repo.saveAsTemplate(id, name: 'My Split TPL');

    final programs = await repo.watchAllPrograms().first;
    expect(programs.map((p) => p.name), ['My Split']);

    final templates = await repo.watchProgramTemplates().first;
    expect(templates.map((p) => p.name), ['My Split TPL']);
  });

  test('saving copies every day and exercise slot', () async {
    final int id = await buildProgram();
    await repo.saveAsTemplate(id);

    final tpl = (await repo.watchProgramTemplates().first).single;
    expect(tpl.sessions.map((s) => s.name), ['Push', 'Pull']);
    expect(tpl.sessions.first.exercises.single.exerciseName, 'Bench Press');
    expect(tpl.sessions.first.exercises.single.targetSets, 4);
    expect(tpl.sessions.last.exercises.single.exerciseName, 'Barbell Row');
  });

  test('using a template creates a real, active program', () async {
    final int id = await buildProgram();
    await repo.saveAsTemplate(id, name: 'Reusable');
    final tpl = (await repo.watchProgramTemplates().first).single;

    final created = await repo.createFromUserTemplate(tpl.id);
    expect(created, isNotNull);
    expect(created!.name, 'Reusable');
    expect(created.isActive, isTrue);
    expect(created.sessions.map((s) => s.name), ['Push', 'Pull']);
    expect(created.sessions.first.exercises.single.restSeconds, 180);

    // The template itself stays a template, and the new program is listed.
    expect((await repo.watchProgramTemplates().first).length, 1);
    final names = (await repo.watchAllPrograms().first).map((p) => p.name);
    expect(names, containsAll(['My Split', 'Reusable']));
  });

  test('editing the program afterwards leaves the template untouched',
      () async {
    final int id = await buildProgram();
    await repo.saveAsTemplate(id, name: 'Snapshot');

    await repo.updateProgram(id: id, name: 'Renamed Split');
    final tpl = (await repo.watchProgramTemplates().first).single;
    expect(tpl.name, 'Snapshot');
  });

  group('my workouts (single-workout templates)', () {
    test('created workouts appear on the shelf with their exercises',
        () async {
      final (_, int sid) = await repo.createMyWorkout('Chest & arms');
      await repo.addExercise(
          programSessionId: sid,
          exerciseName: 'Bench Press',
          targetSets: 4,
          targetReps: 8,
          restSeconds: 180);

      final shelf = await repo.watchMyWorkouts().first;
      expect(shelf.single.name, 'Chest & arms');
      expect(shelf.single.exercises.single.exerciseName, 'Bench Press');
    });

    test('the container is invisible everywhere else', () async {
      await repo.createMyWorkout('Quick pump');
      expect(await repo.watchAllPrograms().first, isEmpty);
      expect(await repo.watchProgramTemplates().first, isEmpty);
    });

    test('the container is created exactly once', () async {
      final int a = await repo.ensureMyWorkoutsContainer();
      await repo.createMyWorkout('One');
      final int b = await repo.ensureMyWorkoutsContainer();
      expect(a, b);
      expect((await repo.watchMyWorkouts().first).length, 1);
    });

    test('the session editor can resolve a My-workouts session', () async {
      // Regression: the editor used to look the program up in the program
      // LIST, which hides templates — so a custom workout read as "Session
      // not found" and exercises could not be added.
      final (int pid, int sid) = await repo.createMyWorkout('Chest & arms');

      final ProgramModel? program = await repo.watchProgramById(pid).first;
      expect(program, isNotNull, reason: 'container must be findable by id');
      expect(program!.sessions.where((s) => s.id == sid), hasLength(1));

      await repo.addExercise(
          programSessionId: sid, exerciseName: 'Incline Press');
      final ProgramModel? after = await repo.watchProgramById(pid).first;
      expect(after!.sessions.single.exercises.single.exerciseName,
          'Incline Press');
    });

    test('deleting a workout leaves the others', () async {
      final (_, int sid) = await repo.createMyWorkout('Push');
      await repo.createMyWorkout('Pull');
      await repo.deleteSession(sid);
      final shelf = await repo.watchMyWorkouts().first;
      expect(shelf.map((w) => w.name), ['Pull']);
    });
  });
}
