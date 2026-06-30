import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shifts/data/models/work_shift_model.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../../shifts/presentation/shift_style.dart';
import '../providers/planner_providers.dart';

/// One column in the week strip — shows the weekday label, date number,
/// habit completion dots, and a task-count badge.
///
/// Tapping selects this day. Long-pressing triggers [onLongPress] (e.g.
/// to add a task pre-filled with this date).
class DayColumn extends ConsumerWidget {
  const DayColumn({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const List<String> _weekdayShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final DotSummary? summary = ref.watch(dayDotSummaryProvider(dateStr));

    // Look up this day's shift (null = free day).
    final Map<String, WorkShiftModel>? shiftMap =
        ref.watch(shiftsByDateProvider).valueOrNull;
    final WorkShiftModel? shift = shiftMap == null ? null : shiftMap[dateStr];

    final bool isFuture = date.isAfter(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );

    // Background + border for selected / today states.
    final Color? bgColor = isSelected
        ? cs.primary.withAlpha(20)
        : null;
    final Color numberColor = isToday
        ? cs.primary
        : isSelected
            ? cs.onSurface
            : cs.onSurface.withAlpha(160);
    final FontWeight numberWeight =
        (isToday || isSelected) ? FontWeight.w700 : FontWeight.w400;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: cs.primary.withAlpha(80), width: 1)
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Weekday label ─────────────────────────────────────────────
            Text(
              _weekdayShort[date.weekday - 1],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withAlpha(120),
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 4),

            // ── Day number (shift-aware) ──────────────────────────────────
            // When the day has a shift, the circle takes the shift fill and a
            // sun/moon badge sits on the corner. ShiftStyle.foreground keeps
            // the number readable in both light and dark themes.
            SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: shift != null
                          ? ShiftStyle.fill(shift.type)
                          : (isToday ? cs.primary : null),
                      // Today + shift: ring marks today over the shift fill.
                      border: (shift != null && isToday)
                          ? Border.all(color: cs.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: numberWeight,
                          color: shift != null
                              ? ShiftStyle.foreground(shift.type)
                              : (isToday ? cs.onPrimary : numberColor),
                        ),
                      ),
                    ),
                  ),
                  if (shift != null)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Icon(
                        ShiftStyle.icon(shift.type),
                        size: 11,
                        color: ShiftStyle.iconColor(shift.type),
                      ),
                    ),
                ],
              ),
            ),

            // ── Rotation label (week view) ────────────────────────────────
            if (shift != null && shift.rotationLabel != null)
              Text(
                shift.rotationLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: shift.rotationColor != null
                      ? Color(shift.rotationColor!)
                      : const Color(0xFFF4511E),
                ),
              ),

            const SizedBox(height: 6),

            // ── Habit dots ────────────────────────────────────────────────
            if (summary != null && summary.habitsTotal > 0)
              _HabitDots(
                total: summary.habitsTotal,
                done: summary.habitsDone,
                isFuture: isFuture,
                color: cs.primary,
              )
            else
              const SizedBox(height: 10),

            const SizedBox(height: 4),

            // ── Task count badge ──────────────────────────────────────────
            if (summary != null && summary.tasksDue > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: summary.tasksCompleted == summary.tasksDue
                      ? cs.primary.withAlpha(30)
                      : const Color(0xFFE07070).withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${summary.tasksDue}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: summary.tasksCompleted == summary.tasksDue
                        ? cs.primary
                        : const Color(0xFFE07070),
                  ),
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ── Habit dot row ─────────────────────────────────────────────────────────────

/// Up to 4 small dots showing habit completion for a day.
/// Green = done, grey = not done.
/// If there are more than 4 habits, the last slot shows "+N".
class _HabitDots extends StatelessWidget {
  const _HabitDots({
    required this.total,
    required this.done,
    required this.isFuture,
    required this.color,
  });

  final int total;
  final int done;
  final bool isFuture;
  final Color color;

  static const int _maxDots = 4;

  @override
  Widget build(BuildContext context) {
    final int shown = total.clamp(0, _maxDots);
    final bool overflow = total > _maxDots;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < shown; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: i == _maxDots - 1 && overflow
                ? _overflowDot(total - (_maxDots - 1))
                : _dot(i < done),
          ),
      ],
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Future days: show pale grey regardless of fill
        color: isFuture
            ? color.withAlpha(30)
            : filled
                ? color
                : color.withAlpha(40),
        border: Border.all(
          color: isFuture ? color.withAlpha(60) : color.withAlpha(100),
          width: 0.8,
        ),
      ),
    );
  }

  Widget _overflowDot(int extra) {
    return SizedBox(
      width: 7,
      height: 7,
      child: Center(
        child: Text(
          '+$extra',
          style: TextStyle(
            fontSize: 5,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
