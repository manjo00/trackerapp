import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_priority.dart';
import '../providers/tasks_providers.dart';

/// Full-screen form for creating OR editing a task.
///
/// **Create mode** — reached via `context.push('/tasks/add')`.
///   All fields are blank. Saves via [addTaskProvider].
///
/// **Edit mode** — reached via `context.push('/tasks/edit', extra: task)`.
///   Fields are pre-filled from [task]. Saves via [updateTaskProvider].
///
/// Also accepts [initialDate] so the planner's long-press pre-fills the
/// due-date field without putting the screen in edit mode.
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({
    this.task,
    this.initialDate,
    super.key,
  });

  /// If non-null, the screen is in edit mode and pre-fills from this model.
  final TaskModel? task;

  /// Optional pre-filled due date ("yyyy-MM-dd") for new tasks from planner.
  final String? initialDate;

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  late TaskPriority _priority;
  bool _reminderEnabled = false;
  bool _lead1d = false;
  bool _lead3h = false;
  bool _lead5m = false;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final TaskModel? t = widget.task;
    if (t != null) {
      // Edit mode — pre-fill every field from the existing task.
      _titleCtrl = TextEditingController(text: t.title);
      _noteCtrl = TextEditingController(text: t.note ?? '');
      _dueDate = t.dueDate != null ? DateTime.parse(t.dueDate!) : null;
      _dueTime = _parseTimeOfDay(t.dueTime);
      _priority = t.priority;
      _reminderEnabled = t.reminderEnabled;
      final List<int> leads = t.leadTimeMinutes;
      _lead1d = leads.contains(1440);
      _lead3h = leads.contains(180);
      _lead5m = leads.contains(5);
    } else {
      // Create mode — blank form, optional pre-filled date from planner.
      _titleCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
      _priority = TaskPriority.medium;
      if (widget.initialDate != null) {
        _dueDate = DateTime.parse(widget.initialDate!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parses "HH:mm" → [TimeOfDay]. Returns null on any parse failure.
  static TimeOfDay? _parseTimeOfDay(String? s) {
    if (s == null) return null;
    final List<String> parts = s.split(':');
    if (parts.length != 2) return null;
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Formats [TimeOfDay] as "HH:mm" for storage.
  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _toDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDisplay(DateTime d) {
    const List<String> months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const List<String> weekdays = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    final DateTime today = DateTime.now();
    final DateTime todayDate =
        DateTime(today.year, today.month, today.day);
    final DateTime picked = DateTime(d.year, d.month, d.day);
    final int diff = picked.difference(todayDate).inDays;

    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => '${weekdays[d.weekday]}, ${d.day} ${months[d.month]}',
    };
  }

  /// Builds the lead-times CSV (e.g. "1440,180") from the checkbox state.
  /// Returns null when no boxes are ticked or reminders are off.
  String? _buildLeadTimesStr() {
    if (!_reminderEnabled) return null;
    final List<int> selected = [
      if (_lead1d) 1440,
      if (_lead3h) 180,
      if (_lead5m) 5,
    ];
    return selected.isEmpty ? null : selected.join(',');
  }

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickDueTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final String? dueDateStr =
        _dueDate != null ? _toDateString(_dueDate!) : null;
    final String? dueTimeStr =
        _dueTime != null ? _timeStr(_dueTime!) : null;
    final String? leadTimesStr = _buildLeadTimesStr();

    if (_isEditing) {
      final TaskModel updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        dueDate: dueDateStr,
        dueTime: dueTimeStr,
        priority: _priority,
        reminderEnabled: _reminderEnabled,
        reminderLeadTimes: leadTimesStr,
      );
      await ref.read(updateTaskProvider.notifier).save(updated);

      // Apply notification change immediately for the edited task.
      if (_reminderEnabled && dueDateStr != null) {
        await NotificationService.instance.scheduleTaskReminders(updated);
      } else {
        await NotificationService.instance.cancelTaskReminders(updated.id);
      }
    } else {
      await ref.read(addTaskProvider.notifier).add(
            _titleCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            dueDate: dueDateStr,
            dueTime: dueTimeStr,
            priority: _priority,
            reminderEnabled: _reminderEnabled,
            reminderLeadTimes: leadTimesStr,
          );

      // After creation, reschedule all tasks so the new one gets its
      // notifications (we don't have the new ID yet, so we fetch fresh).
      if (_reminderEnabled && dueDateStr != null) {
        final List<TaskModel> allTasks =
            await ref.read(tasksRepositoryProvider).getAllTasks();
        for (final TaskModel task in allTasks) {
          if (task.reminderEnabled && !task.isCompleted) {
            await NotificationService.instance.scheduleTaskReminders(task);
          }
        }
      }
    }

    if (mounted) context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Title ─────────────────────────────────────────────────────
            Text(
              'What needs to get done?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Book dentist appointment',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                if (value.trim().length > 200) {
                  return 'Title must be 200 characters or fewer';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Note ──────────────────────────────────────────────────────
            Text(
              'Add a note  (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Any extra details…',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 28),

            // ── Due date ──────────────────────────────────────────────────
            Text(
              'Due date  (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _DateTimeTile(
              icon: Icons.calendar_month_rounded,
              label: _dueDate != null ? _formatDisplay(_dueDate!) : 'No due date',
              active: _dueDate != null,
              onTap: _pickDate,
              onClear: _dueDate != null ? () => setState(() => _dueDate = null) : null,
            ),

            const SizedBox(height: 12),

            // ── Due time ──────────────────────────────────────────────────
            _DateTimeTile(
              icon: Icons.access_time_rounded,
              label: _dueTime != null
                  ? _dueTime!.format(context)
                  : 'No time set',
              active: _dueTime != null,
              onTap: _pickDueTime,
              onClear: _dueTime != null ? () => setState(() => _dueTime = null) : null,
            ),

            const SizedBox(height: 28),

            // ── Priority ──────────────────────────────────────────────────
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _PrioritySelector(
              value: _priority,
              onChanged: (TaskPriority p) => setState(() => _priority = p),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 4),

            // ── Reminders ─────────────────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                _reminderEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                color: _reminderEnabled ? cs.primary : cs.onSurfaceVariant,
              ),
              title: const Text('Reminders'),
              subtitle: const Text('Get notified before the due time'),
              value: _reminderEnabled,
              onChanged: (bool v) => setState(() => _reminderEnabled = v),
            ),

            if (_reminderEnabled) ...[
              // Amber warning when no due date is set.
              if (_dueDate == null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Set a due date above for reminders to fire',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Lead-time checkboxes (always shown when reminder is on).
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('1 day before'),
                value: _lead1d,
                onChanged: (bool? v) => setState(() => _lead1d = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('3 hours before'),
                value: _lead3h,
                onChanged: (bool? v) => setState(() => _lead3h = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('5 minutes before'),
                value: _lead5m,
                onChanged: (bool? v) => setState(() => _lead5m = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],

            const SizedBox(height: 40),

            // ── Save button ───────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Save changes' : 'Save task',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared date/time picker tile ──────────────────────────────────────────────

/// A styled tap-target for date and time pickers — reused for both due date
/// and due time to keep visual consistency.
class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withAlpha(120)),
          borderRadius: BorderRadius.circular(12),
          color: cs.surfaceContainerLow,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? cs.primary : cs.onSurface.withAlpha(120),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: active ? cs.onSurface : cs.onSurface.withAlpha(120),
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurface.withAlpha(120),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Priority selector ─────────────────────────────────────────────────────────

/// Three pill buttons — one per [TaskPriority] value.
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.value,
    required this.onChanged,
  });

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((TaskPriority p) {
        final bool selected = p == value;
        final Color color = p.color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: p != TaskPriority.high ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color.withAlpha(40) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? color : color.withAlpha(80),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    p.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : color.withAlpha(160),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
