import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../data/home_blocks_dao.dart';
import '../widgets/shift_block.dart';

/// DAO wired to the app-wide database (mirrors the Notes/Lists DAO providers).
final homeBlocksDaoProvider = Provider<HomeBlocksDao>(
    (ref) => HomeBlocksDao(ref.watch(appDatabaseProvider)));

/// The dashboard's block rows, in order. On first read it hands the legacy
/// prefs layout over to the DB (one-time seed — a no-op ever after), so
/// upgrading users keep their arrangement.
final homeBlockRowsProvider = StreamProvider<List<HomeBlock>>((ref) async* {
  final HomeBlocksDao dao = ref.watch(homeBlocksDaoProvider);
  await dao.ensureSeeded(ref.read(settingsProvider).homeBlocks);
  yield* dao.watchBlocks();
});

/// One note, live — null once deleted (pinned-block title + placeholder).
final watchNoteProvider = StreamProvider.family<Note?, int>(
    (ref, id) => ref.watch(notesDaoProvider).watchNote(id));

/// Every active note, for the pinned-note picker.
final allNotesProvider = StreamProvider<List<Note>>(
    (ref) => ref.watch(notesDaoProvider).watchAllNotes());

/// Whether the shift glance has nothing to show (no shift today nor in the
/// next 14 days) — drives that block's hide-when-empty option.
final shiftGlanceEmptyProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(shiftsByDateProvider).whenData((byDate) {
    final DateTime now = DateTime.now();
    return ShiftBlock.isEmpty(byDate, DateTime(now.year, now.month, now.day));
  });
});
