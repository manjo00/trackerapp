import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../dao/trackers_dao.dart';
import '../models/tracker_item_model.dart';
import '../models/tracker_log_model.dart';
import '../models/tracker_model.dart';
import '../models/tracker_today_status.dart';

final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
String _today() => _dateFmt.format(DateTime.now());

class TrackersRepository {
  TrackersRepository(this._dao);

  final TrackersDao _dao;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All trackers with today's progress pre-computed.
  Stream<List<TrackerWithProgress>> watchTrackersWithProgress() {
    return _dao.watchAllTrackers().asyncMap((rows) async {
      final String today = _today();
      final List<TrackerWithProgress> result = [];

      for (final CustomTracker row in rows) {
        final List<TrackerItem> items =
            await _dao.getItemsForTracker(row.id);
        final List<TrackerLog> todayLogs =
            await _dao.getLogsForDate(row.id, today);

        int doneToday = 0;

        if (row.templateType == TrackerType.dailyChecklist.value) {
          // Count checked items.
          for (final TrackerLog log in todayLogs) {
            final List<TrackerLogValue> vals =
                await _dao.getValuesForLog(log.id);
            doneToday +=
                vals.where((v) => v.valueText == 'true').length;
          }
        } else {
          // Session log: count how many rows were logged today.
          doneToday = todayLogs.length;
        }

        result.add(TrackerWithProgress(
          trackerId: row.id,
          name: row.name,
          icon: row.icon,
          colorValue: row.colorValue,
          trackerType: TrackerType.fromString(row.templateType),
          totalItems: items.length,
          doneToday: doneToday,
        ));
      }

      return result;
    });
  }

  /// Stream of daily-checklist trackers enriched with today's check state.
  ///
  /// Only returns [TrackerType.dailyChecklist] trackers — session logs are
  /// not suitable for inline check-off on the Today screen.
  ///
  /// Items are NOT loaded here to avoid a race condition: the tracker row is
  /// inserted before its items, so the stream would otherwise emit with an
  /// empty item list. [_TrackerInlineCard] watches [trackerItemsProvider]
  /// directly instead, which reacts to the trackerItems table in real-time.
  Stream<List<TrackerTodayStatus>> watchChecklistTrackersForToday() {
    return _dao.watchAllTrackers().asyncMap((rows) async {
      final String today = _today();
      final List<TrackerTodayStatus> result = [];

      for (final CustomTracker row in rows) {
        // Skip non-checklist trackers and template placeholders.
        if (row.templateType != TrackerType.dailyChecklist.value) continue;
        if (row.isTemplate) continue;

        // Collect which item IDs are checked today.
        final List<TrackerLog> todayLogs =
            await _dao.getLogsForDate(row.id, today);
        final Set<int> checkedIds = {};
        for (final TrackerLog log in todayLogs) {
          final List<TrackerLogValue> vals =
              await _dao.getValuesForLog(log.id);
          for (final TrackerLogValue val in vals) {
            if (val.valueText == 'true') checkedIds.add(val.itemId);
          }
        }

        result.add(TrackerTodayStatus(
          trackerId: row.id,
          name: row.name,
          icon: row.icon,
          colorValue: row.colorValue,
          checkedItemIds: checkedIds,
        ));
      }

      return result;
    });
  }

  /// Items for a specific tracker (ordered by sortOrder).
  Stream<List<TrackerItemModel>> watchItems(int trackerId) {
    return _dao
        .watchItemsForTracker(trackerId)
        .map((rows) => rows.map(_itemFromRow).toList());
  }

  /// All logs for a tracker, newest first, with values joined.
  Stream<List<TrackerLogModel>> watchLogs(int trackerId) {
    return _dao.watchLogsForTracker(trackerId).asyncMap((rows) async {
      final List<TrackerLogModel> result = [];
      for (final TrackerLog row in rows) {
        final List<TrackerLogValue> valRows =
            await _dao.getValuesForLog(row.id);
        result.add(_logFromRow(row, valRows));
      }
      return result;
    });
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Creates a new tracker from a [template] with a user-chosen [name].
  Future<int> addTracker({
    required String name,
    String? description,
    required TrackerType type,
    required String icon,
    required int colorValue,
    required List<(String, FieldType)> items,
    bool reminderEnabled = false,
    String? reminderTime,
    bool isTemplate = false,
  }) async {
    final int id = await _dao.insertTracker(
      CustomTrackersCompanion(
        name: Value(name.trim()),
        description: Value(description?.trim()),
        templateType: Value(type.value),
        icon: Value(icon),
        colorValue: Value(colorValue),
        createdAt: Value(DateTime.now()),
        reminderEnabled: Value(reminderEnabled),
        reminderTime: Value(reminderTime),
        isTemplate: Value(isTemplate),
      ),
    );

    for (int i = 0; i < items.length; i++) {
      final (String itemName, FieldType fieldType) = items[i];
      await _dao.insertItem(
        TrackerItemsCompanion(
          trackerId: Value(id),
          name: Value(itemName.trim()),
          fieldType: Value(fieldType.value),
          sortOrder: Value(i),
        ),
      );
    }

    return id;
  }

  /// Logs a daily-checklist entry for [date] (default today).
  /// [checkedItemIds] is the set of item IDs the user checked.
  Future<void> logChecklist({
    required int trackerId,
    required Set<int> checkedItemIds,
    required List<TrackerItemModel> allItems,
    String? notes,
    String? date,
  }) async {
    final String logDate = date ?? _today();

    // Replace any existing log for this date.
    await _dao.deleteLogsForDate(trackerId, logDate);

    final int logId = await _dao.insertLog(
      TrackerLogsCompanion(
        trackerId: Value(trackerId),
        loggedDate: Value(logDate),
        notes: Value(notes),
        createdAt: Value(DateTime.now()),
      ),
    );

    for (final TrackerItemModel item in allItems) {
      await _dao.insertValue(
        TrackerLogValuesCompanion(
          logId: Value(logId),
          itemId: Value(item.id),
          valueText:
              Value(checkedItemIds.contains(item.id) ? 'true' : 'false'),
        ),
      );
    }
  }

  /// Appends one session-log row (e.g. one exercise in a workout).
  Future<void> logSessionRow({
    required int trackerId,
    required Map<int, String> fieldValues, // itemId → value
    String? notes,
    String? date,
  }) async {
    final int logId = await _dao.insertLog(
      TrackerLogsCompanion(
        trackerId: Value(trackerId),
        loggedDate: Value(date ?? _today()),
        notes: Value(notes),
        createdAt: Value(DateTime.now()),
      ),
    );

    for (final MapEntry<int, String> entry in fieldValues.entries) {
      await _dao.insertValue(
        TrackerLogValuesCompanion(
          logId: Value(logId),
          itemId: Value(entry.key),
          valueText: Value(entry.value),
        ),
      );
    }
  }

  Future<void> deleteLog(int logId) => _dao.deleteLog(logId);
  Future<void> deleteTracker(int id) => _dao.deleteTracker(id);

  /// One-shot list of all trackers — used by rescheduleAll on app start.
  Future<List<TrackerModel>> getAllTrackers() async {
    final rows = await _dao.getAllTrackers();
    return rows.map(_trackerFromRow).toList();
  }

  // ── Private converters ────────────────────────────────────────────────────

  TrackerModel _trackerFromRow(CustomTracker row) => TrackerModel(
        id: row.id,
        name: row.name,
        description: row.description,
        type: TrackerType.fromString(row.templateType),
        icon: row.icon,
        colorValue: row.colorValue,
        createdAt: row.createdAt,
        reminderEnabled: row.reminderEnabled,
        reminderTime: row.reminderTime,
        isTemplate: row.isTemplate,
      );

  TrackerItemModel _itemFromRow(TrackerItem row) => TrackerItemModel(
        id: row.id,
        trackerId: row.trackerId,
        name: row.name,
        fieldType: FieldType.fromString(row.fieldType),
        sortOrder: row.sortOrder,
      );

  TrackerLogModel _logFromRow(
      TrackerLog row, List<TrackerLogValue> vals) =>
      TrackerLogModel(
        id: row.id,
        trackerId: row.trackerId,
        loggedDate: row.loggedDate,
        notes: row.notes,
        createdAt: row.createdAt,
        values: vals
            .map((v) => TrackerLogValueModel(
                  id: v.id,
                  logId: v.logId,
                  itemId: v.itemId,
                  valueText: v.valueText,
                ))
            .toList(),
      );
}
