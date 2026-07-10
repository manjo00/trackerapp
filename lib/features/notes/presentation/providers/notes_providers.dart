import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/images/image_storage_service.dart';
import '../../data/dao/notes_dao.dart';
import '../../data/repositories/notes_repository.dart';

/// Reusable image storage (files on disk, filenames in the DB).
final imageStorageServiceProvider =
    Provider<ImageStorageService>((ref) => ImageStorageService());

/// DAO wired to the app-wide database (mirrors the Lists DAO provider).
final notesDaoProvider =
    Provider<NotesDao>((ref) => NotesDao(ref.watch(appDatabaseProvider)));

final notesRepositoryProvider = Provider<NotesRepository>((ref) =>
    NotesRepository(ref.watch(notesDaoProvider),
        ref.watch(imageStorageServiceProvider)));

/// All active notebooks.
final notebooksProvider = StreamProvider<List<Notebook>>(
    (ref) => ref.watch(notesDaoProvider).watchNotebooks());

/// Notes in a notebook — key `null` = Unfiled.
final notesForNotebookProvider =
    StreamProvider.family<List<Note>, int?>((ref, notebookId) =>
        ref.watch(notesDaoProvider).watchNotes(notebookId));

/// The blocks of one note, in order.
final noteBlocksProvider = StreamProvider.family<List<NoteBlock>, int>(
    (ref, noteId) => ref.watch(notesDaoProvider).watchBlocks(noteId));

/// Latest note-edit time per notebook (notebookId → max note updatedAt).
final lastNoteEditByNotebookProvider = StreamProvider<Map<int, DateTime>>(
    (ref) => ref.watch(notesDaoProvider).watchLastNoteEditByNotebook());

/// Active notebooks ordered by recent activity — the greater of the
/// notebook's own createdAt and its latest note edit — newest first. Drives
/// the Home "Notes" block.
final recentNotebooksProvider = Provider<List<Notebook>>((ref) {
  final List<Notebook> nbs =
      ref.watch(notebooksProvider).valueOrNull ?? const [];
  final Map<int, DateTime> lastEdit =
      ref.watch(lastNoteEditByNotebookProvider).valueOrNull ?? const {};
  DateTime recency(Notebook n) {
    final DateTime? edited = lastEdit[n.id];
    return (edited != null && edited.isAfter(n.createdAt))
        ? edited
        : n.createdAt;
  }

  final List<Notebook> sorted = [...nbs]
    ..sort((a, b) => recency(b).compareTo(recency(a)));
  return sorted;
});
