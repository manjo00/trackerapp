/// A task's reminders, as minutes before its due time: any of the three
/// standard ones plus one custom amount. They are stored as text in
/// `tasks.reminderLeadTimes`, e.g. "1440,180,30".
library;

/// The standard reminders in the order they are shown: 1 day, 3 hours and
/// 5 minutes before.
const List<int> kPresetLeadMinutes = <int>[1440, 180, 5];

/// The longest custom reminder: 30 days before the due time.
const int kMaxLeadMinutes = 30 * 1440;

/// Splits a task's reminder minutes into the standard ones it uses and its
/// custom amount (the first value that isn't standard), if any.
({Set<int> presets, int? custom}) splitLeadTimes(List<int> leads) {
  final Set<int> presets = <int>{};
  int? custom;
  for (final int minutes in leads) {
    if (kPresetLeadMinutes.contains(minutes)) {
      presets.add(minutes);
    } else {
      custom ??= minutes;
    }
  }
  return (presets: presets, custom: custom);
}

/// The stored text for a task's reminders: the standard ones in display order,
/// then the custom amount, which counts once if it equals a standard one.
/// Null when no reminder is chosen.
String? leadTimesCsv(Set<int> presets, int? custom) {
  final List<int> leads = <int>[
    for (final int minutes in kPresetLeadMinutes)
      if (presets.contains(minutes)) minutes,
    if (custom != null && !presets.contains(custom)) custom,
  ];
  return leads.isEmpty ? null : leads.join(',');
}

/// A chip's short label, in the largest unit that fits exactly: "1 day",
/// "3 h", "90 min".
String leadChipLabel(int minutes) {
  if (minutes % 1440 == 0) {
    final int days = minutes ~/ 1440;
    return '$days day${days == 1 ? '' : 's'}';
  }
  if (minutes % 60 == 0) return '${minutes ~/ 60} h';
  return '$minutes min';
}

/// The amount in words, never rounded: "1 day", "36 hours", "90 minutes".
String leadAmount(int minutes) {
  if (minutes % 1440 == 0) return _plural(minutes ~/ 1440, 'day');
  if (minutes % 60 == 0) return _plural(minutes ~/ 60, 'hour');
  return _plural(minutes, 'minute');
}

String _plural(int count, String unit) => '$count $unit${count == 1 ? '' : 's'}';
