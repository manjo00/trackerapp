import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/utils/week_utils.dart';
import 'day_column.dart';

/// Horizontal week navigator shown at the top of [PlannerScreen].
///
/// Displays 7 [DayColumn] widgets for the current week (first day per the
/// week-start setting). Previous/next week buttons and a swipe gesture move
/// between weeks. A "Today" chip appears when the displayed week is not the
/// current week.
class WeekStrip extends ConsumerStatefulWidget {
  const WeekStrip({
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });

  /// The currently selected date — used to highlight the active column.
  final DateTime selectedDate;

  /// Called when the user taps a different day column.
  final ValueChanged<DateTime> onDateSelected;

  @override
  ConsumerState<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends ConsumerState<WeekStrip> {
  /// The first day of the currently displayed week.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOf(widget.selectedDate);
  }

  // ── Date helpers ────────────────────────────────────────────────────────

  DateTime _startOf(DateTime d) => startOfWeek(d,
      sundayStart: ref.read(settingsProvider).weekStartsSunday);

  static DateTime _todayDate() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isCurrentWeek => _weekStart == _startOf(_todayDate());

  void _prevWeek() => setState(
        () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
      );

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  void _jumpToToday() {
    final DateTime today = _todayDate();
    setState(() => _weekStart = _startOf(today));
    widget.onDateSelected(today);
  }

  String _monthLabel() {
    const List<String> months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final DateTime last = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == last.month) {
      return '${months[_weekStart.month]} ${_weekStart.year}';
    }
    // week spans two months
    return '${months[_weekStart.month]} / ${months[last.month]} ${last.year}';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = _todayDate();

    return GestureDetector(
      // Swipe left → next week, swipe right → prev week.
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -200) _nextWeek();
        if (details.primaryVelocity! > 200) _prevWeek();
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Month header + nav arrows ──────────────────────────────
            Row(
              children: [
                // Previous week
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  onPressed: _prevWeek,
                ),

                // Month / year label
                Expanded(
                  child: Text(
                    _monthLabel(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ),

                // "Today" chip — only visible when not on the current week.
                AnimatedOpacity(
                  opacity: _isCurrentWeek ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _isCurrentWeek ? null : _jumpToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: cs.primary.withAlpha(80)),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Next week
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  onPressed: _nextWeek,
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Day columns ────────────────────────────────────────────
            Row(
              children: List.generate(7, (int i) {
                final DateTime day =
                    _weekStart.add(Duration(days: i));
                final bool isSelected = day == DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                );
                final bool isToday = day == today;

                final String dateStr =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

                return Expanded(
                  child: DayColumn(
                    date: day,
                    isSelected: isSelected,
                    isToday: isToday,
                    onTap: () => widget.onDateSelected(day),
                    // Long-press: open add-task screen pre-filled with this date.
                    onLongPress: () =>
                        context.push('/tasks/add', extra: dateStr),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
