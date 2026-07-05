import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/program_session_model.dart';
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
