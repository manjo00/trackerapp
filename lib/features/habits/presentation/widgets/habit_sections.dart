import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/habit_rules.dart';
import '../../domain/habit_types.dart';
import '../models/habit_day_view.dart';
import 'habit_row.dart';

/// Look A's list: what is left today, by part of the day, then two folds,
/// "Done today" and "Not due today". A habit just ticked stays in its section
/// for a moment, then folds away.
class HabitSections extends StatefulWidget {
  const HabitSections({required this.views, super.key});

  final List<HabitDayView> views;

  /// How long a just-ticked habit stays in its section before it folds.
  static const Duration linger = Duration(milliseconds: 400);

  @override
  State<HabitSections> createState() => _HabitSectionsState();
}

class _HabitSectionsState extends State<HabitSections> {
  final Map<int, Timer> _lingering = {};
  bool _doneOpen = false;
  bool _notDueOpen = false;

  static const Map<HabitSection, String> _labels = {
    HabitSection.wake: 'Wake-up',
    HabitSection.any: 'Any time',
    HabitSection.day: 'Daytime',
    HabitSection.sleep: 'Before sleep',
  };

  static bool _isKept(HabitDayView v) => v.summary.today == DayState.kept;

  static bool _isOpen(HabitDayView v) =>
      v.summary.today == DayState.pending ||
      v.summary.today == DayState.partial;

  @override
  void didUpdateWidget(HabitSections old) {
    super.didUpdateWidget(old);
    final Set<int> wasKept = {
      for (final HabitDayView v in old.views)
        if (_isKept(v)) v.habit.id,
    };
    for (final HabitDayView v in widget.views) {
      final int id = v.habit.id;
      if (_isKept(v) && !wasKept.contains(id)) {
        _lingering[id]?.cancel();
        _lingering[id] = Timer(HabitSections.linger, () {
          if (mounted) setState(() => _lingering.remove(id));
        });
      }
    }
  }

  @override
  void dispose() {
    for (final Timer t in _lingering.values) {
      t.cancel();
    }
    super.dispose();
  }

  String _reason(HabitDayView v) => switch (v.summary.today) {
        DayState.away => 'Away',
        DayState.rest => 'Rest day',
        DayState.sick => 'Sick day',
        _ when v.habit.schedule == HabitSchedule.perWeek => 'Done for the week',
        _ => 'Not today',
      };

  @override
  Widget build(BuildContext context) {
    final List<HabitDayView> views = widget.views;
    final List<HabitDayView> done = [
      for (final HabitDayView v in views)
        if (_isKept(v) && !_lingering.containsKey(v.habit.id)) v,
    ];
    final List<HabitDayView> notDue = [
      for (final HabitDayView v in views)
        if (const {DayState.notDue, DayState.away, DayState.rest, DayState.sick}
            .contains(v.summary.today))
          v,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final HabitSection section in HabitSection.values)
          ..._section(
            context,
            _labels[section]!,
            [
              for (final HabitDayView v in views)
                if (v.habit.section == section &&
                    (_isOpen(v) || _lingering.containsKey(v.habit.id)))
                  v,
            ],
          ),
        if (done.isNotEmpty) ...[
          _Fold(
            label: 'Done today · ${done.length}',
            open: _doneOpen,
            onTap: () => setState(() => _doneOpen = !_doneOpen),
          ),
          if (_doneOpen)
            for (final HabitDayView v in done)
              HabitRow(key: ValueKey('done-${v.habit.id}'), view: v),
        ],
        if (notDue.isNotEmpty) ...[
          _Fold(
            label: 'Not due today · ${notDue.length}',
            open: _notDueOpen,
            onTap: () => setState(() => _notDueOpen = !_notDueOpen),
          ),
          if (_notDueOpen)
            for (final HabitDayView v in notDue)
              HabitRow(
                  key: ValueKey('notdue-${v.habit.id}'),
                  view: v,
                  reason: _reason(v)),
        ],
      ],
    );
  }

  List<Widget> _section(
      BuildContext context, String label, List<HabitDayView> rows) {
    if (rows.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
        child: Text(
          label.toUpperCase(),
          semanticsLabel: label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
      for (final HabitDayView v in rows)
        HabitRow(key: ValueKey('open-${v.habit.id}'), view: v),
    ];
  }
}

/// A collapsible line: "Done today · 2" with a turning chevron.
class _Fold extends StatelessWidget {
  const _Fold({required this.label, required this.open, required this.onTap});

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
