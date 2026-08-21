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
const String kCurrentRelease = '1.16.0';

/// One line per change, in plain language — this is what the after-update
/// popup shows, so keep it short and say what the user can now DO.
const List<String> kReleaseHighlights = [
  'Deleting is no longer final. Anything you delete waits 30 days in '
      'Recently deleted, and restoring puts it back exactly where it was.',
  'Swiping a habit or tracker now archives it instead of destroying it — a '
      'mis-swipe can no longer cost you a streak or a log history. Delete '
      'moved into each one\'s ⋮ menu.',
  'Notes and notebooks can be archived now too. Archiving a notebook takes '
      'its notes with it, and brings them all back together.',
  'The Archive screen searches inside things: type a line you remember and '
      'the note it came from turns up, with the matching line shown.',
];
