import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_provider.dart';
import '../data/coach_content.dart';
import '../data/coach_tip.dart';
import '../domain/coach_due.dart';
import 'coach_overlay.dart';
import 'coach_target.dart';

const String _kSeenKey = 'coach_seen_tips';
const String _kVersionKey = 'coach_last_version';

/// Runs the in-place tutorial: decides which tips a screen still owes you,
/// waits for its widgets to be laid out, and drives the spotlight overlay.
class CoachController {
  CoachController(this._prefs);

  final SharedPreferences _prefs;

  /// An overlay is showing (or is being prepared) — never stack two.
  bool _busy = false;

  Set<String> get _seen =>
      (_prefs.getStringList(_kSeenKey) ?? const <String>[]).toSet();

  String? get lastSeenVersion => _prefs.getString(_kVersionKey);

  Future<void> _markSeen(String id) async {
    final Set<String> next = _seen..add(id);
    await _prefs.setStringList(_kSeenKey, next.toList());
  }

  /// Remembers the running version so later tips can be badged "New".
  Future<void> recordVersion() async {
    final PackageInfo pkg = await PackageInfo.fromPlatform();
    await _prefs.setString(_kVersionKey, pkg.version);
  }

  /// Forget everything — a full replay of every tour.
  Future<void> resetAll() async {
    await _prefs.remove(_kSeenKey);
  }

  /// Un-sees a single tip so it fires again the next time its screen opens.
  /// Used by the Codex's "Show me" button, which then navigates there.
  Future<void> replay(String tipId) async {
    final Set<String> next = _seen..remove(tipId);
    await _prefs.setStringList(_kSeenKey, next.toList());
  }

  bool get hasSeenAnything => _seen.isNotEmpty;

  /// Shows whatever [screen] still owes, if its targets are on screen.
  /// Safe to call on every visit: seen tips are skipped, and a tip whose
  /// target is missing is left for next time rather than burned.
  Future<void> run(BuildContext context, String screen) async {
    if (_busy) return;
    final List<CoachTip> due = dueTips(kCoachTips, screen, _seen);
    if (due.isEmpty) return;
    _busy = true;
    try {
      // Let the screen finish laying out (and any entry animation settle)
      // before measuring targets.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!context.mounted) return;

      final String? last = lastSeenVersion;
      final List<CoachStep> steps = [];
      for (final CoachTip t in due) {
        final String? target = t.target;
        if (target == null) {
          // Screen-level tip: dim, centred card, nothing to point at.
          steps.add(CoachStep(t, null, isNew: isNewSince(t, last)));
          continue;
        }
        // A named target that is not on screen right now is left for next
        // time rather than burned.
        final Rect? r = CoachRegistry.rectOf(target);
        if (r != null) steps.add(CoachStep(t, r, isNew: isNewSince(t, last)));
      }
      if (steps.isEmpty) return;

      final OverlayState overlay = Overlay.of(context, rootOverlay: true);
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => CoachOverlay(
          steps: steps,
          onSeen: (tip) => _markSeen(tip.id),
          onFinished: () {
            entry.remove();
            _busy = false;
          },
        ),
      );
      overlay.insert(entry);
      return; // _busy is cleared by onFinished
    } finally {
      // Only clear here when we bailed out before showing anything.
      if (_busy && !context.mounted) _busy = false;
    }
  }
}

final coachControllerProvider = Provider<CoachController>(
  (ref) => CoachController(ref.watch(sharedPreferencesProvider)),
);

/// Wrap a screen's body to have it teach itself on first visit.
///
/// ```dart
/// CoachMarks(screen: kCoachHome, child: Scaffold(...))
/// ```
class CoachMarks extends ConsumerStatefulWidget {
  const CoachMarks({required this.screen, required this.child, super.key});

  final String screen;
  final Widget child;

  @override
  ConsumerState<CoachMarks> createState() => _CoachMarksState();
}

class _CoachMarksState extends ConsumerState<CoachMarks> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A tutorial must never be able to break the screen it teaches: if the
      // controller is unavailable (e.g. prefs not provided in a widget test)
      // the screen just renders without coach marks.
      try {
        ref.read(coachControllerProvider).run(context, widget.screen);
      } on Object catch (_) {
        // no coach marks here — deliberately silent
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
