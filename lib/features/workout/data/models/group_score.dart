import 'muscle_groups.dart';

/// One muscle's weekly progress for the scoreboard: how many sessions trained
/// it (directly) and how many direct sets were logged, vs the targets.
///
/// "Direct" = the muscle was the exercise's *primary* mover, so assistance work
/// (e.g. triceps on a bench press) never inflates a muscle's numbers — you
/// can't be fooled into thinking a muscle is covered when it wasn't.
class MuscleScore {
  const MuscleScore({
    required this.muscleKey,
    required this.sessionsDone,
    required this.setsDone,
    required this.frequencyTarget,
    required this.setsTarget,
  });

  final String muscleKey;
  final int sessionsDone;
  final int setsDone;
  final int frequencyTarget;
  final int setsTarget;

  /// The muscle's display label (the key itself, e.g. "Triceps").
  String get label => muscleKey;

  /// The group this muscle is shown under (push/pull/…), for section headers.
  String get group => MuscleGroup.forMuscle(muscleKey) ?? MuscleGroup.core;

  bool get frequencyMet => sessionsDone >= frequencyTarget;
  bool get setsMet => setsDone >= setsTarget;
  bool get fullyMet => frequencyMet && setsMet;

  double get setsProgress =>
      setsTarget == 0 ? 1 : (setsDone / setsTarget).clamp(0, 1);
}
