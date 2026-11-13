/// The morning and night du'a lists as habits count them. Pure Dart.
library;

import 'adhkar_lists.dart';
import 'dhikr.dart';

/// Which list a du'a habit counts. A habit is a du'a habit when its
/// `autoSource` is one of these [source]s.
enum AdhkarList {
  morning('adhkar:morning'),
  night('adhkar:night');

  const AdhkarList(this.source);

  /// The habit's `autoSource` value.
  final String source;

  /// The du'as, in the post's order.
  List<Dhikr> get items => switch (this) {
        AdhkarList.morning => kMorningAdhkar,
        AdhkarList.night => kNightAdhkar,
      };

  /// The list a habit's [source] names, or null for any other habit.
  static AdhkarList? fromSource(String? source) {
    for (final AdhkarList list in values) {
      if (list.source == source) return list;
    }
    return null;
  }
}

/// One day's counts of a list: how many times each du'a has been said.
/// Immutable; every change returns a new value.
class AdhkarProgress {
  const AdhkarProgress._(this.items, this._counts);

  /// Nothing counted yet.
  AdhkarProgress.empty(this.items) : _counts = const {};

  /// Counts saved by [toJson]. Ids no longer in [items] are dropped and each
  /// count is kept between 0 and its du'a's number of times.
  factory AdhkarProgress.fromJson(List<Dhikr> items, Map<String, dynamic> json) {
    final Map<String, int> counts = {};
    for (final Dhikr d in items) {
      final Object? raw = json[d.id];
      if (raw is int && raw > 0) counts[d.id] = raw > d.times ? d.times : raw;
    }
    return AdhkarProgress._(items, counts);
  }

  final List<Dhikr> items;
  final Map<String, int> _counts;

  /// How many times du'a [i] has been said.
  int countOf(int i) => _counts[items[i].id] ?? 0;

  /// Whether du'a [i] has reached its count.
  bool isFinished(int i) => countOf(i) >= items[i].times;

  /// How many du'as have reached their count: the habit's day value.
  int get finished {
    int n = 0;
    for (int i = 0; i < items.length; i++) {
      if (isFinished(i)) n++;
    }
    return n;
  }

  /// Every du'a has reached its count.
  bool get complete => finished == items.length;

  /// One more for du'a [i]; nothing changes once it has reached its count.
  AdhkarProgress tapped(int i) =>
      isFinished(i) ? this : _with(items[i].id, countOf(i) + 1);

  /// One fewer for du'a [i] (a mistaken tap); never below 0.
  AdhkarProgress untapped(int i) =>
      countOf(i) == 0 ? this : _with(items[i].id, countOf(i) - 1);

  /// Every du'a at its count (today was marked done somewhere else).
  AdhkarProgress allDone() =>
      AdhkarProgress._(items, {for (final Dhikr d in items) d.id: d.times});

  /// What the counter shows: these counts, or every du'a done when the
  /// habit's day is already kept (marked done from the live notification,
  /// say), so the two never disagree.
  AdhkarProgress shown({required bool dayKept}) =>
      dayKept && !complete ? allDone() : this;

  /// The first du'a not finished yet, or null when all are.
  int? get firstOpen => nextOpen(after: -1);

  /// The next du'a after [after] not finished yet, going round to the start;
  /// null when all are finished.
  int? nextOpen({required int after}) {
    for (int step = 1; step <= items.length; step++) {
      final int i = (after + step) % items.length;
      if (!isFinished(i)) return i;
    }
    return null;
  }

  /// The counts above 0, by du'a id, for saving.
  Map<String, int> toJson() => Map.unmodifiable(_counts);

  AdhkarProgress _with(String id, int count) {
    final Map<String, int> next = {..._counts};
    if (count <= 0) {
      next.remove(id);
    } else {
      next[id] = count;
    }
    return AdhkarProgress._(items, next);
  }
}
