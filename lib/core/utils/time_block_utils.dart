/// Pure helpers for task time ranges ("time blocking").
///
/// A range is stored as `dueTime` (start, "HH:mm") + `durationMinutes`;
/// the end time is always COMPUTED so rescheduling the start moves the
/// whole block. All parsing is defensive — bad strings yield null, never
/// throw (these run on user-typed and DB data).
library;

/// "14:30" → 870 (minutes since midnight). Null/garbage/out-of-range → null.
int? minutesOfDay(String? hhmm) {
  if (hhmm == null) return null;
  final List<String> parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final int? h = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

String _hhmm(int minutes) {
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Computed end time; clamped to 23:59 — a block never wraps past midnight.
String? endTimeOf(String? dueTime, int? durationMinutes) {
  final int? start = minutesOfDay(dueTime);
  if (start == null || durationMinutes == null) return null;
  final int end = start + durationMinutes;
  return _hhmm(end > 1439 ? 1439 : end);
}

/// Minutes from [start] to [end]; null when [end] isn't strictly after
/// [start] (the editor rejects such picks) or either fails to parse.
int? durationBetween(String start, String end) {
  final int? s = minutesOfDay(start);
  final int? e = minutesOfDay(end);
  if (s == null || e == null || e <= s) return null;
  return e - s;
}

/// "14:00" + 90 → "14:00–15:30" (en dash, matches UI copy).
String formatRange(String start, int durationMinutes) =>
    '$start–${endTimeOf(start, durationMinutes)}';
