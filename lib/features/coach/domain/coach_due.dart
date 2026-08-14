import '../data/coach_tip.dart';

/// Tips that should run for [screen]: everything not yet seen, in declared
/// order. A tip added to a screen you already toured therefore surfaces on
/// your next visit — that is how a new feature announces itself.
List<CoachTip> dueTips(List<CoachTip> all, String screen, Set<String> seen) => [
  for (final CoachTip t in all)
    if (t.screen == screen && !seen.contains(t.id)) t,
];

/// Compares dotted versions ("1.14.1"). Returns <0, 0 or >0 like compareTo.
/// Missing/short parts count as 0; non-numeric parts count as 0 so a build
/// suffix never crashes this.
int compareVersions(String a, String b) {
  final List<String> x = a.split('+').first.split('.');
  final List<String> y = b.split('+').first.split('.');
  for (int i = 0; i < 3; i++) {
    final int ax = i < x.length ? (int.tryParse(x[i]) ?? 0) : 0;
    final int by = i < y.length ? (int.tryParse(y[i]) ?? 0) : 0;
    if (ax != by) return ax.compareTo(by);
  }
  return 0;
}

/// Whether [tip] should wear a "New" badge: it arrived after the version this
/// user last ran. Fresh installs ([lastSeenVersion] null) badge nothing —
/// everything is new to them, so the badge would be noise.
bool isNewSince(CoachTip tip, String? lastSeenVersion) =>
    lastSeenVersion != null &&
    compareVersions(tip.sinceVersion, lastSeenVersion) > 0;
