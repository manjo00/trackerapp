import 'package:flutter/material.dart';
import '../../../shifts/presentation/widgets/shift_month_calendar.dart';
import '../widgets/day_detail_view.dart';
import '../widgets/week_strip.dart';

/// The Planner tab — a week-strip calendar above a day detail view.
///
/// State:
///   [_selectedDate] — which day the user has tapped (defaults to today).
///
/// The week strip shows 7 day columns (Mon–Sun) with habit-completion dots
/// and task-count badges. Swiping or tapping the arrows moves between weeks.
/// Tapping a day column updates [_selectedDate] and the detail view below.
/// Long-pressing a day column opens AddTaskScreen pre-filled with that date.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _selectedDate;

  /// Whether the calendar shows a full month (true) or the week strip (false).
  bool _monthView = false;

  @override
  void initState() {
    super.initState();
    // Default to today (date only, no time component).
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _selectedDateLabel {
    const List<String> weekdays = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const List<String> months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final DateTime today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final int diff = _selectedDate.difference(today).inDays;

    final String dayName = switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => weekdays[_selectedDate.weekday],
    };
    return '$dayName, ${months[_selectedDate.month]} ${_selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Week / Month toggle ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<bool>(
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_week_rounded, size: 16),
                  label: Text('Week'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.calendar_view_month_rounded, size: 16),
                  label: Text('Month'),
                ),
              ],
              selected: {_monthView},
              onSelectionChanged: (Set<bool> s) =>
                  setState(() => _monthView = s.first),
            ),
          ),

          // ── Calendar: week strip or month grid ──────────────────────────
          if (_monthView)
            ShiftMonthCalendar(
              initialMonth: _selectedDate,
              selectedDate: _dateStr(_selectedDate),
              showSummary: false,
              onDaySelected: (String ds) =>
                  setState(() => _selectedDate = DateTime.parse(ds)),
            )
          else
            WeekStrip(
              selectedDate: _selectedDate,
              onDateSelected: (DateTime d) =>
                  setState(() => _selectedDate = d),
            ),

          // ── Selected day label ──────────────────────────────────────────
          Container(
            color: cs.surfaceContainerLow,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              _selectedDateLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
            ),
          ),

          const Divider(height: 1),

          // ── Day detail ──────────────────────────────────────────────────
          Expanded(
            child: DayDetailView(selectedDate: _selectedDate),
          ),
        ],
      ),
    );
  }
}
