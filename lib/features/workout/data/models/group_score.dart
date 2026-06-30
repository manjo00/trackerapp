import 'muscle_groups.dart';

/// One muscle group's weekly progress for the scoreboard: how many sessions hit
/// it and how many sets were logged, vs the targets.
class GroupScore {
  const GroupScore({
    required this.groupKey,
    required this.sessionsDone,
    required this.setsDone,
    required this.frequencyTarget,
    required this.setsTarget,
  });

  final String groupKey;
  final int sessionsDone;
  final int setsDone;

  /// Ideal sessions/week for this group.
  final int frequencyTarget;

  /// Ideal total sets/week (frequency × sets-per-session).
  final int setsTarget;

  String get label => MuscleGroup.label(groupKey);

  bool get frequencyMet => sessionsDone >= frequencyTarget;
  bool get setsMet => setsDone >= setsTarget;
  bool get fullyMet => frequencyMet && setsMet;

  /// 0..1 progress for the frequency bar.
  double get frequencyProgress =>
      frequencyTarget == 0 ? 1 : (sessionsDone / frequencyTarget).clamp(0, 1);

  /// 0..1 progress for the sets bar.
  double get setsProgress =>
      setsTarget == 0 ? 1 : (setsDone / setsTarget).clamp(0, 1);
}
