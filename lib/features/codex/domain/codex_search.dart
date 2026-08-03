import '../data/codex_topic.dart';

/// Filters Codex topics by a free-text [query], matching the title, summary,
/// keywords and body text (all case-insensitive). An empty/whitespace query
/// returns everything. Results keep their declared order, except that title
/// matches float above body-only matches. Pure — unit-tested.
List<CodexTopic> searchCodex(List<CodexTopic> topics, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return topics;

  bool inTitle(CodexTopic t) =>
      t.title.toLowerCase().contains(q) ||
      t.keywords.any((k) => k.toLowerCase().contains(q));

  bool inBody(CodexTopic t) =>
      t.summary.toLowerCase().contains(q) ||
      t.body.any((b) => b.text.toLowerCase().contains(q));

  return [
    ...topics.where(inTitle),
    ...topics.where((t) => !inTitle(t) && inBody(t)),
  ];
}

/// The hidden/power features, in declared order.
List<CodexTopic> hiddenGems(List<CodexTopic> topics) =>
    topics.where((t) => t.hidden).toList();
