import 'package:flutter/material.dart';
import 'shift_month_calendar.dart';

/// Shows a month-calendar bottom sheet for picking a date, with work-shift
/// days shaded (cyan day / navy night) so the user can avoid scheduling on a
/// work day. Returns the picked [DateTime] (date only), or null if dismissed.
///
/// This replaces the stock [showDatePicker], which can't render custom day
/// decorations, while reusing the same [ShiftMonthCalendar] as the schedule
/// screen so the styling stays identical everywhere.
Future<DateTime?> showShiftDatePicker(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShiftDatePickerSheet(initialDate: initialDate),
  );
}

class _ShiftDatePickerSheet extends StatelessWidget {
  const _ShiftDatePickerSheet({this.initialDate});

  final DateTime? initialDate;

  static String? _dateStr(DateTime? d) => d == null
      ? null
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Select due date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ShiftMonthCalendar(
                initialMonth: initialDate,
                selectedDate: _dateStr(initialDate),
                showSummary: false,
                onDaySelected: (String ds) =>
                    Navigator.of(context).pop(DateTime.parse(ds)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
