import 'package:flutter/material.dart';

/// The three priority levels a task can have.
///
/// Stored in SQLite as integers (0, 1, 2) so they can be sorted numerically.
/// Use [TaskPriority.fromInt] when reading from the DB and [.toInt] when writing.
enum TaskPriority {
  low,    // 0
  medium, // 1
  high;   // 2

  /// Converts the SQLite integer back to a [TaskPriority].
  static TaskPriority fromInt(int value) => switch (value) {
        0 => TaskPriority.low,
        2 => TaskPriority.high,
        _ => TaskPriority.medium, // default to medium for unknown values
      };

  /// Converts to the integer stored in SQLite.
  int toInt() => index; // low=0, medium=1, high=2

  /// Human-readable label shown in the UI.
  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Med',
        TaskPriority.high => 'High',
      };

  /// Accent colour for the [PriorityBadge] widget.
  Color get color => switch (this) {
        TaskPriority.low => const Color(0xFF8E9AAF),    // muted slate
        TaskPriority.medium => const Color(0xFFFFB347), // warm amber
        TaskPriority.high => const Color(0xFFE07070),   // soft red
      };
}
