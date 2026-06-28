import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/work_shift_model.dart';
import '../providers/shifts_providers.dart';
import '../shift_style.dart';

/// A reusable month-grid calendar for entering and viewing the work schedule.
///
/// Tapping a day cycles its shift: OFF → Day → Night → OFF (via
/// [ShiftEditor.cycle]). Shift days are filled with the shared [ShiftStyle]
/// colors + icon, so the whole month reads at a glance — exactly the "what
/// days am I free" view.
///
/// It watches [shiftsByDateProvider] (the single source of truth), so any
/// change here also updates the Today tiles and, later, the date-picker.
class ShiftMonthCalendar extends ConsumerStatefulWidget {
  const ShiftMonthCalendar({
    this.onDaySelected,
    this.selectedDate,
    this.initialMonth,
    this.showSummary = true,
    super.key,
  });

  /// When provided, tapping a day calls this with its "yyyy-MM-dd" string
  /// instead of cycling its shift. This is what turns the calendar into a
  /// date-picker (used by [showShiftDatePicker]).
  final void Function(String dateStr)? onDaySelected;

  /// "yyyy-MM-dd" of the day to highlight as selected (picker mode only).
  final String? selectedDate;

  /// The month shown first. Defaults to the current month.
  final DateTime? initialMonth;

  /// Whether to show the working/free count tiles (hidden in the picker).
  final bool showSummary;

  @override
  ConsumerState<ShiftMonthCalendar> createState() =>
      _ShiftMonthCalendarState();
}

class _ShiftMonthCalendarState extends ConsumerState<ShiftMonthCalendar> {
  /// First day (year-month) of the month currently on screen.
  late DateTime _visibleMonth;

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final DateTime base = widget.initialMonth ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month);
  }

  void _prevMonth() => setState(() =>
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));

  void _nextMonth() => setState(() =>
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  void _jumpToToday() {
    final DateTime now = DateTime.now();
    setState(() => _visibleMonth = DateTime(now.year, now.month));
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Map<String, WorkShiftModel> shifts =
        ref.watch(shiftsByDateProvider).valueOrNull ?? const {};

    final DateTime firstOfMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Monday = 1 → 0 leading blanks; Sunday = 7 → 6 leading blanks.
    final int leadingBlanks = firstOfMonth.weekday - 1;

    final DateTime now = DateTime.now();
    final String todayStr = _dateStr(DateTime(now.year, now.month, now.day));
    final bool onCurrentMonth =
        _visibleMonth.year == now.year && _visibleMonth.month == now.month;

    // Working / free counts for the visible month.
    int working = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final String ds =
          _dateStr(DateTime(_visibleMonth.year, _visibleMonth.month, d));
      if (shifts.containsKey(ds)) working++;
    }
    final int free = daysInMonth - working;

    // Build the grid cells: leading blanks, then one cell per day.
    final List<Widget> cells = [];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final DateTime date =
          DateTime(_visibleMonth.year, _visibleMonth.month, d);
      final String ds = _dateStr(date);
      cells.add(_DayCell(
        day: d,
        shift: shifts[ds],
        isToday: ds == todayStr,
        isSelected: widget.selectedDate == ds,
        onTap: () {
          final void Function(String)? onSelect = widget.onDaySelected;
          if (onSelect != null) {
            // Picker mode: report the tapped date.
            onSelect(ds);
          } else {
            // Schedule mode: cycle the shift.
            ref.read(shiftEditorProvider.notifier).cycle(ds);
          }
        },
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header: month nav + legend ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _prevMonth,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_visibleMonth.month]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // ── Legend + "today" jump ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const _LegendChip(
                color: ShiftStyle.dayFill,
                textColor: ShiftStyle.dayForeground,
                label: 'Day',
              ),
              const SizedBox(width: 12),
              const _LegendChip(
                color: ShiftStyle.nightFill,
                textColor: ShiftStyle.nightForeground,
                label: 'Night',
              ),
              const Spacer(),
              if (!onCurrentMonth)
                TextButton(
                  onPressed: _jumpToToday,
                  child: const Text('Today'),
                ),
            ],
          ),
        ),

        // ── Weekday header row ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            d,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        // ── Day grid ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ),

        if (widget.showSummary) ...[
          const SizedBox(height: 12),

          // ── Working / free summary ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CountTile(
                    label: 'Working', value: working, color: cs.primary),
                const SizedBox(width: 12),
                _CountTile(
                    label: 'Free', value: free, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A single tappable day cell. Fills with the shift colour + icon when the day
/// has a shift; today gets a ring.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.shift,
    required this.isToday,
    required this.onTap,
    this.isSelected = false,
  });

  final int day;
  final WorkShiftModel? shift;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasShift = shift != null;
    final Color bg =
        hasShift ? ShiftStyle.fill(shift!.type) : Colors.transparent;
    final Color fg =
        hasShift ? ShiftStyle.foreground(shift!.type) : cs.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: cs.primary, width: 2)
              : isToday
                  ? Border.all(color: cs.primary.withAlpha(120), width: 1.5)
                  : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 6,
              child: Text(
                '$day',
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
            if (hasShift)
              Positioned(
                bottom: 3,
                right: 4,
                child: Icon(
                  ShiftStyle.icon(shift!.type),
                  size: 13,
                  color: ShiftStyle.iconColor(shift!.type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.textColor,
    required this.label,
  });

  final Color color;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
