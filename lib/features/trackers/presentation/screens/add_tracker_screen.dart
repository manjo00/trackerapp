import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/models/tracker_item_model.dart';
import '../../data/models/tracker_model.dart';
import '../../data/models/tracker_template.dart';
import '../providers/trackers_providers.dart';

/// Two-step screen:
///   Step 1 — pick a built-in template (or "Custom")
///   Step 2 — customise name, icon, color, items, then save
class AddTrackerScreen extends ConsumerStatefulWidget {
  const AddTrackerScreen({super.key});

  @override
  ConsumerState<AddTrackerScreen> createState() => _AddTrackerScreenState();
}

class _AddTrackerScreenState extends ConsumerState<AddTrackerScreen> {
  // ── Step tracking ─────────────────────────────────────────────────────────

  int _step = 0; // 0 = pick template, 1 = customise

  // ── Step 2 form state ─────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _iconCtrl;
  late TextEditingController _descCtrl;
  TrackerType _type = TrackerType.dailyChecklist;
  int _colorValue = 0xFF607D8B; // grey default
  // Mutable list of (name, fieldType) pairs
  final List<(String, FieldType)> _items = [];

  // ── Reminder state ────────────────────────────────────────────────────────
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  // Preset color swatches
  static const List<Color> _swatches = [
    Color(0xFF4CAF50),
    Color(0xFF1976D2),
    Color(0xFFE64A19),
    Color(0xFF7B1FA2),
    Color(0xFF0288D1),
    Color(0xFF607D8B),
    Color(0xFFF57C00),
    Color(0xFFE91E63),
    Color(0xFF00695C),
    Color(0xFF5D4037),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _iconCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Step 1 → Step 2 ───────────────────────────────────────────────────────

  void _pickTemplate(TrackerTemplate t) {
    _nameCtrl.text = t.name == 'Custom' ? '' : t.name;
    _iconCtrl.text = t.icon;
    _type = t.type;
    _colorValue = t.color.toARGB32();
    _items
      ..clear()
      ..addAll(t.defaultItems);
    setState(() => _step = 1);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  // ── Reminder helpers ──────────────────────────────────────────────────────

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(addTrackerProvider.notifier).add(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          type: _type,
          icon: _iconCtrl.text.trim().isEmpty ? '📋' : _iconCtrl.text.trim(),
          colorValue: _colorValue,
          items: List.from(_items),
          reminderEnabled: _reminderEnabled,
          reminderTime: _reminderEnabled ? _timeStr(_reminderTime) : null,
        );

    // After creation, reschedule all trackers so the new one gets its
    // notification (we don't have the new ID until we fetch fresh).
    if (_reminderEnabled) {
      final allTrackers =
          await ref.read(trackersRepositoryProvider).getAllTrackers();
      for (final t in allTrackers) {
        if (t.reminderEnabled && !t.isTemplate) {
          await NotificationService.instance.scheduleTrackerReminder(t);
        }
      }
    }

    if (mounted) context.pop();
  }

  // ── Item list helpers ─────────────────────────────────────────────────────

  void _addItem() {
    setState(() => _items.add(('', FieldType.checkbox)));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateItemName(int index, String name) {
    final (_, ft) = _items[index];
    setState(() => _items[index] = (name, ft));
  }

  void _updateItemType(int index, FieldType ft) {
    final (name, _) = _items[index];
    setState(() => _items[index] = (name, ft));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Choose a template' : 'Customise tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _step == 0 ? _buildTemplatePicker() : _buildCustomiseForm(),
    );
  }

  // ── Step 1: template grid ─────────────────────────────────────────────────

  Widget _buildTemplatePicker() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: kBuiltInTemplates.length,
      itemBuilder: (_, i) => _TemplateCard(
        template: kBuiltInTemplates[i],
        onTap: () => _pickTemplate(kBuiltInTemplates[i]),
      ),
    );
  }

  // ── Step 2: customise form ────────────────────────────────────────────────

  Widget _buildCustomiseForm() {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ── Name ──────────────────────────────────────────────────────
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Tracker name *',
              hintText: 'e.g. Daily Prayers',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),

          // ── Description (optional) ────────────────────────────────────
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // ── Icon + Color row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Emoji icon',
                    hintText: '🕌',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 22),
                  maxLength: 2,
                  buildCounter: (_, {required currentLength,
                      required isFocused, maxLength}) => null,
                ),
              ),
              const SizedBox(width: 12),
              // Color swatch picker
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _swatches.map((c) {
                        final selected = c.toARGB32() == _colorValue;
                        return GestureDetector(
                          onTap: () => setState(() => _colorValue = c.toARGB32()),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: cs.onSurface, width: 2.5)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tracker type ──────────────────────────────────────────────
          Text('Tracker type',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TrackerType>(
            segments: const [
              ButtonSegment(
                value: TrackerType.dailyChecklist,
                label: Text('Daily checklist'),
                icon: Icon(Icons.check_box_outlined),
              ),
              ButtonSegment(
                value: TrackerType.sessionLog,
                label: Text('Session log'),
                icon: Icon(Icons.table_rows_outlined),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _type == TrackerType.dailyChecklist
                ? 'A fixed checklist reset each day (e.g. prayers, medications).'
                : 'Open-ended rows per session (e.g. exercises, each with sets/reps).',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // ── Items ─────────────────────────────────────────────────────
          Row(
            children: [
              Text('Items / fields',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _type == TrackerType.dailyChecklist
                    ? 'Add items to check off each day.'
                    : 'Add fields to record per session (e.g. Exercise, Sets, Reps).',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final (name, ft) = entry.value;
            return _ItemRow(
              index: i,
              name: name,
              fieldType: ft,
              onNameChanged: (v) => _updateItemName(i, v),
              onTypeChanged: (v) => _updateItemType(i, v),
              onDelete: () => _removeItem(i),
            );
          }),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 4),

          // ── Reminder ─────────────────────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              _reminderEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: _reminderEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Daily reminder'),
            subtitle: const Text('Get notified to log this tracker'),
            value: _reminderEnabled,
            onChanged: (bool v) => setState(() => _reminderEnabled = v),
          ),
          if (_reminderEnabled) ...[
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_rounded),
              title: const Text('Reminder time'),
              trailing: Text(
                _reminderTime.format(context),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onTap: _pickTime,
            ),
          ],

          const SizedBox(height: 20),

          // ── Save button ───────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Create tracker'),
          ),
        ],
      ),
    );
  }
}

// ── Template card (step 1) ────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});
  final TrackerTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: template.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(template.icon,
                    style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 10),
              Text(
                template.name,
                style:
                    tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single item row (step 2) ──────────────────────────────────────────────

class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.index,
    required this.name,
    required this.fieldType,
    required this.onNameChanged,
    required this.onTypeChanged,
    required this.onDelete,
  });

  final int index;
  final String name;
  final FieldType fieldType;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<FieldType> onTypeChanged;
  final VoidCallback onDelete;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Drag handle (visual only — reordering is a future improvement)
          const Icon(Icons.drag_handle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Item ${widget.index + 1}',
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              onChanged: widget.onNameChanged,
            ),
          ),
          const SizedBox(width: 8),
          // Field type dropdown
          DropdownButton<FieldType>(
            value: widget.fieldType,
            isDense: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: FieldType.checkbox,
                child: Text('☑ Check'),
              ),
              DropdownMenuItem(
                value: FieldType.number,
                child: Text('# Number'),
              ),
              DropdownMenuItem(
                value: FieldType.text,
                child: Text('A Text'),
              ),
            ],
            onChanged: (v) {
              if (v != null) widget.onTypeChanged(v);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onDelete,
            tooltip: 'Remove item',
          ),
        ],
      ),
    );
  }
}
