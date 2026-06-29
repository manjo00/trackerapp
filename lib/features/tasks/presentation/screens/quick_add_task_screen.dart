import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shifts/data/models/work_shift_model.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../../shifts/presentation/shift_style.dart';
import '../../../shifts/presentation/widgets/shift_date_picker_sheet.dart';
import '../../data/models/task_priority.dart';
import '../providers/tasks_providers.dart';

/// A lightweight quick-add half-sheet, opened by the home-screen widget "+".
///
/// Fast capture over a see-through scrim: type a name, pick an exact date
/// (shift-aware — work days are shaded) and time, set priority, send.
/// Dismissing or saving closes the activity so you return to the home screen.
class QuickAddTaskScreen extends ConsumerStatefulWidget {
  const QuickAddTaskScreen({super.key});

  @override
  ConsumerState<QuickAddTaskScreen> createState() => _QuickAddTaskScreenState();
}

class _QuickAddTaskScreenState extends ConsumerState<QuickAddTaskScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  bool _saving = false;

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${d.day} ${_months[d.month]}';
  }

  /// Closes the whole activity → returns to the home screen (the widget's
  /// launch context), rather than dropping the user into the app.
  void _dismiss() {
    SystemNavigator.pop();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime? picked =
        await showShiftDatePicker(context, initialDate: _dueDate);
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _cyclePriority() {
    setState(() {
      _priority = switch (_priority) {
        TaskPriority.low => TaskPriority.medium,
        TaskPriority.medium => TaskPriority.high,
        TaskPriority.high => TaskPriority.low,
      };
    });
  }

  Future<void> _save() async {
    final String title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _dismiss();
      return;
    }
    setState(() => _saving = true);
    await ref.read(addTaskProvider.notifier).add(
          title,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          dueDate: _dueDate != null ? _dateStr(_dueDate!) : null,
          dueTime: _dueTime != null
              ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
              : null,
          priority: _priority,
        );
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    // Shift for the chosen date — lets us show working / rest right on the chip.
    final WorkShiftModel? shift = _dueDate == null
        ? null
        : ref.watch(shiftsByDateProvider).valueOrNull?[_dateStr(_dueDate!)];

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(120),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _dismiss,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withAlpha(40),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Task name',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  TextField(
                    controller: _noteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Chips row — scrolls if it gets crowded.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Date (shift-aware: colour + icon when it's a shift day)
                        _Chip(
                          icon: shift != null
                              ? ShiftStyle.icon(shift.type)
                              : Icons.event_rounded,
                          label: _dueDate == null
                              ? 'No date'
                              : (shift != null
                                  ? '${_dateLabel(_dueDate!)} · ${shift.type.label}'
                                  : _dateLabel(_dueDate!)),
                          active: _dueDate != null,
                          activeColor: shift != null
                              ? ShiftStyle.foreground(shift.type)
                              : cs.primary,
                          onTap: _pickDate,
                        ),
                        const SizedBox(width: 8),
                        // Time
                        _Chip(
                          icon: Icons.access_time_rounded,
                          label: _dueTime == null
                              ? 'No time'
                              : _dueTime!.format(context),
                          active: _dueTime != null,
                          activeColor: cs.primary,
                          onTap: _pickTime,
                        ),
                        const SizedBox(width: 8),
                        // Priority
                        _Chip(
                          icon: Icons.flag_rounded,
                          label: _priority.label,
                          active: true,
                          activeColor: _priority.color,
                          onTap: _cyclePriority,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (shift != null && _dueDate != null)
                        Expanded(
                          child: Text(
                            'Heads up: ${shift.type.label.toLowerCase()} that day',
                            style: TextStyle(
                              fontSize: 12,
                              color: ShiftStyle.foreground(shift.type),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Material(
                        color: cs.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _saving ? null : _save,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _saving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : Icon(Icons.arrow_upward_rounded,
                                    color: cs.onPrimary, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = active ? activeColor : cs.onSurface.withAlpha(150);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor : cs.outline.withAlpha(120),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: fg)),
          ],
        ),
      ),
    );
  }
}
