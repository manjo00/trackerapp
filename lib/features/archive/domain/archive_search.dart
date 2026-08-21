import 'archived_item.dart';

/// Filters archived/deleted items by a free-text [query], matching the title
/// **and the contents** — a note's lines, a list's task titles, a task's note.
/// Case-insensitive. An empty query returns everything unchanged.
///
/// Title matches float above content-only matches, so searching "shopping"
/// puts the list called Shopping above the note that merely mentions it. Pure —
/// unit-tested, no database needed.
List<ArchivedItem> searchArchive(List<ArchivedItem> items, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return items;

  bool inTitle(ArchivedItem i) => i.title.toLowerCase().contains(q);
  bool inBody(ArchivedItem i) => i.body.toLowerCase().contains(q);

  return [
    ...items.where(inTitle),
    ...items.where((i) => !inTitle(i) && inBody(i)),
  ];
}

/// The line of [item]'s contents that [query] matched, trimmed for display —
/// so a result can show *why* it came up instead of just appearing.
///
/// Returns null when the query is empty, or when it matched the title only
/// (the title is already on screen; repeating it underneath is noise).
String? matchingLine(ArchivedItem item, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return null;
  if (item.title.toLowerCase().contains(q)) return null;
  for (final String line in item.body.split('\n')) {
    if (line.toLowerCase().contains(q)) {
      final String trimmed = line.trim();
      return trimmed.length <= 90 ? trimmed : '${trimmed.substring(0, 90)}…';
    }
  }
  return null;
}
