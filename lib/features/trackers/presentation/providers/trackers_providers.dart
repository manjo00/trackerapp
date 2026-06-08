import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/trackers_dao.dart';
import '../../data/models/tracker_item_model.dart';
import '../../data/models/tracker_log_model.dart';
import '../../data/models/tracker_model.dart';
import '../../data/models/tracker_today_status.dart';
import '../../data/repositories/trackers_repository.dart';

part 'trackers_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

/// Provides the single [TrackersRepository] wired to the live database.
///
/// Kept alive because the repository is cheap and needed throughout the session.
@Riverpod(keepAlive: true)
TrackersRepository trackersRepository(TrackersRepositoryRef ref) {
  final dao = TrackersDao(ref.watch(appDatabaseProvider));
  return TrackersRepository(dao);
}

// ── Read providers ────────────────────────────────────────────────────────

/// Stream of all trackers with today's progress pre-computed.
///
/// Each item includes how many checklist boxes were ticked, or how many
/// session rows were logged today, so the card can show a progress indicator.
@riverpod
Stream<List<TrackerWithProgress>> trackersWithProgress(
    TrackersWithProgressRef ref) {
  return ref.watch(trackersRepositoryProvider).watchTrackersWithProgress();
}

/// Stream of daily-checklist trackers with today's item-level check state.
///
/// Used by [TodayScreen] to render inline expandable check-off cards.
/// Session-log trackers are excluded — they don't map to a simple ✓ pattern.
@riverpod
Stream<List<TrackerTodayStatus>> checklistTrackersForToday(
    ChecklistTrackersForTodayRef ref) {
  return ref
      .watch(trackersRepositoryProvider)
      .watchChecklistTrackersForToday();
}

/// Stream of items (fields) belonging to [trackerId], ordered by sortOrder.
///
/// Used by the log-entry screen to know which fields to show.
@riverpod
Stream<List<TrackerItemModel>> trackerItems(
    TrackerItemsRef ref, int trackerId) {
  return ref.watch(trackersRepositoryProvider).watchItems(trackerId);
}

/// Stream of all log entries for [trackerId], newest first, values joined.
///
/// Used by the detail / history screen.
@riverpod
Stream<List<TrackerLogModel>> trackerLogs(
    TrackerLogsRef ref, int trackerId) {
  return ref.watch(trackersRepositoryProvider).watchLogs(trackerId);
}

// ── Write providers ───────────────────────────────────────────────────────

/// Creates a brand-new tracker (table row + all its item rows).
///
/// Usage:
/// ```dart
/// await ref.read(addTrackerProvider.notifier).add(
///   name: 'My Prayers',
///   type: TrackerType.dailyChecklist,
///   icon: '🕌',
///   colorValue: Colors.green.value,
///   items: [('Fajr', FieldType.checkbox), ...],
/// );
/// ```
@riverpod
class AddTracker extends _$AddTracker {
  @override
  Future<void> build() async {}

  Future<void> add({
    required String name,
    String? description,
    required TrackerType type,
    required String icon,
    required int colorValue,
    required List<(String, FieldType)> items,
    bool reminderEnabled = false,
    String? reminderTime,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackersRepositoryProvider).addTracker(
            name: name,
            description: description,
            type: type,
            icon: icon,
            colorValue: colorValue,
            items: items,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
          ),
    );
    ref.invalidate(trackersWithProgressProvider);
  }
}

/// Saves a daily-checklist log for today (replaces any previous entry for
/// the same date so re-checking is idempotent).
@riverpod
class LogChecklist extends _$LogChecklist {
  @override
  Future<void> build() async {}

  Future<void> save({
    required int trackerId,
    required Set<int> checkedItemIds,
    required List<TrackerItemModel> allItems,
    String? notes,
    String? date,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackersRepositoryProvider).logChecklist(
            trackerId: trackerId,
            checkedItemIds: checkedItemIds,
            allItems: allItems,
            notes: notes,
            date: date,
          ),
    );
    ref.invalidate(trackersWithProgressProvider);
    ref.invalidate(trackerLogsProvider(trackerId));
  }
}

/// Appends one session-log row (e.g. one exercise in a workout).
@riverpod
class LogSessionRow extends _$LogSessionRow {
  @override
  Future<void> build() async {}

  Future<void> save({
    required int trackerId,
    required Map<int, String> fieldValues,
    String? notes,
    String? date,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackersRepositoryProvider).logSessionRow(
            trackerId: trackerId,
            fieldValues: fieldValues,
            notes: notes,
            date: date,
          ),
    );
    ref.invalidate(trackersWithProgressProvider);
    ref.invalidate(trackerLogsProvider(trackerId));
  }
}

/// Deletes a single log entry (and its values via CASCADE).
@riverpod
class DeleteLog extends _$DeleteLog {
  @override
  Future<void> build() async {}

  Future<void> delete(int logId, {required int trackerId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackersRepositoryProvider).deleteLog(logId),
    );
    ref.invalidate(trackersWithProgressProvider);
    ref.invalidate(trackerLogsProvider(trackerId));
  }
}

/// Permanently deletes a tracker and all its items + logs (CASCADE in DB).
@riverpod
class DeleteTracker extends _$DeleteTracker {
  @override
  Future<void> build() async {}

  Future<void> delete(int trackerId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(trackersRepositoryProvider).deleteTracker(trackerId),
    );
    ref.invalidate(trackersWithProgressProvider);
  }
}
