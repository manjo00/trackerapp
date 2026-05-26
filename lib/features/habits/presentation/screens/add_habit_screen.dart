import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/habits_providers.dart';

/// Full-screen form for creating a new habit.
///
/// Pushed from [HabitListScreen]'s FAB via `context.push('/habits/add')`.
/// The bottom navigation bar is hidden while this screen is open because
/// it lives outside the [StatefulShellRoute].
///
/// Uses [ConsumerStatefulWidget] — the stateful variant of [ConsumerWidget].
/// We need stateful here because the form has a [GlobalKey<FormState>] and
/// a [TextEditingController], which are instance-level objects that must
/// persist across rebuilds.
class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  int _targetPerWeek = 7; // default: every day
  bool _saving = false;

  @override
  void dispose() {
    // Always dispose controllers to free memory.
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validate runs each field's validator; returns false if any fail.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    await ref.read(addHabitProvider.notifier).add(
          _nameCtrl.text,
          targetPerWeek: _targetPerWeek,
        );

    // mounted check is necessary after any await — the widget might have
    // been removed from the tree while we were waiting.
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New habit'),
        // Explicit back button so it's always visible.
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
              autofocus: true,
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
                return null; // null means valid
              },
            ),

            const SizedBox(height: 32),

            // ── Target days per week ────────────────────────────────────
            Text(
              'How many days per week?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Seven toggle-buttons, one per day count.
            _DayTargetSelector(
              value: _targetPerWeek,
              onChanged: (int v) => setState(() => _targetPerWeek = v),
            ),

            const SizedBox(height: 40),

            // ── Save button ─────────────────────────────────────────────
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
                  : const Text(
                      'Save habit',
                      style: TextStyle(
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

// ── Day target selector ───────────────────────────────────────────────────

/// Row of 7 circular toggle buttons (1–7 days per week).
///
/// Extracted into its own widget to keep [_AddHabitScreenState.build] readable.
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
