import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/task_priority.dart';
import '../providers/tasks_providers.dart';

/// A lightweight quick-add half-sheet, opened by the home-screen widget "+".
///
/// Unlike the full [AddTaskScreen], this is a fast capture surface: type a
/// name, optionally toggle Today / cycle priority, hit send. It renders as a
/// bottom card over a dimmed scrim so it feels like an overlay rather than a
/// full screen. Tapping the scrim (or back) dismisses it.
class QuickAddTaskScreen extends ConsumerStatefulWidget {
  const QuickAddTaskScreen({super.key});

  @override
  ConsumerState<QuickAddTaskScreen> createState() => _QuickAddTaskScreenState();
}

class _QuickAddTaskScreenState extends ConsumerState<QuickAddTaskScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _dueToday = false;
  TaskPriority _priority = TaskPriority.medium;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _todayStr() {
    final DateTime n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      // Opened directly from the widget — no in-app history to pop to.
      context.go('/today');
    }
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
          dueDate: _dueToday ? _todayStr() : null,
          priority: _priority,
        );
    if (mounted) _dismiss();
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(120), // dim scrim
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        // Tap outside the card → dismiss.
        onTap: _dismiss,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            // Swallow taps on the card so they don't dismiss.
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
                  // Drag handle
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

                  // Task name (autofocus → keyboard opens immediately)
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

                  // Description (optional)
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

                  // Quick options + send
                  Row(
                    children: [
                      _Chip(
                        icon: Icons.event_rounded,
                        label: _dueToday ? 'Today' : 'No date',
                        active: _dueToday,
                        activeColor: cs.primary,
                        onTap: () => setState(() => _dueToday = !_dueToday),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        icon: Icons.flag_rounded,
                        label: _priority.label,
                        active: true,
                        activeColor: _priority.color,
                        onTap: _cyclePriority,
                      ),
                      const Spacer(),
                      // Send button
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

/// A small toggle/cycle chip used for Today + priority in the quick-add sheet.
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
