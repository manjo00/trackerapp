import 'package:freezed_annotation/freezed_annotation.dart';
import 'habit_model.dart';

part 'habit_with_status.freezed.dart';

/// A [HabitModel] enriched with today's completion state and streak count.
///
/// This is the object that [HabitListScreen] receives from the provider.
/// It carries everything a [HabitTile] needs to render itself without
/// making any additional database calls.
@freezed
abstract class HabitWithStatus with _$HabitWithStatus {
  const factory HabitWithStatus({
    required HabitModel habit,

    /// True if the habit has a completion row for today's date.
    required bool isDoneToday,

    /// Number of consecutive days (up to and including today) with a completion.
    /// 0 means the habit has never been completed or the streak was broken.
    required int streak,
  }) = _HabitWithStatus;
}
