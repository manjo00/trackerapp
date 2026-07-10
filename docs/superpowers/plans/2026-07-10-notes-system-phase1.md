# Notes System (Block Editor) — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A notebook-organized notes feature where each note is a stack of editable blocks (text, tappable checkbox, inline photo), with photo attachments stored as files on disk.

**Architecture:** Standard five-layer pipeline (Table → DAO → Repository → Provider → Screen), mirroring the Lists feature. A reusable `ImageStorageService` copies picked photos into `<appDocs>/note_images/` and stores only the filename in Drift, resolving to a full path at display time.

**Tech Stack:** Drift (schema v14), Riverpod (manual `Provider`/`StreamProvider`), go_router (full-screen routes), `image_picker` (new dep), `path_provider` (existing).

## Global Constraints
- Flutter 3.44 / Dart null-safety strict. No `!` null-bang unless unavoidable.
- Colors via `.toARGB32()`, never `.value`.
- Drift migrations via `m.createTable()` / `m.addColumn()` only — never raw SQL.
- Schema goes **13 → 14**; bump `schemaVersion`, add an `if (from < 14)` block.
- `const` constructors where possible; one widget per file.
- Re-read `state.valueOrNull` after every `await` in a Riverpod notifier.
- Run `dart run build_runner build --delete-conflicting-outputs` after schema/DAO changes.
- New dependency `image_picker` — announced before adding.
- `flutter analyze` clean; each shippable step ends with `### 🧪 Manual Test Steps`.
- Tests run from `C:\Projects\life_tracker` with `flutter test <path>`.
- Drift generated names: table `Notebooks` → getter `notebooks`, row `Notebook`, companion `NotebooksCompanion`; `Notes` → `notes`/`Note`/`NotesCompanion`; `NoteBlocks` → `noteBlocks`/`NoteBlock`/`NoteBlocksCompanion`.

---

## File Structure

**New:**
- `lib/features/notes/data/tables/notebooks_table.dart` — `Notebooks` table.
- `lib/features/notes/data/tables/notes_table.dart` — `Notes` table.
- `lib/features/notes/data/tables/note_blocks_table.dart` — `NoteBlocks` table.
- `lib/features/notes/data/models/note_block_type.dart` — `NoteBlockType` enum (pure).
- `lib/features/notes/data/dao/notes_dao.dart` — `NotesDao` (`@DriftAccessor`).
- `lib/features/notes/data/repositories/notes_repository.dart` — photo-aware ops.
- `lib/features/notes/presentation/providers/notes_providers.dart` — providers.
- `lib/features/notes/presentation/screens/notes_overview_screen.dart`
- `lib/features/notes/presentation/screens/notebook_detail_screen.dart`
- `lib/features/notes/presentation/screens/note_editor_screen.dart`
- `lib/features/notes/presentation/screens/photo_view_screen.dart`
- `lib/features/notes/presentation/widgets/notebook_tile.dart`
- `lib/features/notes/presentation/widgets/note_tile.dart`
- `lib/features/notes/presentation/widgets/text_block_view.dart`
- `lib/features/notes/presentation/widgets/checkbox_block_view.dart`
- `lib/features/notes/presentation/widgets/photo_block_view.dart`
- `lib/core/images/image_storage_service.dart`
- `lib/core/images/image_filename.dart` — pure `buildImageFilename`.
- `test/core/database/notes_migration_test.dart`
- `test/features/notes/notes_dao_test.dart`
- `test/core/images/image_filename_test.dart`

**Modify:**
- `lib/core/database/app_database.dart` — register 3 tables, v14 migration, schemaVersion.
- `lib/core/router/app_router.dart` — 3 routes + import.
- `lib/features/settings/presentation/widgets/app_drawer.dart` — Notes feature tile.
- `lib/core/backup/backup_service.dart` — import batch + delete order for 3 tables.
- `pubspec.yaml` — `image_picker`.
- `CLAUDE.md` — feature row, schema v14, backup limitation.

---

## Task 1: Schema v14 — tables + migration

**Files:**
- Create: `lib/features/notes/data/tables/notebooks_table.dart`
- Create: `lib/features/notes/data/tables/notes_table.dart`
- Create: `lib/features/notes/data/tables/note_blocks_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Test: `test/core/database/notes_migration_test.dart`

**Interfaces:**
- Produces: tables `Notebooks`, `Notes`, `NoteBlocks`; getters `db.notebooks`, `db.notes`, `db.noteBlocks`; row types `Notebook`, `Note`, `NoteBlock`; companions `NotebooksCompanion`, `NotesCompanion`, `NoteBlocksCompanion`.

- [ ] **Step 1: Write the table files**

`notebooks_table.dart`:
```dart
import 'package:drift/drift.dart';

/// A user-created folder of notes (e.g. "Rounds", "Cardiology").
class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF8AB4F8))();
  TextColumn get icon => text().withDefault(const Constant('📓'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  /// NULL = active; non-null = archived (Phase 2 wires the Archived screen).
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
```

`notes_table.dart`:
```dart
import 'package:drift/drift.dart';
import 'notebooks_table.dart';

/// A single note. notebookId NULL = "Unfiled" (no row for it, mirrors the
/// Captured-list convention). Body lives in note_blocks, not here.
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notebookId => integer()
      .nullable()
      .references(Notebooks, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  /// Bumped on every edit — sorts recently-edited first and is the
  /// last-write-wins key for future cloud sync.
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
```

`note_blocks_table.dart`:
```dart
import 'package:drift/drift.dart';
import 'notes_table.dart';

/// One block of a note. type is 'text' | 'checkbox' | 'photo'.
/// content holds the text (text/checkbox) OR the image filename (photo).
class NoteBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text().withLength(min: 1, max: 16)();
  TextColumn get content => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 2: Register the tables + migration in `app_database.dart`**

Add imports after the tasks table imports (line ~15):
```dart
import '../../features/notes/data/tables/note_blocks_table.dart';
import '../../features/notes/data/tables/notebooks_table.dart';
import '../../features/notes/data/tables/notes_table.dart';
```

In the `tables:` list, after `MuscleTargets,` (line ~72):
```dart
    // ── Notes (v14) ──────────────────────────────────────────────────────────
    Notebooks,
    Notes,
    NoteBlocks,
```

Add the doc line after the v13 comment (line ~106):
```dart
  /// v14 → notes system: notebooks, notes, note_blocks tables (block editor)
```

Change `int get schemaVersion => 13;` → `=> 14;`.

In `onUpgrade`, after the `if (from < 13)` block:
```dart
          if (from < 14) {
            // Notes system: notebooks → notes → note_blocks (FK order).
            await m.createTable(notebooks);
            await m.createTable(notes);
            await m.createTable(noteBlocks);
          }
```

- [ ] **Step 3: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `app_database.g.dart` now has `notebooks`/`notes`/`noteBlocks` getters and `Notebook`/`Note`/`NoteBlock` classes.

- [ ] **Step 4: Write the migration test**

`test/core/database/notes_migration_test.dart`:
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

void main() {
  test('v14 tables exist and accept inserts', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime(2026, 7, 10, 9);

    final nb = await db.into(db.notebooks).insert(
        NotebooksCompanion.insert(name: 'Rounds', createdAt: now));
    final note = await db.into(db.notes).insert(NotesCompanion.insert(
        notebookId: Value(nb), createdAt: now, updatedAt: now));
    await db.into(db.noteBlocks).insert(NoteBlocksCompanion.insert(
        noteId: note, type: 'text', content: const Value('hello')));

    expect((await db.select(db.notebooks).get()).single.name, 'Rounds');
    expect((await db.select(db.notes).get()).single.notebookId, nb);
    expect((await db.select(db.noteBlocks).get()).single.content, 'hello');
    await db.close();
  });
}
```

- [ ] **Step 5: Run the test**

Run: `flutter test test/core/database/notes_migration_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Commit**

```bash
git add lib/features/notes/data/tables lib/core/database/app_database.dart lib/core/database/app_database.g.dart test/core/database/notes_migration_test.dart
git commit -m "feat: schema v14 — notebooks, notes, note_blocks tables"
```

---

## Task 2: Pure helpers — NoteBlockType + image filename

**Files:**
- Create: `lib/features/notes/data/models/note_block_type.dart`
- Create: `lib/core/images/image_filename.dart`
- Test: `test/core/images/image_filename_test.dart`

**Interfaces:**
- Produces: `enum NoteBlockType { text, checkbox, photo }` with `String get storageKey` and `static NoteBlockType parse(String?)`; `String buildImageFilename({required int seed, String extension})`.

- [ ] **Step 1: Write the failing test**

`test/core/images/image_filename_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/images/image_filename.dart';

void main() {
  test('builds img_<seed>.<ext>', () {
    expect(buildImageFilename(seed: 123, extension: 'png'), 'img_123.png');
  });
  test('defaults to jpg', () {
    expect(buildImageFilename(seed: 5), 'img_5.jpg');
  });
  test('lowercases and strips a leading dot', () {
    expect(buildImageFilename(seed: 7, extension: '.JPEG'), 'img_7.jpeg');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/images/image_filename_test.dart`
Expected: FAIL (compile error — `image_filename.dart` missing).

- [ ] **Step 3: Write the implementations**

`image_filename.dart`:
```dart
/// Builds a stable image filename from a caller-supplied monotonic [seed]
/// (e.g. DateTime.now().microsecondsSinceEpoch). Kept pure — the timestamp
/// stays OUTSIDE so this is deterministic and unit-testable.
String buildImageFilename({required int seed, String extension = 'jpg'}) {
  var ext = extension.toLowerCase();
  if (ext.startsWith('.')) ext = ext.substring(1);
  if (ext.isEmpty) ext = 'jpg';
  return 'img_$seed.$ext';
}
```

`note_block_type.dart`:
```dart
/// The kinds of block a note can contain (Phase 1).
enum NoteBlockType {
  text,
  checkbox,
  photo;

  /// Value persisted in note_blocks.type.
  String get storageKey => name;

  /// Parses a stored value; null/unknown falls back to text (safe default).
  static NoteBlockType parse(String? raw) => switch (raw) {
        'checkbox' => NoteBlockType.checkbox,
        'photo' => NoteBlockType.photo,
        _ => NoteBlockType.text,
      };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/images/image_filename_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/data/models/note_block_type.dart lib/core/images/image_filename.dart test/core/images/image_filename_test.dart
git commit -m "feat: NoteBlockType enum + pure image-filename helper"
```

---

## Task 3: NotesDao + tests

**Files:**
- Create: `lib/features/notes/data/dao/notes_dao.dart`
- Test: `test/features/notes/notes_dao_test.dart`

**Interfaces:**
- Consumes: tables from Task 1; `NoteBlockType` from Task 2.
- Produces: `NotesDao(AppDatabase db)` with:
  - `Stream<List<Notebook>> watchNotebooks()`
  - `Future<int> createNotebook({required String name, required int colorValue, required String icon, required DateTime now})`
  - `Future<void> renameNotebook(int id, String name, int colorValue, String icon)`
  - `Future<void> setNotebookArchived(int id, DateTime? at)`
  - `Future<void> deleteNotebook(int id)`
  - `Stream<List<Note>> watchNotes(int? notebookId)`
  - `Future<int> createNote({int? notebookId, required DateTime now})`
  - `Future<void> updateNoteTitle(int id, String title, DateTime now)`
  - `Future<void> touchNote(int id, DateTime now)`
  - `Future<void> setNoteArchived(int id, DateTime? at)`
  - `Future<List<NoteBlock>> getBlocks(int noteId)`
  - `Future<void> deleteNote(int id)`
  - `Stream<List<NoteBlock>> watchBlocks(int noteId)`
  - `Future<int> addBlock({required int noteId, required NoteBlockType type, String? content, required int orderIndex})`
  - `Future<void> updateBlockContent(int id, String content)`
  - `Future<void> setBlockChecked(int id, bool checked)`
  - `Future<void> deleteBlock(int id)`

- [ ] **Step 1: Write the DAO**

`notes_dao.dart`:
```dart
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/note_block_type.dart';
import '../tables/note_blocks_table.dart';
import '../tables/notebooks_table.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

/// Queries for notebooks, notes, and the blocks that make up a note.
@DriftAccessor(tables: [Notebooks, Notes, NoteBlocks])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // ── Notebooks ───────────────────────────────────────────────────────────
  Stream<List<Notebook>> watchNotebooks() => (select(notebooks)
        ..where((n) => n.archivedAt.isNull())
        ..orderBy([
          (n) => OrderingTerm.asc(n.orderIndex),
          (n) => OrderingTerm.asc(n.name),
        ]))
      .watch();

  Future<int> createNotebook({
    required String name,
    required int colorValue,
    required String icon,
    required DateTime now,
  }) async {
    final int maxOrder = await _maxNotebookOrder();
    return into(notebooks).insert(NotebooksCompanion.insert(
      name: name,
      colorValue: Value(colorValue),
      icon: Value(icon),
      orderIndex: Value(maxOrder + 1),
      createdAt: now,
    ));
  }

  Future<int> _maxNotebookOrder() async {
    final max = notebooks.orderIndex.max();
    final row = await (selectOnly(notebooks)..addColumns([max])).getSingle();
    return row.read(max) ?? -1;
  }

  Future<void> renameNotebook(int id, String name, int colorValue, String icon) =>
      (update(notebooks)..where((n) => n.id.equals(id))).write(
          NotebooksCompanion(
              name: Value(name),
              colorValue: Value(colorValue),
              icon: Value(icon)));

  Future<void> setNotebookArchived(int id, DateTime? at) =>
      (update(notebooks)..where((n) => n.id.equals(id)))
          .write(NotebooksCompanion(archivedAt: Value(at)));

  Future<void> deleteNotebook(int id) =>
      (delete(notebooks)..where((n) => n.id.equals(id))).go();

  // ── Notes ───────────────────────────────────────────────────────────────
  Stream<List<Note>> watchNotes(int? notebookId) {
    final query = select(notes)..where((n) => n.archivedAt.isNull());
    if (notebookId == null) {
      query.where((n) => n.notebookId.isNull());
    } else {
      query.where((n) => n.notebookId.equals(notebookId));
    }
    query.orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    return query.watch();
  }

  Future<int> createNote({int? notebookId, required DateTime now}) =>
      into(notes).insert(NotesCompanion.insert(
        notebookId: Value(notebookId),
        createdAt: now,
        updatedAt: now,
      ));

  Future<void> updateNoteTitle(int id, String title, DateTime now) =>
      (update(notes)..where((n) => n.id.equals(id))).write(
          NotesCompanion(title: Value(title), updatedAt: Value(now)));

  Future<void> touchNote(int id, DateTime now) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(updatedAt: Value(now)));

  Future<void> setNoteArchived(int id, DateTime? at) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(archivedAt: Value(at)));

  Future<List<NoteBlock>> getBlocks(int noteId) =>
      (select(noteBlocks)..where((b) => b.noteId.equals(noteId))).get();

  Future<void> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  // ── Blocks ──────────────────────────────────────────────────────────────
  Stream<List<NoteBlock>> watchBlocks(int noteId) => (select(noteBlocks)
        ..where((b) => b.noteId.equals(noteId))
        ..orderBy([
          (b) => OrderingTerm.asc(b.orderIndex),
          (b) => OrderingTerm.asc(b.id),
        ]))
      .watch();

  Future<int> addBlock({
    required int noteId,
    required NoteBlockType type,
    String? content,
    required int orderIndex,
  }) =>
      into(noteBlocks).insert(NoteBlocksCompanion.insert(
        noteId: noteId,
        type: type.storageKey,
        content: Value(content),
        orderIndex: Value(orderIndex),
      ));

  Future<void> updateBlockContent(int id, String content) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(content: Value(content)));

  Future<void> setBlockChecked(int id, bool checked) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(checked: Value(checked)));

  Future<void> deleteBlock(int id) =>
      (delete(noteBlocks)..where((b) => b.id.equals(id))).go();
}
```

- [ ] **Step 2: Run build_runner (generates `notes_dao.g.dart`)**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `notes_dao.g.dart` created with `_$NotesDaoMixin`.

- [ ] **Step 3: Write the failing tests**

`test/features/notes/notes_dao_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 10, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  test('notebook + note appear in their streams, filtered by notebook',
      () async {
    final nbA = await dao.createNotebook(
        name: 'A', colorValue: 0xFF000000, icon: '📓', now: now);
    final nbB = await dao.createNotebook(
        name: 'B', colorValue: 0xFF000000, icon: '📓', now: now);

    expect((await dao.watchNotebooks().first).length, 2);

    final note = await dao.createNote(notebookId: nbA, now: now);
    expect((await dao.watchNotes(nbA).first).map((n) => n.id), [note]);
    expect(await dao.watchNotes(nbB).first, isEmpty);

    final unfiled = await dao.createNote(notebookId: null, now: now);
    expect((await dao.watchNotes(null).first).map((n) => n.id), [unfiled]);
  });

  test('blocks return in order; checkbox toggle persists', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'a', orderIndex: 0);
    final cb = await dao.addBlock(
        noteId: note, type: NoteBlockType.checkbox, content: 'b', orderIndex: 1);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'img_1.jpg',
        orderIndex: 2);

    final blocks = await dao.watchBlocks(note).first;
    expect(blocks.map((b) => b.type), ['text', 'checkbox', 'photo']);

    await dao.setBlockChecked(cb, true);
    final after = await dao.watchBlocks(note).first;
    expect(after.firstWhere((b) => b.id == cb).checked, true);
  });

  test('deleting a note cascades its blocks', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 0);
    await dao.deleteNote(note);
    expect(await dao.watchBlocks(note).first, isEmpty);
  });

  test('deleting a notebook moves its notes to Unfiled (notebookId NULL)',
      () async {
    final nb = await dao.createNotebook(
        name: 'A', colorValue: 0xFF000000, icon: '📓', now: now);
    final note = await dao.createNote(notebookId: nb, now: now);
    await dao.deleteNotebook(nb);
    expect(await dao.watchNotes(nb).first, isEmpty);
    expect((await dao.watchNotes(null).first).map((n) => n.id), [note]);
  });

  test('archived notebook and note leave the active streams', () async {
    final nb = await dao.createNotebook(
        name: 'A', colorValue: 0xFF000000, icon: '📓', now: now);
    final note = await dao.createNote(notebookId: nb, now: now);
    await dao.setNotebookArchived(nb, now);
    await dao.setNoteArchived(note, now);
    expect(await dao.watchNotebooks().first, isEmpty);
    expect(await dao.watchNotes(nb).first, isEmpty);
  });
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/notes/notes_dao_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/data/dao test/features/notes/notes_dao_test.dart
git commit -m "feat: NotesDao — notebooks/notes/blocks queries + tests"
```

---

## Task 4: ImageStorageService + image_picker

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/images/image_storage_service.dart`

**Interfaces:**
- Consumes: `buildImageFilename` from Task 2.
- Produces: `ImageStorageService` with `Future<String?> pickAndStore(ImageSource source)`, `Future<String> resolvePath(String filename)`, `Future<bool> exists(String filename)`, `Future<void> delete(String filename)`.

- [ ] **Step 1: Announce + add the dependency**

Add under dependencies in `pubspec.yaml` (near `image` / `file_selector`):
```yaml
  image_picker: ^1.1.2
```
Run: `flutter pub get`
Expected: resolves; `image_picker` downloaded.

- [ ] **Step 2: Write the service**

`image_storage_service.dart`:
```dart
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_filename.dart';

/// Copies picked images into <appDocs>/note_images/ and resolves them back.
/// Only the filename is persisted (in note_blocks.content); the absolute path
/// is rebuilt at display time because the app-docs path can change per install.
class ImageStorageService {
  static const String _subdir = 'note_images';
  final ImagePicker _picker = ImagePicker();

  Future<Directory> _dir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, _subdir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Picks one image; copies its bytes into storage; returns the filename
  /// (null if the user cancelled).
  Future<String?> pickAndStore(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, maxWidth: 2000);
    if (picked == null) return null;
    final Directory dir = await _dir();
    final String ext = p.extension(picked.path).replaceFirst('.', '');
    final String filename = buildImageFilename(
      seed: DateTime.now().microsecondsSinceEpoch,
      extension: ext.isEmpty ? 'jpg' : ext,
    );
    await File(picked.path).copy(p.join(dir.path, filename));
    return filename;
  }

  Future<String> resolvePath(String filename) async {
    final Directory dir = await _dir();
    return p.join(dir.path, filename);
  }

  Future<bool> exists(String filename) async =>
      File(await resolvePath(filename)).exists();

  Future<void> delete(String filename) async {
    final File f = File(await resolvePath(filename));
    if (await f.exists()) await f.delete();
  }
}
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/core/images/image_storage_service.dart`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/images/image_storage_service.dart
git commit -m "feat: ImageStorageService + image_picker dependency"
```

---

## Task 5: Repository + providers

**Files:**
- Create: `lib/features/notes/data/repositories/notes_repository.dart`
- Create: `lib/features/notes/presentation/providers/notes_providers.dart`

**Interfaces:**
- Consumes: `NotesDao` (Task 3), `ImageStorageService` (Task 4), `NoteBlockType` (Task 2).
- Produces: `NotesRepository` (wraps DAO + image service); providers `notesDaoProvider`, `imageStorageServiceProvider`, `notesRepositoryProvider`, `notebooksProvider`, `notesForNotebookProvider` (family, `int?`), `noteBlocksProvider` (family, `int`). Reuses the existing `appDatabaseProvider`.

- [ ] **Step 1: Write the repository**

`notes_repository.dart`:
```dart
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/images/image_storage_service.dart';
import '../dao/notes_dao.dart';
import '../models/note_block_type.dart';

/// Coordinates the DAO and image storage so screens never orchestrate a file
/// write + DB write together. Plain text/checkbox mutations pass through,
/// bumping the note's updatedAt.
class NotesRepository {
  NotesRepository(this._dao, this._images);

  final NotesDao _dao;
  final ImageStorageService _images;

  NotesDao get dao => _dao;

  Future<void> addPhotoBlock(
    int noteId,
    ImageSource source,
    int orderIndex, {
    required DateTime now,
  }) async {
    final String? filename = await _images.pickAndStore(source);
    if (filename == null) return; // cancelled
    await _dao.addBlock(
      noteId: noteId,
      type: NoteBlockType.photo,
      content: filename,
      orderIndex: orderIndex,
    );
    await _dao.touchNote(noteId, now);
  }

  Future<void> removePhotoBlock(NoteBlock block, {required DateTime now}) async {
    final String? filename = block.content;
    if (filename != null && filename.isNotEmpty) {
      await _images.delete(filename);
    }
    await _dao.deleteBlock(block.id);
    await _dao.touchNote(block.noteId, now);
  }

  /// Deletes a note and every image file its photo blocks referenced.
  Future<void> deleteNoteWithPhotos(int noteId) async {
    final List<NoteBlock> blocks = await _dao.getBlocks(noteId);
    for (final NoteBlock b in blocks) {
      if (b.type == NoteBlockType.photo.storageKey && b.content != null) {
        await _images.delete(b.content!);
      }
    }
    await _dao.deleteNote(noteId);
  }
}
```

- [ ] **Step 2: Write the providers**

`notes_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/images/image_storage_service.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/dao/notes_dao.dart';
import '../../data/repositories/notes_repository.dart';

final imageStorageServiceProvider =
    Provider<ImageStorageService>((ref) => ImageStorageService());

final notesDaoProvider =
    Provider<NotesDao>((ref) => NotesDao(ref.watch(appDatabaseProvider)));

final notesRepositoryProvider = Provider<NotesRepository>((ref) =>
    NotesRepository(
        ref.watch(notesDaoProvider), ref.watch(imageStorageServiceProvider)));

final notebooksProvider = StreamProvider<List<Notebook>>(
    (ref) => ref.watch(notesDaoProvider).watchNotebooks());

final notesForNotebookProvider =
    StreamProvider.family<List<Note>, int?>((ref, notebookId) =>
        ref.watch(notesDaoProvider).watchNotes(notebookId));

final noteBlocksProvider = StreamProvider.family<List<NoteBlock>, int>(
    (ref, noteId) => ref.watch(notesDaoProvider).watchBlocks(noteId));
```

Note: confirm the existing app-database provider import path. If `appDatabaseProvider` lives elsewhere (grep: `grep -rn "appDatabaseProvider =" lib/`), fix the import to match (the Lists providers import it the same way).

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/notes`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add lib/features/notes/data/repositories lib/features/notes/presentation/providers
git commit -m "feat: NotesRepository + Riverpod providers"
```

---

## Task 6: Overview + notebook-detail screens, routes, drawer

**Files:**
- Create: `lib/features/notes/presentation/widgets/notebook_tile.dart`
- Create: `lib/features/notes/presentation/widgets/note_tile.dart`
- Create: `lib/features/notes/presentation/screens/notes_overview_screen.dart`
- Create: `lib/features/notes/presentation/screens/notebook_detail_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/settings/presentation/widgets/app_drawer.dart`

**Interfaces:**
- Consumes: providers from Task 5.
- Produces: routes `/notes`, `/notes/notebook/:id` (id or literal `unfiled`), `/notes/:id`.

- [ ] **Step 1: Write `notebook_tile.dart`**

A `ListTile`-style card: leading emoji `icon` on a `Color(colorValue)` chip, title `name`, trailing note-count (passed in). `onTap` callback. Follows `_DrawerTile`/list card visuals. (Full widget — icon in a `CircleAvatar` with `backgroundColor: Color(nb.colorValue).withAlpha(40)`, `Text(nb.icon)`.)

- [ ] **Step 2: Write `note_tile.dart`**

A `Card` + `InkWell`: title (or "Untitled" italic when empty), a one-line preview (first text block's content — pass the note plus an optional preview string), relative `updatedAt` date (reuse the `_DueDateChip` relative-format approach: Today/Yesterday/`d MMM`), and a small `Icons.photo_outlined` + count when the note has photo blocks. `onTap` opens the editor.

- [ ] **Step 3: Write `notes_overview_screen.dart`**

`ConsumerWidget`. AppBar "Notes". Body watches `notebooksProvider`:
- A fixed **Unfiled** tile at the top (📥, opens `/notes/notebook/unfiled`).
- Then one `NotebookTile` per notebook (tap → `/notes/notebook/${nb.id}`).
- FAB → `showNotebookDialog` (a `showDialog` with a name `TextField`, an emoji `TextField` defaulting '📓', and a color choice — reuse the palette used by `showListFormDialog`; keep it a self-contained dialog in this file). On save: `ref.read(notesDaoProvider).createNotebook(name:…, colorValue:…, icon:…, now: DateTime.now())`.
- Empty state text when there are no notebooks.

- [ ] **Step 4: Write `notebook_detail_screen.dart`**

`ConsumerWidget`, param `notebookId` (`int?`; `null` = Unfiled). AppBar:
- Title = the notebook name (watch `notebooksProvider`, find by id) or "Unfiled".
- For a real notebook, a ⋮ menu: **Rename / recolor** (reuse the dialog) → `renameNotebook`; **Delete** → confirm dialog ("Its notes move to Unfiled.") → `deleteNotebook` + `context.pop()`.
Body watches `notesForNotebookProvider(notebookId)`; renders `NoteTile`s (compute preview: first block of `type=='text'` via a one-shot `getBlocks`, or pass empty preview to keep it simple in Phase 1 — preview may be blank). FAB → `createNote(notebookId: notebookId, now: now)` then `context.push('/notes/${id}')`.

- [ ] **Step 5: Add the routes**

In `app_router.dart`, add the import and three routes after the `/archived` route:
```dart
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/notes/presentation/screens/notebook_detail_screen.dart';
import '../../features/notes/presentation/screens/notes_overview_screen.dart';
```
```dart
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NotesOverviewScreen(),
    ),
    GoRoute(
      path: '/notes/notebook/:id',
      builder: (context, state) {
        final String raw = state.pathParameters['id'] ?? 'unfiled';
        final int? notebookId = raw == 'unfiled' ? null : int.tryParse(raw);
        return NotebookDetailScreen(notebookId: notebookId);
      },
    ),
    GoRoute(
      path: '/notes/:id',
      builder: (context, state) =>
          NoteEditorScreen(noteId: int.parse(state.pathParameters['id']!)),
    ),
```
Route-order note: `/notes/notebook/:id` is more specific than `/notes/:id`; go_router matches by segment count so `/notes/notebook/5` hits the notebook route. Keep the notebook route listed before `/notes/:id`.

- [ ] **Step 6: Add the drawer tile**

In `app_drawer.dart`, in the FEATURES section (after the Trackers tile, before Planner), add:
```dart
            _DrawerTile(
              icon: Icons.sticky_note_2_rounded,
              label: 'Notes',
              subtitle: 'Notebooks for rounds & knowledge',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/notes');
              },
            ),
```

- [ ] **Step 7: Analyze (note: editor screen not yet written — add a temporary stub so routing compiles, replaced in Task 7)**

Create a minimal `note_editor_screen.dart` stub:
```dart
import 'package:flutter/material.dart';

class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({required this.noteId, super.key});
  final int noteId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Editor (Task 7)')));
}
```
Run: `flutter analyze lib/features/notes lib/core/router/app_router.dart lib/features/settings/presentation/widgets/app_drawer.dart`
Expected: "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add lib/features/notes lib/core/router/app_router.dart lib/features/settings/presentation/widgets/app_drawer.dart
git commit -m "feat: notes overview + notebook detail screens, routes, drawer tile"
```

---

## Task 7: Note editor + block widgets + photo viewer

**Files:**
- Create: `lib/features/notes/presentation/widgets/text_block_view.dart`
- Create: `lib/features/notes/presentation/widgets/checkbox_block_view.dart`
- Create: `lib/features/notes/presentation/widgets/photo_block_view.dart`
- Create: `lib/features/notes/presentation/screens/photo_view_screen.dart`
- Replace: `lib/features/notes/presentation/screens/note_editor_screen.dart` (stub → real)

**Interfaces:**
- Consumes: `noteBlocksProvider`, `notesRepositoryProvider`, `notesDaoProvider`, `imageStorageServiceProvider`, `NoteBlockType`.

- [ ] **Step 1: `photo_view_screen.dart`**

Full-screen viewer: `Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black), body: Center(child: InteractiveViewer(child: Image.file(File(path)))))`. Param: resolved absolute `path`.

- [ ] **Step 2: `photo_block_view.dart`**

`ConsumerWidget`, params `NoteBlock block`, `VoidCallback onRemove`. `FutureBuilder<String>` on `imageStorageServiceProvider.resolvePath(block.content!)`; when it has data, check `exists`:
- exists → `GestureDetector(onTap: push PhotoViewScreen)` wrapping `ClipRRect(Image.file(...))`, with a small top-right `IconButton(Icons.close)` calling `onRemove`.
- missing → a bordered placeholder card: `Icons.broken_image_outlined` + "Image unavailable" + the remove button.

- [ ] **Step 3: `checkbox_block_view.dart`**

Row: `Checkbox(value: block.checked, onChanged: (v) => dao.setBlockChecked(block.id, v))` + an inline `TextField` (controller seeded from `block.content`) that writes on focus-loss via `updateBlockContent`. Strikethrough + dimmed text style when `checked`.

- [ ] **Step 4: `text_block_view.dart`**

A borderless multi-line `TextField` (controller seeded from `block.content`), `InputBorder.none`, hint "Write…", writes via `updateBlockContent` on focus-loss.

- [ ] **Step 5: `note_editor_screen.dart` (real)**

`ConsumerStatefulWidget`, param `noteId`. On init, load the note row (`dao` one-shot select) to seed the title controller.
- AppBar: back button; when leaving, save title if changed and delete the note if it's empty (no title, no non-empty blocks) via a helper `_saveAndMaybeDelete()`. Use `PopScope` / `onPopInvoked` to run it.
- Body `Column`: a title `TextField` (bold, no border), then `Expanded(child: ListView)` of block widgets from `noteBlocksProvider(noteId)`, dispatched by `NoteBlockType.parse(block.type)`.
- Bottom `BottomAppBar` with three actions:
  - **+ Text** → `dao.addBlock(noteId, NoteBlockType.text, content:'', orderIndex:_nextOrder)` + `touchNote`.
  - **☑ Checkbox** → same with `NoteBlockType.checkbox`.
  - **📷 Photo** → `showModalBottomSheet` choosing Camera/Gallery → `repo.addPhotoBlock(noteId, source, _nextOrder, now: DateTime.now())`.
  - `_nextOrder` = current block count (append at end).
- Title edits: write via `dao.updateNoteTitle(noteId, text, DateTime.now())` on focus-loss + on pop.
- Photo remove: `repo.removePhotoBlock(block, now: DateTime.now())` (confirm dialog first).
- After any `await` inside a callback that then writes state, re-read providers via `ref.read` fresh (no stale snapshot).

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/features/notes`
Expected: "No issues found!"

- [ ] **Step 7: Commit**

```bash
git add lib/features/notes
git commit -m "feat: note block editor — text/checkbox/photo blocks + photo viewer"
```

---

## Task 8: Backup wiring, docs, ship

**Files:**
- Modify: `lib/core/backup/backup_service.dart`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: the 3 tables (Task 1). Export already covers them via `allTables`; only import (delete order + batch insert) needs the tables.

- [ ] **Step 1: Add the 3 tables to import**

In `backup_service.dart` `importFromJson` batch, after the task-organization inserts (line ~100), before `workShifts`:
```dart
        // Notes (v14): notebooks → notes → note_blocks (FK order).
        b.insertAll(
            _db.notebooks, rowsFor('notebooks').map(Notebook.fromJson));
        b.insertAll(_db.notes, rowsFor('notes').map(Note.fromJson));
        b.insertAll(
            _db.noteBlocks, rowsFor('note_blocks').map(NoteBlock.fromJson));
```
In `_deleteOrder`, add children-first at the top (before `trackerLogValues` is fine as long as note_blocks precedes notes precedes notebooks):
```dart
        _db.noteBlocks,
        _db.notes,
        _db.notebooks,
```

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all tests pass (existing + the new migration/dao/filename tests).

- [ ] **Step 3: Analyze the whole project**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Update CLAUDE.md**

- Add a feature-table row under "What is BUILT": Notes system v1 (schema v14; notebooks/notes/note_blocks; block editor with text/checkbox/photo; drawer → Notes; photos as files in `note_images/`, filenames in DB; photo bytes NOT in JSON backup — cloud sync is the fix).
- Update the schema line to **v14** and add the v14 bullet.
- Add a Phase 2 backlog row: headings/formatting, drag-reorder blocks, notes in Archived screen, Notes-as-a-tab, notebook custom-image logos.

- [ ] **Step 5: Bump version + commit**

Bump `pubspec.yaml` `version:` (next patch, e.g. `1.7.0+10`).
```bash
git add lib/core/backup/backup_service.dart CLAUDE.md pubspec.yaml
git commit -m "feat: notes in backup restore + docs + version bump (Notes v1)"
```

- [ ] **Step 6: Device deploy + release**

- `flutter run -d <device>` (or install the release APK) and walk the Manual Test Steps.
- `flutter build apk --release`.
- Publish via `gh release create vX.Y.Z --repo manjo00/uplan-releases …` with the APK.

### 🧪 Manual Test Steps
1. Drawer → **Notes** → tap **+** → create a notebook "Rounds" (pick an emoji + color) → it appears.
2. Open "Rounds" → **+** → a blank note opens in the editor.
3. Type a title. Tap **+ Text**, write a line. Tap **☑ Checkbox**, write "Check vitals", tick it → it strikes through.
4. Tap **📷 Photo** → Gallery → pick an image → it appears inline. Tap it → full-screen zoom → back.
5. Back out → the note shows in the notebook with its title, a 📷 badge, and "Today".
6. Reopen it → title, text, checked box, and photo all persisted.
7. Remove the photo (✕ → confirm) → gone. Notebook ⋮ → Delete → its notes move to **Unfiled** (check the Unfiled tile).
8. Create a note with no title/blocks, back out → it does not litter the list (auto-deleted).

---

## Self-Review

**Spec coverage:** notebooks/notes/note_blocks (Task 1) ✓; NoteBlockType + filename helper (Task 2) ✓; NotesDao all methods (Task 3) ✓; ImageStorageService + image_picker (Task 4) ✓; repository + providers (Task 5) ✓; overview/detail/nav/drawer (Task 6) ✓; editor + block widgets + viewer (Task 7) ✓; backup + docs + ship (Task 8) ✓. Deferred items (headings, reorder, archive UI, tab) correctly excluded and logged. All spec sections covered.

**Placeholder scan:** UI-heavy Tasks 6–7 describe widgets in prose rather than full code (device-verified surfaces); the testable layers (schema, enum, filename, DAO) have complete code + tests. No TBD/TODO left.

**Type consistency:** `NotesDao` method names/signatures in Task 3 match their calls in Tasks 5–7; `NoteBlockType.storageKey`/`.parse` consistent; generated names (`notebooks`/`Notebook`, `notes`/`Note`, `noteBlocks`/`NoteBlock`) used consistently in DAO, tests, and backup.
