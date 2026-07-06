import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shifts/data/models/work_shift_model.dart';
import '../../../shifts/presentation/shift_style.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/screens/add_task_screen.dart';
import '../day_grid_layout.dart';

/// 24-hour vertical grid for one day: timed tasks as proportional slabs
/// (priority colour), the work shift shaded behind, a red now-line on
/// today. Tap a slab → edit; long-press empty space → new task at that
/// hour. Untimed tasks live in the "Anytime" strip rendered by the parent.
class DayTimeGrid extends ConsumerWidget {
  const DayTimeGrid({
    required this.dateStr,
    required this.tasks,
    required this.shift,
    super.key,
  });

  final String dateStr; // "yyyy-MM-dd"
  final List<TaskModel> tasks;
  final WorkShiftModel? shift;

  static const double _hourHeight = 64;
  static const double _gutter = 52; // hour-label column width

  bool get _isToday {
    final DateTime now = DateTime.now();
    final String today = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return dateStr == today;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<DayGridItem> items = layoutDayItems(tasks);

    // Open scrolled to the action: now on today, else the first slab,
    // else a sane morning hour.
    final DateTime now = DateTime.now();
    final double anchorMin = _isToday
        ? (now.hour * 60 + now.minute - 60).clamp(0, 1439).toDouble()
        : (items.isNotEmpty ? items.first.startMin.toDouble() : 7 * 60);
    final ScrollController controller = ScrollController(
        initialScrollOffset: anchorMin / 60 * _hourHeight);

    return LayoutBuilder(builder: (context, constraints) {
      final double laneWidth = constraints.maxWidth - _gutter - 8;

      return SingleChildScrollView(
        controller: controller,
        child: SizedBox(
          height: 24 * _hourHeight,
          child: Stack(
            children: [
              // ── Shift shading (behind everything) ────────────────────
              ..._shiftBands(cs),

              // ── Hour lines + labels ──────────────────────────────────
              for (int h = 0; h < 24; h++)
                Positioned(
                  top: h * _hourHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _gutter,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, top: 2),
                          child: Text(
                            '${h.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withAlpha(90),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          height: 1,
                          color: cs.outlineVariant.withAlpha(60),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Long-press target (under the slabs) ──────────────────
              Positioned.fill(
                left: _gutter,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPressStart: (details) {
                    final int hour =
                        (details.localPosition.dy / _hourHeight)
                            .floor()
                            .clamp(0, 23);
                    context.push(
                      '/tasks/add',
                      extra: AddTaskArgs(
                        initialDate: dateStr,
                        initialTime:
                            '${hour.toString().padLeft(2, '0')}:00',
                      ),
                    );
                  },
                ),
              ),

              // ── Task slabs ───────────────────────────────────────────
              for (final DayGridItem item in items)
                Positioned(
                  top: item.startMin / 60 * _hourHeight,
                  left: _gutter +
                      laneWidth * item.column / item.columns,
                  width: laneWidth / item.columns - 3,
                  height: (item.durationMin.clamp(30, 1440)) /
                      60 *
                      _hourHeight,
                  child: _Slab(item: item),
                ),

              // ── Now line (today only) ────────────────────────────────
              if (_isToday)
                Positioned(
                  top: (now.hour * 60 + now.minute) / 60 * _hourHeight,
                  left: _gutter - 4,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                          child: Container(height: 2, color: cs.error)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// Semi-transparent bands over the shift's working hours. Day shift is a
  /// single 07–19 band; night wraps midnight → 19–24 plus 00–07.
  List<Widget> _shiftBands(ColorScheme cs) {
    final WorkShiftModel? s = shift;
    if (s == null) return const [];
    final Color base = ShiftStyle.foreground(s.type).withAlpha(18);

    Widget band(int fromHour, int toHour) => Positioned(
          top: fromHour * _hourHeight,
          left: _gutter,
          right: 0,
          height: (toHour - fromHour) * _hourHeight,
          child: Container(color: base),
        );

    return s.type == ShiftType.day
        ? [band(7, 19)]
        : [band(19, 24), band(0, 7)];
  }
}

class _Slab extends StatelessWidget {
  const _Slab({required this.item});

  final DayGridItem item;

  @override
  Widget build(BuildContext context) {
    final TaskModel task = item.task;
    final Color color = task.priority.color;
    final bool done = task.isCompleted;

    return GestureDetector(
      onTap: () => context.push('/tasks/edit', extra: task),
      child: Container(
        margin: const EdgeInsets.only(right: 2, bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: done ? color.withAlpha(70) : color.withAlpha(170),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(220), width: 1),
        ),
        child: Text(
          task.title,
          maxLines: item.durationMin >= 45 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
