/// A daily-checklist tracker enriched with today's item-level check state.
///
/// Used exclusively by [TodayScreen] for inline check-off.
/// Plain Dart — no code generation needed.
///
/// Items are intentionally NOT stored here. [_TrackerInlineCard] watches
/// [trackerItemsProvider] directly so it reacts to item changes without
/// a race condition between the tracker-row insert and item inserts.
class TrackerTodayStatus {
  const TrackerTodayStatus({
    required this.trackerId,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.checkedItemIds,
  });

  final int trackerId;
  final String name;
  final String icon;
  final int colorValue;

  /// Item IDs that are checked for today's date.
  final Set<int> checkedItemIds;
}
