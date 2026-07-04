import '../../features/tasks/data/models/task_model.dart';

/// Section shape the builder needs — a plain record instead of the Drift
/// row class so this file stays pure Dart (no DB import, trivially
/// unit-testable). Callers map `ListSection` rows to this.
typedef FeedbackSection = ({int id, String name});

/// Turns a list name into a safe file-path segment:
/// lowercase, runs of non-alphanumerics collapse to single dashes,
/// leading/trailing dashes trimmed. Falls back to "list" when nothing
/// alphanumeric survives (e.g. a name that is all emoji/symbols).
String slugify(String name) {
  final String slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'list' : slug;
}

/// Renders one task list as the Markdown feedback document pushed to
/// GitHub. Unsectioned tasks come first under "General"; each section
/// with tasks follows as its own heading; empty sections are omitted.
///
/// [now] is injectable for tests; production callers pass DateTime.now().
String buildFeedbackMarkdown({
  required String listName,
  required List<FeedbackSection> sections,
  required List<TaskModel> tasks,
  required DateTime now,
}) {
  final String date = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  final StringBuffer md = StringBuffer()
    ..writeln('# $listName — Feedback & Ideas')
    ..writeln('_Pushed from Uplan · ${date}_')
    ..writeln();

  final Set<int> sectionIds = sections.map((s) => s.id).toSet();
  // Tasks whose section no longer exists count as unsectioned too.
  final List<TaskModel> general = tasks
      .where((t) => t.sectionId == null || !sectionIds.contains(t.sectionId))
      .toList();

  void writeBlock(String heading, List<TaskModel> blockTasks) {
    if (blockTasks.isEmpty) return;
    md
      ..writeln('## $heading')
      ..writeln();
    for (final TaskModel t in blockTasks) {
      final String box = t.isCompleted ? 'x' : ' ';
      md.writeln('- [$box] **${t.title}** `${t.priority.label}`');
      final String? note = t.note;
      if (note != null && note.trim().isNotEmpty) {
        md.writeln('  - ${note.trim()}');
      }
    }
    md.writeln();
  }

  writeBlock('General', general);
  for (final FeedbackSection section in sections) {
    writeBlock(
        section.name, tasks.where((t) => t.sectionId == section.id).toList());
  }

  if (tasks.isEmpty) md.writeln('_No open items_');

  return md.toString();
}
