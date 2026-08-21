import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../coach/presentation/coach_target.dart';
import '../../domain/archive_search.dart';
import '../../domain/archived_item.dart';
import '../archive_providers.dart';

/// Recovery bin for everything the user has put away.
///
/// Two tabs — **Archived** (kept indefinitely) and **Recently deleted** (kept
/// 30 days) — over one search field that reads titles *and contents*, so an
/// archived note can be found by a line inside it.
class ArchivedScreen extends ConsumerStatefulWidget {
  const ArchivedScreen({super.key});

  @override
  ConsumerState<ArchivedScreen> createState() => _ArchivedScreenState();
}

class _ArchivedScreenState extends ConsumerState<ArchivedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild on tab change so the ⋮ menu can offer "Empty" on the bin tab only.
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ArchiveService svc = ref.watch(archiveServiceProvider);
    final String query = _search.text;
    final List<ArchivedItem> archived =
        searchArchive(ref.watch(archivedItemsProvider), query);
    final List<ArchivedItem> deleted =
        searchArchive(ref.watch(deletedItemsProvider), query);
    final bool onBin = _tabs.index == 1;

    return CoachMarks(
      screen: kCoachArchived,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Archive'),
          actions: [
            if (onBin && deleted.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Empty Recently deleted',
                onPressed: () => _confirmEmpty(svc, deleted.length),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(108),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CoachTarget(
                    id: 'archive.search',
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search names and what is inside…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                              ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  tabs: [
                    Tab(text: 'Archived  ${_count(archived)}'),
                    Tab(text: 'Recently deleted  ${_count(deleted)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _ItemList(
              items: archived,
              query: query,
              inBin: false,
              onPrimary: (i) => _restore(svc, i),
              onSecondary: (i) => _delete(svc, i),
              emptyTitle: 'Nothing archived',
              emptyHint: query.isEmpty
                  ? 'Swipe a task or habit away and it lands here.'
                  : null,
            ),
            _ItemList(
              items: deleted,
              query: query,
              inBin: true,
              onPrimary: (i) => _restoreFromBin(svc, i),
              onSecondary: (i) => _confirmDestroy(svc, i),
              emptyTitle: 'Recently deleted is empty',
              emptyHint: query.isEmpty
                  ? 'Deleted items wait here for 30 days before they go.'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _count(List<ArchivedItem> items) =>
      items.isEmpty ? '' : '(${items.length})';

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _restore(ArchiveService svc, ArchivedItem item) async {
    switch (item.kind) {
      case ArchivedKind.task:
        await svc.restoreTask(item.id);
      case ArchivedKind.list:
        await svc.restoreList(item.id);
      case ArchivedKind.habit:
        await svc.restoreHabit(item.id);
      case ArchivedKind.tracker:
        await svc.restoreTracker(item.id);
      case ArchivedKind.note:
        await svc.restoreNote(item.id);
      case ArchivedKind.notebook:
        await svc.restoreNotebook(item.id);
    }
    _say('"${item.title}" restored');
  }

  /// Archived → Recently deleted. Undoable, and undoing puts it back in the
  /// archive rather than back into the app.
  Future<void> _delete(ArchiveService svc, ArchivedItem item) async {
    final DateTime now = DateTime.now();
    switch (item.kind) {
      case ArchivedKind.task:
        await svc.trashTask(item.id, now);
      case ArchivedKind.list:
        await svc.trashList(item.id, now);
      case ArchivedKind.habit:
        await svc.trashHabit(item.id, now);
      case ArchivedKind.tracker:
        await svc.trashTracker(item.id, now);
      case ArchivedKind.note:
        await svc.trashNote(item.id, now);
      case ArchivedKind.notebook:
        await svc.trashNotebook(item.id, now);
    }
    _say('"${item.title}" moved to Recently deleted',
        undo: () => _restoreFromBin(svc, item));
  }

  Future<void> _restoreFromBin(ArchiveService svc, ArchivedItem item) async {
    switch (item.kind) {
      case ArchivedKind.task:
        await svc.restoreTaskFromTrash(item.id);
      case ArchivedKind.list:
        await svc.restoreListFromTrash(item.id);
      case ArchivedKind.habit:
        await svc.restoreHabitFromTrash(item.id);
      case ArchivedKind.tracker:
        await svc.restoreTrackerFromTrash(item.id);
      case ArchivedKind.note:
        await svc.restoreNoteFromTrash(item.id);
      case ArchivedKind.notebook:
        await svc.restoreNotebookFromTrash(item.id);
    }
    _say('"${item.title}" restored');
  }

  Future<void> _destroy(ArchiveService svc, ArchivedItem item) async {
    switch (item.kind) {
      case ArchivedKind.task:
        await svc.destroyTask(item.id);
      case ArchivedKind.list:
        await svc.destroyList(item.id);
      case ArchivedKind.habit:
        await svc.destroyHabit(item.id);
      case ArchivedKind.tracker:
        await svc.destroyTracker(item.id);
      case ArchivedKind.note:
        await svc.destroyNote(item.id);
      case ArchivedKind.notebook:
        await svc.destroyNotebook(item.id);
    }
  }

  Future<void> _confirmDestroy(ArchiveService svc, ArchivedItem item) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item.title}" for good?'),
        content: Text(item.kind == ArchivedKind.notebook
            ? 'The notebook and the notes deleted with it go too. This cannot '
                'be undone.'
            : 'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete for good')),
        ],
      ),
    );
    if (yes == true) await _destroy(svc, item);
  }

  Future<void> _confirmEmpty(ArchiveService svc, int count) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recently deleted?'),
        content: Text('$count item${count == 1 ? '' : 's'} will be gone for '
            'good. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Empty')),
        ],
      ),
    );
    if (yes == true) {
      final int removed = await svc.emptyTrash(DateTime.now());
      _say('$removed item${removed == 1 ? '' : 's'} deleted');
    }
  }

  void _say(String message, {VoidCallback? undo}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      action: undo == null
          ? null
          : SnackBarAction(label: 'Undo', onPressed: undo),
    ));
  }
}

// ── List body ─────────────────────────────────────────────────────────────────

/// One tab's contents. Browsing groups by kind; searching shows a single ranked
/// list instead, because rank matters more than grouping once you have a query.
class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    required this.query,
    required this.inBin,
    required this.onPrimary,
    required this.onSecondary,
    required this.emptyTitle,
    this.emptyHint,
  });

  final List<ArchivedItem> items;
  final String query;
  final bool inBin;
  final void Function(ArchivedItem) onPrimary;
  final void Function(ArchivedItem) onSecondary;
  final String emptyTitle;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final bool searching = query.trim().isNotEmpty;
    if (items.isEmpty) {
      return _Empty(
        title: searching ? 'Nothing matches "${query.trim()}"' : emptyTitle,
        hint: searching ? null : emptyHint,
      );
    }

    final List<Widget> children = [];
    if (searching) {
      children.addAll(items.map(_row));
    } else {
      for (final ArchivedKind kind in ArchivedKind.values) {
        final List<ArchivedItem> mine =
            items.where((i) => i.kind == kind).toList();
        if (mine.isEmpty) continue;
        children.add(_Header(label: '${kindLabel(kind)}  ·  ${mine.length}'));
        children.addAll(mine.map(_row));
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }

  Widget _row(ArchivedItem item) => _ItemRow(
        key: ValueKey(item.key),
        item: item,
        query: query,
        inBin: inBin,
        onPrimary: () => onPrimary(item),
        onSecondary: () => onSecondary(item),
      );
}

/// The container noun is user-facing wording, so the list kind reads from
/// [kListNounPlural] rather than the enum's own label.
String kindLabel(ArchivedKind kind) => switch (kind) {
      ArchivedKind.list => kListNounPlural,
      ArchivedKind.task => 'Tasks',
      ArchivedKind.habit => 'Habits',
      ArchivedKind.tracker => 'Trackers',
      ArchivedKind.note => 'Notes',
      ArchivedKind.notebook => 'Notebooks',
    };

IconData kindIcon(ArchivedKind kind) => switch (kind) {
      ArchivedKind.task => Icons.check_circle_outline_rounded,
      ArchivedKind.list => Icons.list_alt_rounded,
      ArchivedKind.habit => Icons.repeat_rounded,
      ArchivedKind.tracker => Icons.checklist_rounded,
      ArchivedKind.note => Icons.sticky_note_2_outlined,
      ArchivedKind.notebook => Icons.folder_outlined,
    };

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.query,
    required this.inBin,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  final ArchivedItem item;
  final String query;
  final bool inBin;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int? color = item.colorValue;
    final String? subtitle = _subtitle();

    return ListTile(
      leading: color != null
          ? Icon(kindIcon(item.kind), color: Color(color))
          : Icon(kindIcon(item.kind), color: cs.onSurface.withAlpha(150)),
      title: Text(item.title, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface.withAlpha(150)),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.unarchive_rounded),
            tooltip: 'Restore',
            onPressed: onPrimary,
          ),
          IconButton(
            icon: Icon(
              inBin ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
              color: inBin ? cs.error : null,
            ),
            tooltip: inBin ? 'Delete for good' : 'Delete',
            onPressed: onSecondary,
          ),
        ],
      ),
    );
  }

  /// Why this row is here: the line that matched the search, or — in the bin —
  /// how long it has left. Searching wins, since that is what the user asked.
  String? _subtitle() {
    final String? line = matchingLine(item, query);
    final bool searching = query.trim().isNotEmpty;
    if (line != null) return '${kindSingular(item.kind)}  ·  $line';
    if (searching) return kindSingular(item.kind);
    final DateTime? deletedAt = item.deletedAt;
    if (inBin && deletedAt != null) {
      final int days = ArchiveService.daysLeftInTrash(deletedAt, DateTime.now());
      return switch (days) {
        0 => 'Deletes today',
        1 => 'Deletes tomorrow',
        _ => 'Deletes in $days days',
      };
    }
    return null;
  }
}

String kindSingular(ArchivedKind kind) =>
    kind == ArchivedKind.list ? kListNoun : kind.label;

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? hintText = hint;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: cs.onSurface.withAlpha(60)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withAlpha(160))),
            if (hintText != null) ...[
              const SizedBox(height: 6),
              Text(
                hintText,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withAlpha(110)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
