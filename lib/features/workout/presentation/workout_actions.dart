import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/exercise_model.dart';
import '../data/models/program_exercise_model.dart';
import '../data/models/program_session_model.dart';
import '../data/models/quick_start_templates.dart';
import 'providers/workout_providers.dart';

/// Starts a workout for [session] (or a blank custom session when null) and
/// opens the active-workout screen. Resumes instead if one is already
/// running. Shared by the Workout home Train button and the Home
/// dashboard's workout block.
Future<void> startProgramSession(
  BuildContext context,
  WidgetRef ref, {
  ProgramSessionModel? session,
}) async {
  // If already active, just resume.
  final active = ref.read(activeWorkoutProvider).valueOrNull;
  if (active != null) {
    context.push('/workout/active');
    return;
  }
  await ref.read(activeWorkoutProvider.notifier).start(
        programSessionId: session?.id,
        programExercises: session?.exercises ?? [],
        programSessionName: session?.name,
      );
  if (context.mounted) context.push('/workout/active');
}

/// Starts an ad-hoc session from a quick-start template: looks up each
/// exercise in the library and pre-loads them (no program link). Resumes
/// instead if a workout is already running. Shared by the Workout home
/// quick-start row and the Home dashboard's workout block (Targets mode).
Future<void> startQuickTemplate(
  BuildContext context,
  WidgetRef ref,
  QuickStartTemplate template,
) async {
  final active = ref.read(activeWorkoutProvider).valueOrNull;
  if (active != null) {
    context.push('/workout/active');
    return;
  }

  final List<ExerciseModel> library =
      await ref.read(workoutRepositoryProvider).getAllExercises();
  final Map<String, ExerciseModel> byName = {
    for (final ExerciseModel e in library) e.name: e,
  };

  final List<ProgramExerciseModel> planned = [];
  int order = 0;
  for (final String name in template.exercises) {
    final ExerciseModel? ex = byName[name];
    if (ex == null) continue; // skip anything not in the library
    planned.add(ProgramExerciseModel(
      id: -1 - order, // synthetic (no DB row); negative to avoid clashes
      programSessionId: -1,
      exerciseId: ex.id,
      exerciseName: ex.name,
      orderIndex: order,
    ));
    order++;
  }

  await ref.read(activeWorkoutProvider.notifier).start(
        programExercises: planned,
        programSessionName: template.name,
      );
  if (context.mounted) context.push('/workout/active');
}
