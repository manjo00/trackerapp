/// Days as 'yyyy-MM-dd' keys, and the *habit day*: the day a moment counts
/// for. The new day starts at 04:00, not midnight, so a tick at 02:30 still
/// counts for the evening before. (The night-shift rule comes in demo 3.)
library;

/// When the habit day starts, in minutes after midnight (04:00).
const int kHabitDayStartMinutes = 240;

String _two(int n) => n.toString().padLeft(2, '0');

/// The calendar date of [d] as 'yyyy-MM-dd'.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// The habit day [moment] belongs to.
String habitDayOf(DateTime moment,
        {int dayStartMinutes = kHabitDayStartMinutes}) =>
    dayKey(moment.subtract(Duration(minutes: dayStartMinutes)));

/// Days are counted in UTC, so a clock change can never skip or repeat one.
DateTime _utc(String day) => DateTime.utc(int.parse(day.substring(0, 4)),
    int.parse(day.substring(5, 7)), int.parse(day.substring(8, 10)));

/// [day] moved by [n] days (negative goes back).
String addDays(String day, int n) => dayKey(_utc(day).add(Duration(days: n)));

/// 1 = Monday … 7 = Sunday, as `DateTime.weekday`.
int weekdayOf(String day) => _utc(day).weekday;

/// The first day of [day]'s week (Sunday or Monday, as the app is set).
String weekStartOf(String day, {required bool weekStartsSunday}) {
  final int weekday = weekdayOf(day);
  return addDays(day, -(weekStartsSunday ? weekday % 7 : weekday - 1));
}
