import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final HabitModel? h = widget.habit;
    if (h != null) {
      // Edit mode — pre-fill from the existing habit.
      _nameCtrl = TextEditingController(text: h.name);
      _targetPerWeek = h.targetPerWeek;
    } else {
      // Create mode — blank form.
      _nameCtrl = TextEditingController();
      _targetPerWeek = 7; // default: every day
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    if (_isEditing) {
      // Edit mode: update the existing habit.
      await ref.read(updateHabitProvider.notifier).save(
            widget.habit!.copyWith(
              name: _nameCtrl.text.trim(),
              targetPerWeek: _targetPerWeek,
            ),
          );
    } else {
      // Create mode: add a brand-new habit.
      await ref.read(addHabitProvider.notifier).add(
            _nameCtrl.text,
            targetPerWeek: _targetPerWeek,
          );
    }

    if (mounted) context.pop();
  }

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
            // ── Name field ──────────────────────────────────────────────
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

            const SizedBox(height: 40),

            // ── Save button ──────────────────────────────────────────────
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

// ── Day target selector ──────────────────────────────────────────────────────

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
