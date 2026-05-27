import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_model.freezed.dart';

/// The two logging modes a tracker can operate in.
enum TrackerType {
  /// A fixed set of items checked off once per day.
  /// Examples: prayers, medications, study chapters, water glasses.
  dailyChecklist,

  /// Open-ended rows with named fields logged per session.
  /// Example: gym (exercise + sets + reps + weight).
  sessionLog;

  static TrackerType fromString(String s) =>
      s == 'session_log' ? sessionLog : dailyChecklist;

  String get value =>
      this == sessionLog ? 'session_log' : 'daily_checklist';
}

/// Immutable domain object representing one user-created tracker.
@freezed
abstract class TrackerModel with _$TrackerModel {
  const factory TrackerModel({
    required int id,
    required String name,
    String? description,
    required TrackerType type,
    required String icon,
    required int colorValue,
    required DateTime createdAt,
    /// Whether a daily reminder notification is enabled for this tracker.
    @Default(false) bool reminderEnabled,
    /// Reminder time as "HH:mm", e.g. "20:00". Null = not configured.
    String? reminderTime,
    /// When true this row is a saved template, not an active tracker.
    @Default(false) bool isTemplate,
  }) = _TrackerModel;
}
