import 'dart:typed_data';

import '../data/models/muscle_groups.dart';

/// What the smart order decided for one workout.
class SmartOrderResult {
  const SmartOrderResult({required this.order, required this.movedUp});

  /// Exercise names in the order to show them.
  final List<String> order;

  /// Up to two exercises that are early today but weren't early last time —
  /// named in the "their turn for a fresh start" line. Empty on the first
  /// workout.
  final List<String> movedUp;
}

/// Helper muscles, each with the muscles whose exercises must come first: a
/// helper worked to failure early weakens the big lifts that lean on it
/// (triceps pushdowns before the bench press cut the bench reps, JSSM 2016).
const Map<String, Set<String>> _helperAfter = {
  'Triceps': {'Chest', 'Shoulders'},
  'Biceps': {'Back', 'Lats'},
  'Forearms': {'Back', 'Lats'},
  'Core': {'Back', 'Lats', 'Legs', 'Quads', 'Hamstrings', 'Glutes', 'Calves'},
};

/// Up to this many exercises the order is found by trying every order (a
/// subset search of a few million steps at most); above it, one slot at a time.
const int _maxSearched = 14;

const int _unreached = 0x3fffffff;

/// Reorders [planned] (exercise names, in the plan's order) for today's
/// workout.
///
/// [muscles] maps an exercise name to its main muscle tag; an exercise without
/// one has no family and no helper rule. [recent] holds the last workouts of
/// this same plan, newest first, each as the names in the order they were
/// really done; only the first three count.
///
/// The rules (docs/superpowers/specs/2026-11-01-gym-smart-order-design.md):
/// - The waiting list: the exercises that went the most workouts in a row
///   without an early slot (the first third of a workout) go first; a tie goes
///   to the one done later last time (skipped counts as later than last), then
///   to the plan's order. Helpers come after all the others.
/// - Helpers always come after the big lifts of their muscles.
/// - Two exercises of the same family (push, pull, legs, core) sit next to
///   each other only when no order can avoid it.
/// - Of the orders that keep those rules, the one closest to the waiting list
///   wins.
SmartOrderResult smartOrder({
  required List<String> planned,
  required Map<String, String> muscles,
  required List<List<String>> recent,
}) {
  // A name planned twice counts once.
  final List<String> names = planned.toSet().toList();
  final List<List<String>> lastThree = recent.take(3).toList();

  final List<String> waiting = _waitingList(names, muscles, lastThree);
  final List<String> order = waiting.length <= _maxSearched
      ? _searchEveryOrder(waiting, muscles)
      : _oneSlotAtATime(waiting, muscles);
  return SmartOrderResult(order: order, movedUp: _movedUp(order, lastThree));
}

/// How many of a workout's [count] places are early: the first third.
int _earlySlots(int count) => (count + 2) ~/ 3;

bool _isHelper(String? muscle) => _helperAfter.containsKey(muscle);

/// The family the "mix them up" rule keeps apart, or null (never clashes).
/// Forearm work counts as pull: it tires the grip that rows and pulldowns use.
String? _family(String? muscle) {
  final String? group = MuscleGroup.forMuscle(muscle);
  return group == MuscleGroup.forearms ? MuscleGroup.pull : group;
}

List<String> _waitingList(
  List<String> names,
  Map<String, String> muscles,
  List<List<String>> recent,
) {
  int wait(String name) {
    int workouts = 0;
    for (final List<String> done in recent) {
      final int place = done.indexOf(name);
      if (place >= 0 && place < _earlySlots(done.length)) break;
      workouts++;
    }
    return workouts;
  }

  // Place in the newest workout; a skipped exercise counts as later than last.
  int lateness(String name) {
    if (recent.isEmpty) return 0;
    final int place = recent.first.indexOf(name);
    return place < 0 ? recent.first.length : place;
  }

  final entries = [
    for (int i = 0; i < names.length; i++)
      (
        name: names[i],
        helper: _isHelper(muscles[names[i]]),
        wait: wait(names[i]),
        late: lateness(names[i]),
        planned: i,
      ),
  ];
  entries.sort((a, b) {
    if (a.helper != b.helper) return a.helper ? 1 : -1;
    if (a.wait != b.wait) return b.wait.compareTo(a.wait);
    if (a.late != b.late) return b.late.compareTo(a.late);
    return a.planned.compareTo(b.planned);
  });
  return [for (final e in entries) e.name];
}

/// For each exercise in [names], the places of the exercises that must come
/// before it (its big lifts, when it's a helper).
List<Set<int>> _mustComeAfter(List<String> names, Map<String, String> muscles) {
  return [
    for (final String name in names)
      {
        for (int i = 0; i < names.length; i++)
          if (_helperAfter[muscles[name]]?.contains(muscles[names[i]]) ?? false)
            i,
      },
  ];
}

/// Tries every order (a search over which exercises are placed so far and
/// which came last) and returns the cheapest: same-family neighbours cost
/// more than any reshuffle can, then each exercise costs how far it moved
/// from its place in the waiting list.
List<String> _searchEveryOrder(List<String> waiting, Map<String, String> muscles) {
  final int n = waiting.length;
  if (n < 2) return waiting;

  final List<String?> family = [for (final String w in waiting) _family(muscles[w])];
  final List<int> before = [
    for (final Set<int> places in _mustComeAfter(waiting, muscles))
      places.fold(0, (int mask, int i) => mask | (1 << i)),
  ];
  final int neighbourCost = n * n + 1; // more than all the moving can add up to

  final int masks = 1 << n;
  final Int32List cost = Int32List(masks * n)..fillRange(0, masks * n, _unreached);
  final Int8List cameFrom = Int8List(masks * n);
  final Uint8List placedCount = Uint8List(masks);
  for (int mask = 1; mask < masks; mask++) {
    placedCount[mask] = placedCount[mask >> 1] + (mask & 1);
  }

  for (int j = 0; j < n; j++) {
    if (before[j] != 0) continue;
    final int state = (1 << j) * n + j;
    cost[state] = j; // first slot: moved j places
    cameFrom[state] = -1;
  }
  for (int mask = 1; mask < masks; mask++) {
    final int slot = placedCount[mask];
    for (int last = 0; last < n; last++) {
      final int sofar = cost[mask * n + last];
      if (sofar == _unreached) continue;
      for (int j = 0; j < n; j++) {
        if (mask & (1 << j) != 0 || before[j] & ~mask != 0) continue;
        final bool sameFamily = family[j] != null && family[j] == family[last];
        final int next =
            sofar + (sameFamily ? neighbourCost : 0) + (slot - j).abs();
        final int state = (mask | (1 << j)) * n + j;
        if (next < cost[state]) {
          cost[state] = next;
          cameFrom[state] = last;
        }
      }
    }
  }

  final int all = masks - 1;
  int last = 0;
  for (int j = 1; j < n; j++) {
    if (cost[all * n + j] < cost[all * n + last]) last = j;
  }
  final List<String> backwards = [];
  int mask = all;
  for (int at = last; at >= 0;) {
    backwards.add(waiting[at]);
    final int previous = cameFrom[mask * n + at];
    mask &= ~(1 << at);
    at = previous;
  }
  return backwards.reversed.toList();
}

/// For long lists: each slot takes the first exercise in the waiting list
/// whose big lifts are done and whose family differs from the one before it,
/// or the first ready one when every ready one would sit next to its family.
List<String> _oneSlotAtATime(List<String> waiting, Map<String, String> muscles) {
  final List<String?> family = [for (final String w in waiting) _family(muscles[w])];
  final List<Set<int>> before = _mustComeAfter(waiting, muscles);
  final Set<int> left = {for (int i = 0; i < waiting.length; i++) i};
  final List<int> order = [];
  while (left.isNotEmpty) {
    final List<int> ready = [
      for (final int i in left)
        if (!before[i].any(left.contains)) i,
    ]..sort();
    final int pick = ready.firstWhere(
      (int i) =>
          order.isEmpty || family[i] == null || family[i] != family[order.last],
      orElse: () => ready.first,
    );
    order.add(pick);
    left.remove(pick);
  }
  return [for (final int i in order) waiting[i]];
}

List<String> _movedUp(List<String> order, List<List<String>> recent) {
  if (recent.isEmpty) return const [];
  final Set<String> earlyLastTime =
      recent.first.take(_earlySlots(recent.first.length)).toSet();
  return order
      .take(_earlySlots(order.length))
      .where((String name) => !earlyLastTime.contains(name))
      .take(2)
      .toList();
}
