import 'package:intl/intl.dart';

import '../data/models/workout_session_model.dart';
import '../data/models/workout_set_model.dart';

/// What the workout history shows about a past workout (look B, Ahmed's pick
/// 2026-11-04): its totals, the order its exercises were done in, and how each
/// exercise changed since the last workout of the same plan.

/// A set counts as logged once its weight or reps are filled in (the rows made
/// when an exercise is opened start empty).
bool isLogged(WorkoutSetModel set) => set.weightKg != null || set.reps != null;

int loggedSetCount(Iterable<WorkoutSetModel> sets) => sets.where(isLogged).length;

/// Kilos lifted: each set's weight × reps, added up. Warm-ups and sets missing
/// either number are left out.
double kgLifted(Iterable<WorkoutSetModel> sets) {
  double total = 0;
  for (final WorkoutSetModel set in sets) {
    final double? kg = set.weightKg;
    final int? reps = set.reps;
    if (set.isWarmup || kg == null || reps == null) continue;
    total += kg * reps;
  }
  return total;
}

/// How many exercises got a new record (an exercise with two record sets
/// counts once).
int recordCount(Iterable<WorkoutSetModel> sets) =>
    {for (final WorkoutSetModel s in sets) if (s.isPr) s.exerciseName}.length;

/// Exercise names by their first tick, then the never-ticked ones in the order
/// given (the order they were opened). Ticks are saved to the second, so a tie
/// keeps the opened order.
List<String> exercisesInDoneOrder(
    Iterable<({String name, DateTime? tick})> sets) {
  final List<String> opened = [];
  final Map<String, DateTime> firstTick = {};
  for (final (:String name, :DateTime? tick) in sets) {
    if (!opened.contains(name)) opened.add(name);
    final DateTime? earliest = firstTick[name];
    if (tick != null && (earliest == null || tick.isBefore(earliest))) {
      firstTick[name] = tick;
    }
  }
  final List<(DateTime, int, String)> ticked = [
    for (int i = 0; i < opened.length; i++)
      if (firstTick[opened[i]] case final DateTime tick) (tick, i, opened[i]),
  ]..sort((a, b) {
      final int byTime = a.$1.compareTo(b.$1);
      return byTime != 0 ? byTime : a.$2.compareTo(b.$2);
    });
  return [
    for (final (_, _, String name) in ticked) name,
    for (final String name in opened)
      if (!firstTick.containsKey(name)) name,
  ];
}

/// The older workout [session] is compared with ("last time"): the most recent
/// one after it in [newestFirst] from the same plan — or, for a workout
/// without a plan, with the same name — that shares at least 3 in 4 of its
/// exercises. A short or half-done workout is skipped, so it can't turn into
/// "308% more than last time".
WorkoutSessionModel? previousOfSamePlan(
    List<WorkoutSessionModel> newestFirst, WorkoutSessionModel session) {
  final int at = newestFirst.indexWhere((s) => s.id == session.id);
  if (at < 0) return null;
  final int? plan = session.programSessionId;
  final String? name = session.name;
  for (final WorkoutSessionModel older in newestFirst.skip(at + 1)) {
    final bool same = plan != null
        ? older.programSessionId == plan
        : name != null && name.isNotEmpty && older.name == name;
    if (same && _similar(session, older)) return older;
  }
  return null;
}

/// Whether two workouts share at least 3 in 4 exercises, counted against the
/// one with more.
bool _similar(WorkoutSessionModel a, WorkoutSessionModel b) {
  Set<String> exercises(WorkoutSessionModel w) =>
      {for (final WorkoutSetModel s in w.sets) if (isLogged(s)) s.exerciseName};
  final Set<String> mine = exercises(a);
  final Set<String> theirs = exercises(b);
  final int bigger = mine.length > theirs.length ? mine.length : theirs.length;
  return bigger > 0 && mine.intersection(theirs).length * 4 >= bigger * 3;
}

/// An exercise's best set: the heaviest, then the one with the most reps.
/// Warm-ups are left out.
WorkoutSetModel? topSet(Iterable<WorkoutSetModel> sets) {
  WorkoutSetModel? best;
  for (final WorkoutSetModel set in sets) {
    if (set.isWarmup || !isLogged(set)) continue;
    final WorkoutSetModel? current = best;
    if (current == null) {
      best = set;
      continue;
    }
    final int byKg = (set.weightKg ?? 0).compareTo(current.weightKg ?? 0);
    if (byKg > 0 || (byKg == 0 && (set.reps ?? 0) > (current.reps ?? 0))) {
      best = set;
    }
  }
  return best;
}

/// How an exercise's top set changed since last time, in a few words
/// ("+2.5 kg", "+2 reps", "+5 kg, 3 fewer reps", "new"). [better] is true
/// only when nothing went down, so a mixed change stays neutral — the
/// history never scolds.
({String label, bool better}) changeSinceLastTime(
    WorkoutSetModel? now, WorkoutSetModel? before) {
  if (now == null || before == null) return (label: 'new', better: false);
  final double kg = (now.weightKg ?? 0) - (before.weightKg ?? 0);
  final int reps = (now.reps ?? 0) - (before.reps ?? 0);
  final bool kgMoved = kg.abs() >= 0.01;
  final List<String> parts = [
    if (kgMoved) '${kg > 0 ? '+' : '−'}${_plain(kg.abs())} kg',
    if (reps != 0)
      switch ((kgMoved, reps > 0)) {
        (false, true) => '+$reps ${_reps(reps)}',
        (true, true) => '$reps more ${_reps(reps)}',
        (_, false) => '${-reps} fewer ${_reps(-reps)}',
      },
  ];
  if (parts.isEmpty) return (label: 'same as last time', better: false);
  return (label: parts.join(', '), better: kg >= 0 && reps >= 0);
}

String _reps(int n) => n == 1 ? 'rep' : 'reps';

/// One set as the workout page shows it: "17.5 × 8", or "12 reps" / "50 kg"
/// when only one number was filled in.
String setLabel(WorkoutSetModel set) {
  final double? kg = set.weightKg;
  final int? reps = set.reps;
  if (kg != null && reps != null) return '${_plain(kg)} × $reps';
  if (kg != null) return '${_plain(kg)} kg';
  return '${reps ?? 0} ${_reps(reps ?? 0)}';
}

/// "2.5", "5", "1.25": a weight without trailing zeros.
String _plain(double kg) =>
    kg.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// Percent more (positive) or less (negative) than [before], rounded; null
/// when there's nothing to compare with.
int? percentChange(double now, double before) =>
    before <= 0 ? null : ((now - before) / before * 100).round();

/// The history row's big number: tonnes from 1,000 kg up ("5.7 t"), else
/// kilos ("850 kg").
String shortKg(double kg) => kg >= 1000
    ? '${(kg / 1000).toStringAsFixed(1)} t'
    : '${kg.round()} kg';

/// The workout page's headline: every kilo ("5,712 kg").
String fullKg(double kg) => '${NumberFormat('#,##0').format(kg.round())} kg';

/// The workout's length ("52 min", "2 h 05 min"), known once Finish was
/// tapped (v26). A workout finished more than 6 hours after it started was
/// left open, so it has no length.
String? lengthLabel(WorkoutSessionModel session) {
  final DateTime? end = session.finishedAt;
  if (end == null) return null;
  final Duration length = end.difference(session.createdAt);
  if (length.isNegative || length > const Duration(hours: 6)) return null;
  final int minutes = length.inMinutes;
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
}
