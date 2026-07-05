/// Week-anchoring helpers honouring the user's week-start setting.
///
/// Dart's [DateTime.weekday] is Mon=1 … Sun=7. Everything that needs
/// "the start of this week" or a month grid's leading blanks goes through
/// here so Sunday-start weeks work everywhere at once.
library;

/// Midnight on the first day of the week containing [d].
DateTime startOfWeek(DateTime d, {required bool sundayStart}) {
  final DateTime day = DateTime(d.year, d.month, d.day);
  final int blanks = (day.weekday - (sundayStart ? 7 : 1)) % 7;
  return day.subtract(Duration(days: blanks));
}

/// How many empty cells a month grid needs before day 1.
int monthLeadingBlanks(DateTime firstOfMonth, {required bool sundayStart}) =>
    (firstOfMonth.weekday - (sundayStart ? 7 : 1)) % 7;

/// Single-letter column headers in display order.
List<String> weekdayHeaderLetters({required bool sundayStart}) => sundayStart
    ? const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
    : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
