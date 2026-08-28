import '../../../core/text/content_search.dart';

/// One note flattened for searching: what it is called, everything written in
/// it, and where it lives.
///
/// Flattening is what makes the search pure — the matching never touches the
/// database, so it unit-tests on plain values.
class NoteSearchItem {
  const NoteSearchItem({
    required this.id,
    required this.title,
    required this.text,
    required this.notebookId,
    required this.notebookName,
  });

  final int id;

  /// The note's own title, which is often empty — notes are usually written
  /// straight into the body.
  final String title;

  /// Everything written in the note, one block per line.
  final String text;

  /// Null for Unfiled.
  final int? notebookId;

  /// Where to say the note lives, ready to show ("Unfiled" for a loose note).
  final String notebookName;

  /// What to show as the result's heading. An untitled note is extremely
  /// common, so it gets its first written line rather than a blank row.
  String get displayTitle {
    final String t = title.trim();
    if (t.isNotEmpty) return t;
    final String firstLine = text.split('\n').firstWhere(
          (String l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    return firstLine.trim().isEmpty ? 'Untitled note' : firstLine.trim();
  }
}

/// Notes matching [query] by title **or by anything written inside them**,
/// titles first. An empty query returns everything unchanged.
List<NoteSearchItem> searchNotes(List<NoteSearchItem> items, String query) =>
    rankByTitleThenBody<NoteSearchItem>(
      items,
      query,
      title: (NoteSearchItem i) => i.displayTitle,
      body: (NoteSearchItem i) => i.text,
    );

/// The line inside a note that matched, for the result's second line. Null
/// when the query is empty or the heading already shows the match.
String? noteMatchLine(NoteSearchItem item, String query) =>
    matchingContentLine(item.displayTitle, item.text, query);
