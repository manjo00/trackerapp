import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/tracker_item_model.dart';
import '../../data/models/tracker_log_model.dart';
import '../../data/models/tracker_model.dart';
import '../providers/trackers_providers.dart';

/// Shows the full log history for one tracker plus a button to log today.
class TrackerDetailScreen extends ConsumerWidget {
  const TrackerDetailScreen({
    super.key,
    required this.trackerId,
    required this.trackerName,
    required this.trackerIcon,
    required this.trackerType,
  });

  final int trackerId;
  final String trackerName;
  final String trackerIcon;
  final TrackerType trackerType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(trackerLogsProvider(trackerId));
    final itemsAsync = ref.watch(trackerItemsProvider(trackerId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(trackerIcon),
            const SizedBox(width: 8),
            Flexible(child: Text(trackerName)),
          ],
        ),
      ),
      floatingActionButton: itemsAsync.when(
        data: (items) => FloatingActionButton.extended(
          onPressed: () => context.push(
            '/trackers/$trackerId/log',
            extra: {
              'name': trackerName,
              'icon': trackerIcon,
              'items': items,
              'trackerType': trackerType,
            },
          ),
          icon: const Icon(Icons.add),
          label: const Text('Log entry'),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return _EmptyHistory(
              onLog: () => itemsAsync.whenData(
                (items) => context.push(
                  '/trackers/$trackerId/log',
                  extra: {
                    'name': trackerName,
                    'icon': trackerIcon,
                    'items': items,
                    'trackerType': trackerType,
                  },
                ),
              ),
            );
          }
          return itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) => _LogList(
              logs: logs,
              items: items,
              trackerId: trackerId,
              ref: ref,
            ),
          );
        },
      ),
    );
  }
}

// ── Log list ──────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({
    required this.logs,
    required this.items,
    required this.trackerId,
    required this.ref,
  });

  final List<TrackerLogModel> logs;
  final List<TrackerItemModel> items;
  final int trackerId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // Group logs by date
    final Map<String, List<TrackerLogModel>> byDate = {};
    for (final log in logs) {
      (byDate[log.loggedDate] ??= []).add(log);
    }
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: sortedDates.length,
      itemBuilder: (_, i) {
        final date = sortedDates[i];
        final dateLogs = byDate[date]!;
        return _DateGroup(
          date: date,
          logs: dateLogs,
          items: items,
          trackerId: trackerId,
          ref: ref,
        );
      },
    );
  }
}

// ── Date group ────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.date,
    required this.logs,
    required this.items,
    required this.trackerId,
    required this.ref,
  });

  final String date;
  final List<TrackerLogModel> logs;
  final List<TrackerItemModel> items;
  final int trackerId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final formatted = _formatDate(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(formatted,
              style: tt.labelLarge?.copyWith(color: cs.primary)),
        ),
        ...logs.map((log) => _LogCard(
              log: log,
              items: items,
              trackerId: trackerId,
              ref: ref,
            )),
        const Divider(height: 24),
      ],
    );
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final logDay = DateTime(dt.year, dt.month, dt.day);
      if (logDay == today) return 'Today';
      if (logDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('EEEE, d MMMM yyyy').format(dt);
    } catch (_) {
      return d;
    }
  }
}

// ── Single log card ───────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.log,
    required this.items,
    required this.trackerId,
    required this.ref,
  });

  final TrackerLogModel log;
  final List<TrackerItemModel> items;
  final int trackerId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Build a map of itemId → item for quick lookup
    final itemMap = {for (final item in items) item.id: item};

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Values
            ...log.values.map((v) {
              final item = itemMap[v.itemId];
              final name = item?.name ?? 'Field ${v.itemId}';
              final ft = item?.fieldType ?? FieldType.text;
              return _ValueRow(name: name, value: v.valueText, fieldType: ft);
            }),

            // Notes
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.notes!,
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
            ],

            // Time + delete
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(log.createdAt),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: cs.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete log',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete log entry?'),
        content: const Text('This entry will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(deleteLogProvider.notifier)
          .delete(log.id, trackerId: trackerId);
    }
  }
}

// ── Value row ─────────────────────────────────────────────────────────────

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.name,
    required this.value,
    required this.fieldType,
  });

  final String name;
  final String value;
  final FieldType fieldType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget leading;
    if (fieldType == FieldType.checkbox) {
      final checked = value == 'true';
      leading = Icon(
        checked ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
        color: checked ? cs.primary : cs.onSurfaceVariant,
      );
    } else {
      leading = Text(value, style: tt.bodyMedium);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Text(name, style: tt.bodyMedium),
          if (fieldType != FieldType.checkbox) ...[
            const SizedBox(width: 4),
            Text('· $value',
                style:
                    tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

// ── Empty history ─────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onLog});
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📂', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No entries yet',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to log your first entry.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.add),
              label: const Text('Log entry'),
            ),
          ],
        ),
      ),
    );
  }
}
