import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../tables/custom_trackers_table.dart';
import '../tables/tracker_items_table.dart';
import '../tables/tracker_log_values_table.dart';
import '../tables/tracker_logs_table.dart';

part 'trackers_dao.g.dart';

@DriftAccessor(
    tables: [CustomTrackers, TrackerItems, TrackerLogs, TrackerLogValues])
class TrackersDao extends DatabaseAccessor<AppDatabase>
    with _$TrackersDaoMixin {
  TrackersDao(super.db);

  // ── Trackers ──────────────────────────────────────────────────────────────

  Stream<List<CustomTracker>> watchAllTrackers() =>
      (select(customTrackers)
            ..where((t) => t.archivedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<int> insertTracker(CustomTrackersCompanion companion) =>
      into(customTrackers).insert(companion);

  /// One-shot fetch of active trackers — used by rescheduleAll on app start.
  /// Archived trackers are excluded so their reminders aren't rescheduled.
  Future<List<CustomTracker>> getAllTrackers() =>
      (select(customTrackers)..where((t) => t.archivedAt.isNull())).get();

  /// Archived trackers, most-recently-archived first (Archived screen).
  Stream<List<CustomTracker>> watchArchivedTrackers() =>
      (select(customTrackers)
            ..where((t) => t.archivedAt.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)]))
          .watch();

  /// Sets/clears a tracker's archived state ([at] = null unarchives).
  Future<void> setTrackerArchived(int id, DateTime? at) =>
      (update(customTrackers)..where((t) => t.id.equals(id)))
          .write(CustomTrackersCompanion(archivedAt: Value(at)));

  Future<void> deleteTracker(int id) =>
      (delete(customTrackers)..where((t) => t.id.equals(id))).go();

  // ── Items ─────────────────────────────────────────────────────────────────

  Future<List<TrackerItem>> getItemsForTracker(int trackerId) =>
      (select(trackerItems)
            ..where((i) => i.trackerId.equals(trackerId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();

  Stream<List<TrackerItem>> watchItemsForTracker(int trackerId) =>
      (select(trackerItems)
            ..where((i) => i.trackerId.equals(trackerId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .watch();

  Future<int> insertItem(TrackerItemsCompanion companion) =>
      into(trackerItems).insert(companion);

  Future<void> deleteItemsForTracker(int trackerId) =>
      (delete(trackerItems)..where((i) => i.trackerId.equals(trackerId))).go();

  // ── Logs ──────────────────────────────────────────────────────────────────

  Stream<List<TrackerLog>> watchLogsForTracker(int trackerId) =>
      (select(trackerLogs)
            ..where((l) => l.trackerId.equals(trackerId))
            ..orderBy([(l) => OrderingTerm.desc(l.loggedDate),
                        (l) => OrderingTerm.desc(l.createdAt)]))
          .watch();

  Future<List<TrackerLog>> getLogsForDate(int trackerId, String date) =>
      (select(trackerLogs)
            ..where((l) =>
                l.trackerId.equals(trackerId) & l.loggedDate.equals(date)))
          .get();

  Future<int> insertLog(TrackerLogsCompanion companion) =>
      into(trackerLogs).insert(companion);

  Future<void> deleteLog(int logId) =>
      (delete(trackerLogs)..where((l) => l.id.equals(logId))).go();

  Future<void> deleteLogsForDate(int trackerId, String date) =>
      (delete(trackerLogs)
            ..where((l) =>
                l.trackerId.equals(trackerId) & l.loggedDate.equals(date)))
          .go();

  // ── Log values ────────────────────────────────────────────────────────────

  Future<List<TrackerLogValue>> getValuesForLog(int logId) =>
      (select(trackerLogValues)..where((v) => v.logId.equals(logId))).get();

  Future<int> insertValue(TrackerLogValuesCompanion companion) =>
      into(trackerLogValues).insert(companion);

  Future<void> deleteValuesForLog(int logId) =>
      (delete(trackerLogValues)..where((v) => v.logId.equals(logId))).go();
}
