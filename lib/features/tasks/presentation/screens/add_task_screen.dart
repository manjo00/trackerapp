import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
///
/// Lives outside the [StatefulShellRoute] so the bottom nav is hidden.
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
  late TaskPriority _priority;
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
      _priority = t.priority;
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

  // ── Date helpers ─────────────────────────────────────────────────────────

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

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final String? dueDateStr =
        _dueDate != null ? _toDateString(_dueDate!) : null;

    if (_isEditing) {
      // Edit mode: update existing task, preserving id and completion state.
      await ref.read(updateTaskProvider.notifier).save(
            widget.task!.copyWith(
              title: _titleCtrl.text.trim(),
              note: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
              dueDate: dueDateStr,
              priority: _priority,
            ),
          );
    } else {
      // Create mode: add a brand-new task.
      await ref.read(addTaskProvider.notifier).add(
            _titleCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            dueDate: dueDateStr,
            priority: _priority,
          );
    }

    if (mounted) context.pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
            // ── Title ──────────────────────────────────────────────────────
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

            // ── Note (optional) ────────────────────────────────────────────
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

            // ── Due date ───────────────────────────────────────────────────
            Text(
              'Due date  (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withAlpha(120)),
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainerLow,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: _dueDate != null
                          ? cs.primary
                          : cs.onSurface.withAlpha(120),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? _formatDisplay(_dueDate!)
                          : 'No due date',
                      style: TextStyle(
                        color: _dueDate != null
                            ? cs.onSurface
                            : cs.onSurface.withAlpha(120),
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: cs.onSurface.withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Priority ───────────────────────────────────────────────────
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

            const SizedBox(height: 40),

            // ── Save ───────────────────────────────────────────────────────
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
