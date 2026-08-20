/// What shipped in the CURRENT release.
///
/// ## Keeping this current (do it in the same batch as the feature)
/// 1. Set [kCurrentRelease] to the version in pubspec.
/// 2. Replace [kReleaseHighlights] with this release's user-facing changes.
/// 3. Tag each new/changed Codex topic with `sinceVersion: kCurrentRelease`.
///
/// While a topic carries the current version it is pulled out of its normal
/// area and listed under "What's new" at the top of the Codex. The moment
/// [kCurrentRelease] moves on, those topics drop back into their own sections
/// automatically — nothing else to clean up.
const String kCurrentRelease = '1.15.1';

/// One line per change, in plain language — this is what the after-update
/// popup shows, so keep it short and say what the user can now DO.
const List<String> kReleaseHighlights = [
  'Uplan now shows you around: open a screen and it highlights the thing '
      'it is describing. New features introduce themselves the same way.',
  'Every Codex article that has a tip now has a "Show me" button — it takes '
      'you to the screen and points at the control, as often as you like.',
  'Notes: a line can finally leave its section by dragging DOWN past the '
      'last line, not only by dragging above the heading.',
];
