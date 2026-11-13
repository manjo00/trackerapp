import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../archive/presentation/archive_providers.dart';
import '../../data/models/habit_model.dart';
import '../../domain/habit_rules.dart';
import '../../domain/habit_stats.dart';
import '../../domain/habit_types.dart';
import '../models/habit_day_view.dart';
import '../models/habit_units.dart';
import '../providers/habits_providers.dart';
import 'habit_palette.dart';

/// One habit in Look A: its icon, its name, one line of facts (the cue, the
/// streak, spare days or this week's count) and a round tick on the right.
/// A count habit gets a + and a thin progress line instead.
///
/// Tap or long-press opens the editor (the habit's own page comes in demo 2);
/// swipe left archives it, with Undo.
///
/// The row shows [HabitDayView.day] (a past day picked in the week strip) or
/// today, and its round button, + and typed amount act on that day.
class HabitRow extends ConsumerWidget {
  const HabitRow({required this.view, this.reason, super.key});

  final HabitDayView view;

  /// Replaces the facts line, e.g. "Done for the week" under Not due today.
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HabitModel habit = view.habit;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final HabitColorSet colors = HabitColors.of(context, habit.color);
    final bool done = view.state == DayState.kept;
    final bool count = habit.kind == HabitKind.count;

    return Dismissible(
      key: ValueKey('habit-row-${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.archive_rounded, color: cs.onTertiaryContainer),
      ),
      onDismissed: (_) => _archive(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Material(
          color: done ? cs.surface : cs.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: done
                ? BorderSide(color: cs.outlineVariant)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => context.push('/habits/edit', extra: habit),
            onLongPress: () => context.push('/habits/edit', extra: habit),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.container,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(habitIcon(habit.icon),
                            size: 22, color: colors.onContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: done
                                        ? cs.onSurfaceVariant
                                        : cs.onSurface,
                                  ),
                            ),
                            _FactsLine(view: view, reason: reason),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (count && !done)
                        _AddButton(view: view)
                      else
                        _TickButton(view: view, solid: colors.solid),
                    ],
                  ),
                ),
                if (count)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (view.value / habit.goal).clamp(0, 1),
                        child: Container(height: 3, color: colors.solid),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final svc = ref.read(archiveServiceProvider);
    await svc.archiveHabit(view.habit.id, DateTime.now());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${view.habit.name}" archived'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => svc.restoreHabit(view.habit.id),
          ),
        ),
      );
    }
  }
}

/// "After dinner · 🔥 6 days · 1 spare left", or a reason when one is given.
class _FactsLine extends StatelessWidget {
  const _FactsLine({required this.view, this.reason});

  final HabitDayView view;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle? style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: cs.onSurfaceVariant);
    final List<InlineSpan> parts = [];
    void add(InlineSpan span) {
      if (parts.isNotEmpty) parts.add(const TextSpan(text: ' · '));
      parts.add(span);
    }

    final HabitModel habit = view.habit;
    final HabitSummary s = view.summary;
    if (reason != null) add(TextSpan(text: reason));
    final String? cue = habit.cue?.trim();
    if (reason == null && cue != null && cue.isNotEmpty) add(TextSpan(text: cue));
    if (reason == null && habit.schedule == HabitSchedule.perWeek) {
      add(TextSpan(text: '${s.weekCount} of ${habit.perWeek ?? 1} this week'));
    }
    if (reason == null && habit.kind == HabitKind.count) {
      final String unit = habit.unit?.trim() ?? '';
      add(TextSpan(
          text: '${formatAmount(view.value)} of ${formatAmount(habit.goal)}'
              '${unit.isEmpty ? '' : ' $unit'}'));
    }
    if (reason == null && s.streak > 0) {
      final String unit = s.streakUnit == StreakUnit.weeks
          ? (s.streak == 1 ? 'week' : 'weeks')
          : (s.streak == 1 ? 'day' : 'days');
      add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(Icons.local_fire_department_rounded,
            size: 14, color: Colors.amber.shade700),
      ));
      parts.add(TextSpan(text: ' ${s.streak} $unit'));
    }
    if (reason == null &&
        habit.sparesPerWeek > 0 &&
        habit.schedule != HabitSchedule.perWeek) {
      add(TextSpan(
          text: switch (s.sparesLeft) {
        0 => 'No spares left this week',
        1 => '1 spare left',
        final int n => '$n spares left',
      }));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text.rich(TextSpan(style: style, children: parts));
  }
}

/// The round tick: an outline when open, filled in the habit's colour when
/// done. For a done count it takes one step back off.
class _TickButton extends ConsumerWidget {
  const _TickButton({required this.view, required this.solid});

  final HabitDayView view;
  final Color solid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool done = view.state == DayState.kept;
    final HabitModel habit = view.habit;
    void onTap() {
      final HabitActions actions = ref.read(habitActionsProvider);
      if (habit.kind == HabitKind.count && done) {
        actions.addAmount(habit.id, -habit.step, day: view.day);
      } else {
        actions.tick(habit.id, day: view.day);
      }
    }

    // Its own node, so a screen reader offers "Tick Read 20 min" apart from
    // the row (which opens the editor).
    return Semantics(
      container: true,
      button: true,
      label: done ? 'Untick ${habit.name}' : 'Tick ${habit.name}',
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        radius: 26,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? solid : Colors.transparent,
            border: Border.all(color: done ? solid : cs.outline, width: 2),
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 24, color: cs.surface)
              : null,
        ),
      ),
    );
  }
}

/// A count habit's +: adds its step; a long-press asks for an amount.
class _AddButton extends ConsumerWidget {
  const _AddButton({required this.view});

  final HabitDayView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HabitModel habit = view.habit;
    final String unit = habit.unit?.trim() ?? '';
    // The button's own long-press: around it, a GestureDetector lost the
    // press to the tooltip, which then showed instead of the amount box.
    return IconButton.filledTonal(
      tooltip: 'Add ${formatAmount(habit.step)}'
          '${unit.isEmpty ? '' : ' $unit'}',
      icon: const Icon(Icons.add_rounded),
      onPressed: () => ref
          .read(habitActionsProvider)
          .addAmount(habit.id, habit.step, day: view.day),
      onLongPress: () => _typeAmount(context, ref),
    );
  }

  Future<void> _typeAmount(BuildContext context, WidgetRef ref) {
    // Read once here: the row may be rebuilt while the box is open.
    final HabitActions actions = ref.read(habitActionsProvider);
    final String day = view.day ?? ref.read(habitTodayProvider);
    return showDialog<void>(
      context: context,
      builder: (_) => _AmountDialog(
        initial: view.value,
        unit: view.habit.unit,
        onSave: (String typed) => actions.setAmount(view.habit.id, day, typed),
      ),
    );
  }
}

/// "Amount" with a number box. Its own widget, so the box's controller is
/// thrown away only once the dialog has fully closed (disposing it right
/// after `showDialog` returned broke the closing animation).
class _AmountDialog extends StatefulWidget {
  const _AmountDialog(
      {required this.initial, required this.unit, required this.onSave});

  final int initial;
  final String? unit;

  /// Saves what was typed; false when it isn't a number from 0 to the limit.
  final Future<bool> Function(String typed) onSave;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bool saved = await widget.onSave(_controller.text);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error =
          'Type a number from 0 to ${formatAmount(kMaxHabitAmount)}');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Amount'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: widget.unit,
            errorText: _error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}
