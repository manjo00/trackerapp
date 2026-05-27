import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/tracker_item_model.dart';
import '../../data/models/tracker_model.dart';
import '../providers/trackers_providers.dart';

/// Log entry screen — adapts its form based on [trackerType]:
///   - [TrackerType.dailyChecklist]: a list of checkboxes, replaces today's log.
///   - [TrackerType.sessionLog]: free-form fields, appends a new row.
///
/// Receives via `state.extra`:
/// ```dart
/// {
///   'name': String,
///   'icon': String,
///   'items': List<TrackerItemModel>,
///   'trackerId': int,
///   'trackerType': TrackerType,
///   // for checklist pre-fill:
///   'checkedItemIds': Set<int>,   // optional
/// }
/// ```
class LogEntryScreen extends ConsumerStatefulWidget {
  const LogEntryScreen({
    super.key,
    required this.trackerId,
    required this.trackerName,
    required this.trackerIcon,
    required this.items,
    required this.trackerType,
    this.preChecked,
  });

  final int trackerId;
  final String trackerName;
  final String trackerIcon;
  final List<TrackerItemModel> items;
  final TrackerType trackerType;
  final Set<int>? preChecked; // for checklist pre-fill

  @override
  ConsumerState<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends ConsumerState<LogEntryScreen> {
  // ── Checklist state ───────────────────────────────────────────────────────
  late Set<int> _checked;

  // ── Session-log state ─────────────────────────────────────────────────────
  late Map<int, TextEditingController> _controllers;

  // ── Shared ────────────────────────────────────────────────────────────────
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checked = Set.from(widget.preChecked ?? {});
    _controllers = {
      for (final item in widget.items)
        item.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    if (widget.trackerType == TrackerType.dailyChecklist) {
      await ref.read(logChecklistProvider.notifier).save(
            trackerId: widget.trackerId,
            checkedItemIds: _checked,
            allItems: widget.items,
            notes: notes,
          );
    } else {
      final Map<int, String> values = {};
      for (final item in widget.items) {
        values[item.id] = _controllers[item.id]?.text.trim() ?? '';
      }
      await ref.read(logSessionRowProvider.notifier).save(
            trackerId: widget.trackerId,
            fieldValues: values,
            notes: notes,
          );
    }

    if (mounted) context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateFormat('EEE, d MMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.trackerIcon),
                const SizedBox(width: 8),
                Flexible(child: Text(widget.trackerName)),
              ],
            ),
            Text(
              today,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: widget.items.isEmpty
          ? _NoItemsPlaceholder(
              onBack: () => context.pop(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (widget.trackerType == TrackerType.dailyChecklist)
                  ..._buildChecklistItems()
                else
                  ..._buildSessionFields(),

                const SizedBox(height: 16),

                // Notes field
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Any additional notes…',
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    widget.trackerType == TrackerType.dailyChecklist
                        ? 'Save checklist'
                        : 'Add session row',
                  ),
                ),
              ],
            ),
    );
  }

  // ── Checklist items ───────────────────────────────────────────────────────

  List<Widget> _buildChecklistItems() {
    return widget.items.map((item) {
      final checked = _checked.contains(item.id);
      return CheckboxListTile(
        title: Text(item.name),
        value: checked,
        onChanged: (v) {
          setState(() {
            if (v == true) {
              _checked.add(item.id);
            } else {
              _checked.remove(item.id);
            }
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: Theme.of(context).colorScheme.primary,
      );
    }).toList();
  }

  // ── Session fields ────────────────────────────────────────────────────────

  List<Widget> _buildSessionFields() {
    return widget.items.map((item) {
      final ctrl = _controllers[item.id]!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: item.name,
            border: const OutlineInputBorder(),
          ),
          keyboardType: item.fieldType == FieldType.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
      );
    }).toList();
  }
}

// ── No-items placeholder ──────────────────────────────────────────────────

class _NoItemsPlaceholder extends StatelessWidget {
  const _NoItemsPlaceholder({required this.onBack});
  final VoidCallback onBack;

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
            const Text('⚙️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No items defined',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Edit this tracker and add some items before logging.',
              style:
                  tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
