import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/models/habit_model.dart';
import '../providers/habits_providers.dart';

/// Full-screen form for creating OR editing a habit.
///
/// **Create mode** — reached via `context.push('/habits/add')`.
///   Fields are blank. Saves via [addHabitProvider].
///
/// **Edit mode** — reached via `context.push('/habits/edit', extra: habit)`.
///   Fields pre-filled from [habit]. Saves via [updateHabitProvider].
class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({this.habit, super.key});

  /// If non-null, the screen is in edit mode and pre-fills from this model.
  final HabitModel? habit;

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late int _targetPerWeek;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final HabitModel? h = widget.habit;
    if (h != null) {
      // Edit mode — pre-fill from existing habit.
      _nameCtrl = TextEditingController(text: h.name);
      _targetPerWeek = h.targetPerWeek;
      _reminderEnabled = h.reminderEnabled;
      _reminderTime =
          _parseReminderTime(h.reminderTime) ?? const TimeOfDay(hour: 7, minute: 0);
    } else {
      // Create mode — blank form.
      _nameCtrl = TextEditingController();
      _targetPerWeek = 7;
      _reminderEnabled = false;
      _reminderTime = const TimeOfDay(hour: 7, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Reminder helpers ──────────────────────────────────────────────────────

  /// Parses "HH:mm" string to [TimeOfDay]. Returns null on any parse failure.
  static TimeOfDay? _parseReminderTime(String? s) {
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

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final String? reminderTimeStr =
        _reminderEnabled ? _timeStr(_reminderTime) : null;

    if (_isEditing) {
      final HabitModel updated = widget.habit!.copyWith(
        name: _nameCtrl.text.trim(),
        targetPerWeek: _targetPerWeek,
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderTimeStr,
      );
      await ref.read(updateHabitProvider.notifier).save(updated);

      // Apply notification change immediately for the edited habit.
      if (_reminderEnabled) {
        await NotificationService.instance.scheduleHabitReminder(updated);
      } else {
        await NotificationService.instance.cancelHabitReminder(updated.id);
      }
    } else {
      await ref.read(addHabitProvider.notifier).add(
            _nameCtrl.text,
            targetPerWeek: _targetPerWeek,
            reminderEnabled: _reminderEnabled,
            reminderTime: reminderTimeStr,
          );

      // After creation, reschedule all habits so the new one gets its
      // notification (we don't have the new ID yet, so we fetch fresh).
      if (_reminderEnabled) {
        final List<HabitModel> allHabits =
            await ref.read(habitsRepositoryProvider).getAllHabits();
        for (final HabitModel h in allHabits) {
          if (h.reminderEnabled) {
            await NotificationService.instance.scheduleHabitReminder(h);
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
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
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
            // ── Name ─────────────────────────────────────────────────────
            Text(
              'What do you want to track?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Read for 20 minutes',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                if (value.trim().length > 120) {
                  return 'Name must be 120 characters or fewer';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // ── Target days per week ─────────────────────────────────────
            Text(
              'How many days per week?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _DayTargetSelector(
              value: _targetPerWeek,
              onChanged: (int v) => setState(() => _targetPerWeek = v),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 4),

            // ── Reminder ─────────────────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                _reminderEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                color: _reminderEnabled ? cs.primary : cs.onSurfaceVariant,
              ),
              title: const Text('Daily reminder'),
              subtitle: const Text('Get notified at a set time each day'),
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
                    color: cs.primary,
                  ),
                ),
                onTap: _pickTime,
              ),
            ],

            const SizedBox(height: 32),

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
                      _isEditing ? 'Save changes' : 'Save habit',
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

// ── Day target selector ───────────────────────────────────────────────────────

/// Row of 7 circular toggle buttons (1–7 days per week).
class _DayTargetSelector extends StatelessWidget {
  const _DayTargetSelector({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (int i) {
        final int days = i + 1;
        final bool selected = days == value;

        return GestureDetector(
          onTap: () => onChanged(days),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? cs.primary : cs.surfaceContainerHigh,
              border: selected
                  ? null
                  : Border.all(color: cs.outline.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                '$days',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
