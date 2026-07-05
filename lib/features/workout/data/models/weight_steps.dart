/// Pure weight-stepper math for the set row's ± buttons.
///
/// Gym plates and dumbbells live on a 2.5 kg ladder (… 10 → 12.5 → 15 …),
/// so stepping snaps to the nearest rung instead of blindly adding 2.5
/// from wherever the user happens to be (11 + step should give 12.5,
/// not 13.5).
library;

/// The plate/dumbbell increment the ± buttons snap to.
const double kPlateStep = 2.5;

/// Tolerance for floating-point drift (12.499999 counts as "on 12.5").
const double _eps = 0.001;

/// The smallest ladder rung strictly above [weight].
double nextWeightUp(double weight) {
  final int steps = ((weight + _eps) / kPlateStep).floor();
  return (steps + 1) * kPlateStep;
}

/// The largest ladder rung strictly below [weight] (never negative).
double nextWeightDown(double weight) {
  final int steps = ((weight - _eps) / kPlateStep).ceil();
  final double down = (steps - 1) * kPlateStep;
  return down < 0 ? 0 : down;
}

/// Parses a typed weight, accepting "." as well as the comma and
/// Arabic-style decimal separators some keyboards produce ("12,5", "12٫5").
double? parseWeight(String text) {
  if (text.trim().isEmpty) return null;
  return double.tryParse(text.trim().replaceAll(',', '.').replaceAll('٫', '.'));
}
