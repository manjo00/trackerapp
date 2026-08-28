// Free-text matching shared by every "search inside things" surface — the
// Archive screen and Notes search. One implementation means searching behaves
// the same wherever you do it, and there is one place to improve it.

/// Ranks [items] against a free-text [query], matching a title and a body of
/// newline-separated content.
///
/// Title matches float above content-only matches, so searching "shopping"
/// puts the thing *called* Shopping above the one that merely mentions it.
/// Case-insensitive; an empty query returns the list unchanged. Pure.
List<T> rankByTitleThenBody<T>(
  List<T> items,
  String query, {
  required String Function(T) title,
  required String Function(T) body,
}) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return items;

  bool inTitle(T item) => title(item).toLowerCase().contains(q);
  bool inBody(T item) => body(item).toLowerCase().contains(q);

  return [
    ...items.where(inTitle),
    ...items.where((item) => !inTitle(item) && inBody(item)),
  ];
}

/// The line of [body] that [query] matched, trimmed for display — so a result
/// can show *why* it came up instead of just appearing.
///
/// Returns null when the query is empty, or when it matched [title] (which is
/// already on screen; repeating it underneath is noise).
String? matchingContentLine(String title, String body, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return null;
  if (title.toLowerCase().contains(q)) return null;
  for (final String line in body.split('\n')) {
    if (line.toLowerCase().contains(q)) {
      final String trimmed = line.trim();
      return trimmed.length <= 90 ? trimmed : '${trimmed.substring(0, 90)}…';
    }
  }
  return null;
}
