import '../../../core/text/content_search.dart';
import 'archived_item.dart';

/// Filters archived/deleted items by a free-text [query], matching the title
/// **and the contents** — a note's lines, a list's task titles, a task's note.
///
/// A thin wrapper over the shared matcher, so the Archive and Notes searches
/// can never drift apart in how they rank or what they consider a match.
List<ArchivedItem> searchArchive(List<ArchivedItem> items, String query) =>
    rankByTitleThenBody<ArchivedItem>(
      items,
      query,
      title: (ArchivedItem i) => i.title,
      body: (ArchivedItem i) => i.body,
    );

/// The line of [item]'s contents that [query] matched, trimmed for display.
/// Null when the query is empty or matched the title.
String? matchingLine(ArchivedItem item, String query) =>
    matchingContentLine(item.title, item.body, query);
