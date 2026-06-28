import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/dao/shifts_dao.dart';
import '../../data/models/work_shift_model.dart';
import '../../data/repositories/shifts_repository.dart';

part 'shifts_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

/// The single [ShiftsRepository] wired to the live database.
@Riverpod(keepAlive: true)
ShiftsRepository shiftsRepository(ShiftsRepositoryRef ref) {
  return ShiftsRepository(ShiftsDao(ref.watch(appDatabaseProvider)));
}

// ── Read provider ─────────────────────────────────────────────────────────

/// All shifts keyed by "yyyy-MM-dd". Any calendar surface watches this and
/// looks up a day with `map[dateString]` — null means a free day.
@riverpod
Stream<Map<String, WorkShiftModel>> shiftsByDate(ShiftsByDateRef ref) {
  return ref.watch(shiftsRepositoryProvider).watchShiftsByDate();
}

// ── Write provider ────────────────────────────────────────────────────────

/// Edits the shift schedule. Holds the tap-to-cycle logic so the UI only has
/// to call [cycle] when a calendar day is tapped.
@riverpod
class ShiftEditor extends _$ShiftEditor {
  @override
  Future<void> build() async {}

  /// Cycles a day through: OFF → Day → Night → OFF.
  ///
  /// Reads the current state from [shiftsByDateProvider] so it always acts on
  /// the latest map, then writes the next state.
  Future<void> cycle(String date) async {
    final Map<String, WorkShiftModel> map =
        ref.read(shiftsByDateProvider).valueOrNull ?? const {};
    final WorkShiftModel? current = map[date];
    final ShiftsRepository repo = ref.read(shiftsRepositoryProvider);

    if (current == null) {
      await repo.setShift(date, ShiftType.day);
    } else if (current.type == ShiftType.day) {
      await repo.setShift(date, ShiftType.night);
    } else {
      await repo.clearShift(date);
    }
  }

  /// Directly sets [date] to [type] (used by future explicit pickers).
  Future<void> setShift(String date, ShiftType type) =>
      ref.read(shiftsRepositoryProvider).setShift(date, type);

  /// Marks [date] as OFF.
  Future<void> clear(String date) =>
      ref.read(shiftsRepositoryProvider).clearShift(date);
}
