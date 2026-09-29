import '../../../core/database/app_database.dart';

/// How a notebook orders its notes. Stored in settings as [key], so the
/// enum's names are part of the persisted format — add, never rename.
enum NoteSort {
  edited('edited', 'Last edited'),
  created('created', 'Date created'),
  name('name', 'Name'),
  starred('starred', 'Starred first');

  const NoteSort(this.key, this.label);

  /// The value written to settings.
  final String key;

  /// User-facing wording for the sort menu.
  final String label;

  /// Reads a stored key back; anything unknown means the default.
  static NoteSort fromKey(String? key) => NoteSort.values.firstWhere(
        (NoteSort s) => s.key == key,
        orElse: () => NoteSort.edited,
      );
}

/// Orders [notebooks] by [sort] — the same four modes as notes, so the two
/// screens read alike. "Last edited" for a notebook means the most recent
/// edit to any note inside it ([lastEdit], notebookId → time), falling back
/// to when the notebook was made for one that is still empty. Pure.
List<Notebook> sortNotebooks(
  List<Notebook> notebooks,
  NoteSort sort,
  Map<int, DateTime> lastEdit,
) {
  final List<Notebook> out = List<Notebook>.of(notebooks);
  DateTime activity(Notebook n) {
    final DateTime? edit = lastEdit[n.id];
    return edit != null && edit.isAfter(n.createdAt) ? edit : n.createdAt;
  }

  int byActivity(Notebook a, Notebook b) =>
      activity(b).compareTo(activity(a));

  switch (sort) {
    case NoteSort.edited:
      out.sort(byActivity);
    case NoteSort.created:
      out.sort((Notebook a, Notebook b) {
        final int c = b.createdAt.compareTo(a.createdAt);
        return c != 0 ? c : byActivity(a, b);
      });
    case NoteSort.name:
      out.sort((Notebook a, Notebook b) {
        final int c =
            a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase());
        return c != 0 ? c : byActivity(a, b);
      });
    case NoteSort.starred:
      out.sort((Notebook a, Notebook b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return byActivity(a, b);
      });
  }
  return out;
}

/// Orders [notes] by [sort]. Pure — unit-tested without a database.
///
/// Ties inside every mode break on "most recently edited first", which is
/// also the default, so switching modes never scrambles notes that are equal
/// under the chosen one. "Name" puts untitled notes last rather than sorting
/// a column of blanks to the top.
List<Note> sortNotes(List<Note> notes, NoteSort sort) {
  final List<Note> out = List<Note>.of(notes);
  int byEdited(Note a, Note b) => b.updatedAt.compareTo(a.updatedAt);

  switch (sort) {
    case NoteSort.edited:
      out.sort(byEdited);
    case NoteSort.created:
      out.sort((Note a, Note b) {
        final int c = b.createdAt.compareTo(a.createdAt);
        return c != 0 ? c : byEdited(a, b);
      });
    case NoteSort.name:
      out.sort((Note a, Note b) {
        final String ta = a.title.trim().toLowerCase();
        final String tb = b.title.trim().toLowerCase();
        if (ta.isEmpty != tb.isEmpty) return ta.isEmpty ? 1 : -1;
        final int c = ta.compareTo(tb);
        return c != 0 ? c : byEdited(a, b);
      });
    case NoteSort.starred:
      out.sort((Note a, Note b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return byEdited(a, b);
      });
  }
  return out;
}
