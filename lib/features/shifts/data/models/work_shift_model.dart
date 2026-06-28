import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_shift_model.freezed.dart';

/// The kind of work shift. Stored in the DB as its [value] string.
///
/// Each type carries its own default start/end times so a shift can be created
/// with sensible hours even before the user knows or cares about exact times.
enum ShiftType {
  day,
  night;

  /// Parses the DB string back into an enum. Unknown values fall back to [day].
  static ShiftType fromString(String s) => switch (s) {
        'night' => ShiftType.night,
        _ => ShiftType.day,
      };

  /// The string persisted in the database ('day' | 'night').
  String get value => name;

  /// Human-readable label for tiles and banners.
  String get label => switch (this) {
        ShiftType.day => 'Day shift',
        ShiftType.night => 'Night shift',
      };

  /// Default start time as "HH:mm" — used when no explicit time is given.
  String get defaultStart => switch (this) {
        ShiftType.day => '07:00',
        ShiftType.night => '19:00',
      };

  /// Default end time as "HH:mm". Night shifts end the next morning.
  String get defaultEnd => switch (this) {
        ShiftType.day => '19:00',
        ShiftType.night => '07:00',
      };
}

/// Immutable domain representation of one work shift on a specific day.
///
/// Produced by [ShiftsRepository] from a raw Drift row. UI works only with
/// this type, never the generated row class.
@freezed
abstract class WorkShiftModel with _$WorkShiftModel {
  const factory WorkShiftModel({
    required int id,

    /// The day this shift falls on, as "yyyy-MM-dd".
    required String date,
    required ShiftType type,

    /// Start time as "HH:mm".
    required String startTime,

    /// End time as "HH:mm".
    required String endTime,
  }) = _WorkShiftModel;
}
