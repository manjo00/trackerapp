import 'package:intl/intl.dart';

/// The result of recognising a "@time" task token at the start of a note line.
///
/// [time] is a 24-hour "HH:mm" string. [date] is a "yyyy-MM-dd" string when the
/// line named a day (e.g. `/17july`), or null when it didn't — the caller then
/// treats "no date" as today. [title] is whatever text followed the token,
/// already trimmed (may be empty).
class ParsedTaskToken {
  const ParsedTaskToken({
    required this.time,
    required this.date,
    required this.title,
  });

  final String time;
  final String? date;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is ParsedTaskToken &&
      other.time == time &&
      other.date == date &&
      other.title == title;

  @override
  int get hashCode => Object.hash(time, date, title);

  @override
  String toString() =>
      'ParsedTaskToken(time: $time, date: $date, title: "$title")';
}

/// Recognises a task "token" at the very start of a note line.
///
/// Grammar (the token must be the first thing on the line):
/// ```
/// @<time>[/<date>] <optional title text>
/// ```
/// - time: 3–4 digits with an optional colon and optional am/pm —
///   `@1250pm`, `@1250`, `@12:50pm`, `@250pm`.
///   If the hour is already ≥ 13 the am/pm is ignored (it's 24-hour already),
///   so `@1450pm` → 14:50; otherwise am/pm applies (`@250pm` → 14:50).
/// - date (optional): `/17july`, `/17jul`, or `/17` (day only ⇒ current month).
/// - title: the remaining text (`@1450pm take sample` → "take sample").
///
/// Returns null when the line isn't a task token, so ordinary prose that merely
/// contains an "@" somewhere is never turned into a task.
class TaskTokenParser {
  const TaskTokenParser._();

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  static final RegExp _tokenRe = RegExp(
    r'^\s*@(\d{1,2}):?(\d{2})\s*(am|pm)?(?:\s*/\s*(\d{1,2})\s*([a-z]{3,9})?)?',
    caseSensitive: false,
  );

  static const Map<String, int> _months = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  /// Parses [line] against the grammar above. [now] supplies the defaults for
  /// the month and year (and is passed in rather than read from the clock so
  /// this stays a pure, unit-testable function).
  static ParsedTaskToken? parse(String line, {required DateTime now}) {
    final RegExpMatch? m = _tokenRe.firstMatch(line);
    if (m == null) return null;

    int hour = int.parse(m.group(1)!);
    final int minute = int.parse(m.group(2)!);
    if (minute > 59) return null;

    final String? ampm = m.group(3)?.toLowerCase();
    if (ampm != null && hour >= 1 && hour <= 12) {
      // am/pm only meaningful for a 1–12 hour; a ≥13 hour is already 24-hour.
      if (ampm == 'pm' && hour != 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
    }
    if (hour > 23) return null;

    final String time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final String? date = _resolveDate(m.group(4), m.group(5), now);

    final String title = line.substring(m.end).trim();

    return ParsedTaskToken(time: time, date: date, title: title);
  }

  /// Builds a "yyyy-MM-dd" string from the optional day + month-name groups,
  /// defaulting the month/year to [now]. Returns null when no day was given or
  /// the day/month is out of range (caller then falls back to today).
  static String? _resolveDate(String? dayStr, String? monthStr, DateTime now) {
    if (dayStr == null) return null;

    final int day = int.parse(dayStr);
    int month = now.month;
    if (monthStr != null) {
      final int? parsed = _months[monthStr.toLowerCase()];
      if (parsed == null) return null; // an unknown month word ⇒ treat as today
      month = parsed;
    }

    final int lastDay = DateTime(now.year, month + 1, 0).day;
    if (day < 1 || day > lastDay) return null;

    return _dateFmt.format(DateTime(now.year, month, day));
  }
}
