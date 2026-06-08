import 'tracker_item_model.dart';

/// A daily-checklist tracker enriched with today's item-level check state.
///
/// Used exclusively by [TodayScreen] for inline check-off.
/// Plain Dart — no code generation needed.
class TrackerTodayStatus {
  const TrackerTodayStatus({
    required this.trackerId,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.items,
    required this.checkedItemIds,
  });

  final int trackerId;
  final String name;
  final String icon;
  final int colorValue;

  /// All checkbox items belonging to this tracker, in sort order.
  final List<TrackerItemModel> items;

  /// Item IDs that are checked for today's date.
  final Set<int> checkedItemIds;

  int get doneToday => checkedItemIds.length;
  int get totalItems => items.length;
}
