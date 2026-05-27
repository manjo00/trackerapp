import 'package:freezed_annotation/freezed_annotation.dart';
import 'tracker_model.dart';

part 'tracker_log_model.freezed.dart';

/// One value within a log entry.
@freezed
abstract class TrackerLogValueModel with _$TrackerLogValueModel {
  const factory TrackerLogValueModel({
    required int id,
    required int logId,
    required int itemId,
    required String valueText,
  }) = _TrackerLogValueModel;
}

/// One log entry with all its values pre-joined.
@freezed
abstract class TrackerLogModel with _$TrackerLogModel {
  const factory TrackerLogModel({
    required int id,
    required int trackerId,
    required String loggedDate,
    String? notes,
    required DateTime createdAt,
    @Default([]) List<TrackerLogValueModel> values,
  }) = _TrackerLogModel;
}

/// A tracker combined with today's progress — used for the tracker card.
@freezed
abstract class TrackerWithProgress with _$TrackerWithProgress {
  const factory TrackerWithProgress({
    required int trackerId,
    required String name,
    required String icon,
    required int colorValue,
    required TrackerType trackerType,
    /// Total items in the tracker (for checklist type).
    required int totalItems,
    /// Items checked/logs recorded today.
    required int doneToday,
  }) = _TrackerWithProgress;
}
