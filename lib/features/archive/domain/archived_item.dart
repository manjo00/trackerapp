/// What kind of thing an archived row is. Drives the icon and which restore /
/// delete methods the Archived screen calls.
enum ArchivedKind {
  task('Task'),
  list('List'),
  habit('Habit'),
  tracker('Tracker'),
  note('Note'),
  notebook('Notebook');

  const ArchivedKind(this.label);

  /// Singular, user-facing name — also the section header (pluralised by the
  /// screen). [ArchivedKind.list] is overridden with the app's list noun.
  final String label;
}

/// One row in the Archived / Recently deleted list, flattened from whichever
/// table it came from.
///
/// Flattening is what makes search possible: the screen holds a single list it
/// can filter with a pure function, instead of six typed lists each needing
/// their own matching rules. [body] is the item's *contents* — a note's text, a
/// list's task titles, a task's note — so a search can look inside, not just at
/// names.
class ArchivedItem {
  const ArchivedItem({
    required this.kind,
    required this.id,
    required this.title,
    this.body = '',
    this.colorValue,
    this.archivedAt,
    this.deletedAt,
  });

  final ArchivedKind kind;
  final int id;
  final String title;

  /// The searchable contents. Newline-separated; each line can be shown back
  /// to the user as the reason a result matched.
  final String body;

  final int? colorValue;
  final DateTime? archivedAt;

  /// Non-null only for items in Recently deleted.
  final DateTime? deletedAt;

  /// A stable key for widget lists — ids only repeat across different kinds.
  String get key => '${kind.name}:$id';
}
