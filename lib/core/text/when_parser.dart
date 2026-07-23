import 'package:intl/intl.dart';

/// A date/time expression recognised inside free text, with the character span
/// it occupied (so a caller can strip it from a task title).
class ParsedWhen {
  const ParsedWhen({
    this.time,
    this.date,
    required this.start,
    required this.end,
  });

  /// "HH:mm" (24-hour) or null when only a date was found.
  final String? time;

  /// "yyyy-MM-dd" or null when only a time was found.
  final String? date;

  /// Inclusive/exclusive char range of the matched expression in the source.
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is ParsedWhen &&
      other.time == time &&
      other.date == date &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(time, date, start, end);

  @override
  String toString() => 'ParsedWhen(time: $time, date: $date, [$start,$end))';
}

/// A recognised task token at the very start of a note line: time (required),
/// an optional date, and the trailing title text.
class NoteWhen {
  const NoteWhen({required this.time, this.date, required this.title});

  final String time; // "HH:mm"
  final String? date; // "yyyy-MM-dd" or null ⇒ today
  final String title;

  @override
  bool operator ==(Object other) =>
      other is NoteWhen &&
      other.time == time &&
      other.date == date &&
      other.title == title;

  @override
  int get hashCode => Object.hash(time, date, title);

  @override
  String toString() => 'NoteWhen(time: $time, date: $date, title: "$title")';
}

/// One recognised fragment (time or date) and where it sat in the text.
class _Span {
  const _Span(this.value, this.start, this.end);
  final String value;
  final int start;
  final int end;
}

/// Recognises Todoist-style date/time phrases in free text.
///
/// It is deliberately *precise, not greedy*: a bare number ("bed 7", "35 flow")
/// is never a date — a date needs a month word, an ordinal ("12th"), a relative
/// word ("today"), or a `12jul`-style joined form. A time needs a disambiguator:
/// a leading `@` / `at`, a colon (`12:50`), or an am/pm (`5pm`). This keeps
/// clinical shorthand from being mistaken for a due date.
///
/// [now] is injected (not read from the clock) so the whole parser is pure and
/// unit-testable.
class WhenParser {
  WhenParser._();

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

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

  // ── Time patterns (each needs a disambiguator) ──────────────────────────
  // @1250 / @12:50 / @1250pm / at 1250 / at 12:50pm  (3–4 digit or colon form)
  static final RegExp _timeAtRe = RegExp(
      r'(?:@|\bat\b)\s*(\d{1,2}):?(\d{2})\s*(am|pm)?',
      caseSensitive: false);
  // 12:50 / 12:50pm  (colon makes it unambiguous)
  static final RegExp _timeColonRe =
      RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false);
  // 5pm / 12 pm  (am/pm makes it unambiguous)
  static final RegExp _timeAmpmRe =
      RegExp(r'\b(\d{1,2})\s*(am|pm)\b', caseSensitive: false);

  // ── Date patterns (month words validated after the match) ───────────────
  static final RegExp _dayMonthRe =
      RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]{3,9})\b', caseSensitive: false);
  static final RegExp _monthDayRe =
      RegExp(r'\b([a-z]{3,9})\s+(\d{1,2})(?:st|nd|rd|th)?\b', caseSensitive: false);
  static final RegExp _dayMonthTightRe =
      RegExp(r'\b(\d{1,2})([a-z]{3,9})\b', caseSensitive: false);
  static final RegExp _dayOrdinalRe =
      RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)\b', caseSensitive: false);
  static final RegExp _relativeRe =
      RegExp(r'\b(today|tonight|tomorrow|tmrw)\b', caseSensitive: false);

  // ── Public API ───────────────────────────────────────────────────────────

  /// Finds the first date/time phrase anywhere in [text] (task creation). Time
  /// and date are merged when they sit next to each other (e.g. "at 12:50pm
  /// july 12"); returns null when nothing recognisable is present.
  static ParsedWhen? parseTaskText(String text, {required DateTime now}) {
    final _Span? t = _findTime(text);
    final _Span? d = _findDate(text, now);
    if (t == null && d == null) return null;

    if (t != null && d != null) {
      if (_adjacent(t, d)) {
        return ParsedWhen(
          time: t.value,
          date: d.value,
          start: t.start < d.start ? t.start : d.start,
          end: t.end > d.end ? t.end : d.end,
        );
      }
      // Not adjacent — keep the earlier one only (rare; documented).
      return t.start <= d.start
          ? ParsedWhen(time: t.value, start: t.start, end: t.end)
          : ParsedWhen(date: d.value, start: d.start, end: d.end);
    }
    if (t != null) return ParsedWhen(time: t.value, start: t.start, end: t.end);
    return ParsedWhen(date: d!.value, start: d.start, end: d.end);
  }

  /// Removes a matched [when] from [text] and tidies the surrounding spaces —
  /// the title the user is left with after a token is recognised.
  static String stripFrom(String text, ParsedWhen when) {
    // Also drop a connector word left dangling before the removed token, so
    // "call mom at 5pm" → "call mom", not "call mom at".
    final String left = text.substring(0, when.start).replaceFirst(
        RegExp(r'\s+(at|on|by|due|for)\s*$', caseSensitive: false), '');
    final String out = left + text.substring(when.end);
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  /// Recognises a task token at the very START of a note line (checkbox lines).
  /// The line must begin with `@time` or `at time`; anything else returns null,
  /// so ordinary prose never becomes a task. An optional date may follow the
  /// time (`@1250pm july 12`, `@1450pm/17july`); the rest is the title.
  static NoteWhen? parseNoteLine(String line, {required DateTime now}) {
    final RegExpMatch? tm = RegExp(
      r'^\s*(?:@|at\s+)(\d{1,2}):?(\d{2})\s*(am|pm)?',
      caseSensitive: false,
    ).firstMatch(line);
    if (tm == null) return null;

    final String? time =
        _time(int.parse(tm.group(1)!), int.parse(tm.group(2)!), tm.group(3));
    if (time == null) return null;

    // Optional date immediately after the time (allowing a leading '/').
    String rest = line.substring(tm.end);
    String? date;
    final RegExpMatch sep = RegExp(r'^\s*/?\s*').firstMatch(rest)!;
    final String afterSep = rest.substring(sep.end);
    final _Span? d = _dateAtStart(afterSep, now);
    if (d != null) {
      date = d.value;
      rest = afterSep.substring(d.end);
    }

    return NoteWhen(time: time, date: date, title: rest.trim());
  }

  // ── Time helpers ─────────────────────────────────────────────────────────

  static _Span? _findTime(String text) {
    _Span? best;
    void keep(String? value, int start, int end) {
      if (value == null) return;
      if (best == null ||
          start < best!.start ||
          (start == best!.start && end > best!.end)) {
        best = _Span(value, start, end);
      }
    }

    for (final m in _timeAtRe.allMatches(text)) {
      keep(_time(int.parse(m.group(1)!), int.parse(m.group(2)!), m.group(3)),
          m.start, m.end);
    }
    for (final m in _timeColonRe.allMatches(text)) {
      keep(_time(int.parse(m.group(1)!), int.parse(m.group(2)!), m.group(3)),
          m.start, m.end);
    }
    for (final m in _timeAmpmRe.allMatches(text)) {
      keep(_time(int.parse(m.group(1)!), 0, m.group(2)), m.start, m.end);
    }
    return best;
  }

  /// Normalises an (hour, minute, am/pm) triple to "HH:mm", or null if invalid.
  /// An hour already ≥ 13 is treated as 24-hour and ignores am/pm.
  static String? _time(int hour, int minute, String? ampmRaw) {
    if (minute > 59) return null;
    final String? ampm = ampmRaw?.toLowerCase();
    if (ampm != null && hour >= 1 && hour <= 12) {
      if (ampm == 'pm' && hour != 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
    }
    if (hour > 23) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // ── Date helpers ─────────────────────────────────────────────────────────

  static _Span? _findDate(String text, DateTime now) {
    _Span? best;
    void keep(String? value, int start, int end) {
      if (value == null) return;
      if (best == null ||
          start < best!.start ||
          (start == best!.start && end > best!.end)) {
        best = _Span(value, start, end);
      }
    }

    for (final m in _dayMonthRe.allMatches(text)) {
      final int? mo = _months[m.group(2)!.toLowerCase()];
      if (mo != null) keep(_date(int.parse(m.group(1)!), mo, now), m.start, m.end);
    }
    for (final m in _monthDayRe.allMatches(text)) {
      final int? mo = _months[m.group(1)!.toLowerCase()];
      if (mo != null) keep(_date(int.parse(m.group(2)!), mo, now), m.start, m.end);
    }
    for (final m in _dayMonthTightRe.allMatches(text)) {
      final int? mo = _months[m.group(2)!.toLowerCase()];
      if (mo != null) keep(_date(int.parse(m.group(1)!), mo, now), m.start, m.end);
    }
    for (final m in _dayOrdinalRe.allMatches(text)) {
      keep(_date(int.parse(m.group(1)!), now.month, now), m.start, m.end);
    }
    for (final m in _relativeRe.allMatches(text)) {
      final String w = m.group(1)!.toLowerCase();
      final DateTime day = (w == 'tomorrow' || w == 'tmrw')
          ? now.add(const Duration(days: 1))
          : now;
      keep(_fmt.format(DateTime(day.year, day.month, day.day)), m.start, m.end);
    }
    return best;
  }

  /// A date that begins at index 0 of [text] (used for the note line's optional
  /// trailing date, so we never grab a number from the middle of a title).
  static _Span? _dateAtStart(String text, DateTime now) {
    final _Span? d = _findDate(text, now);
    if (d == null || d.start != 0) return null;
    return d;
  }

  /// Builds "yyyy-MM-dd" from a day + month for [now]'s year; null if the day is
  /// out of range for that month.
  static String? _date(int day, int month, DateTime now) {
    if (month < 1 || month > 12) return null;
    final int lastDay = DateTime(now.year, month + 1, 0).day;
    if (day < 1 || day > lastDay) return null;
    return _fmt.format(DateTime(now.year, month, day));
  }

  /// Whether a time span and a date span sit next to each other (only spaces or
  /// a short connector between them), so they describe one "when".
  static bool _adjacent(_Span a, _Span b) {
    final int gap = a.end <= b.start ? b.start - a.end : a.start - b.end;
    return gap >= 0 && gap <= 4;
  }
}
