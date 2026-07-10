# Notes System (Block Editor) — Phase 1 Design

**Date:** 2026-07-10
**Status:** Approved (design) — pending spec review
**Feedback origin:** `feedback/app.md` → Additions → "Add a new note system. For my
rounds and accumulated knowledge." Photos requested in the same session.

## Goal
A notebook-organized note-taking feature where each note is a stack of editable
**blocks** (text, tappable checkbox, inline photo) — covering both quick rounds
notes/checklists and a growing personal knowledge base, with photo attachments
baked in from day one.

## Architecture (one sentence)
Follows the app's standard five-layer pipeline (Table → DAO → Repository →
Provider → Screen/Widget) exactly like the Lists feature, plus a small reusable
`ImageStorageService` for copying picked photos to app-documents storage and
resolving them back to paths at display time.

## Tech Stack
- Drift (schema **v14**), Riverpod (manual `Provider`/`StreamProvider`, matching
  the Lists DAO wiring), go_router (full-screen routes), `image_picker` (new),
  `path_provider` (already a dependency).

---

## Global Constraints
- **Flutter 3.44 / Dart null-safety strict.** No `!` null-bang unless unavoidable.
- **Colors** via `.toARGB32()`, never `.value`.
- **Drift migrations** via `m.createTable()` / `m.addColumn()` only — never raw SQL.
- **Schema goes 13 → 14.** Bump `schemaVersion` and add an `if (from < 14)` block.
- **`const` constructors** wherever possible; one widget per file; extract
  subwidgets liberally.
- **Re-read `state.valueOrNull` after every `await`** in any Riverpod notifier.
- **Run `dart run build_runner build --delete-conflicting-outputs`** after the
  schema + table changes (generates `app_database.g.dart`).
- **New dependency `image_picker`** — announced to the user before adding to
  `pubspec.yaml`.
- Every feature ends with `flutter analyze` clean + `### 🧪 Manual Test Steps`.

---

## Scope

### Phase 1 delivers
- **Notebooks** (folders): create, rename, recolor, pick an emoji icon, delete.
- **Notes** inside a notebook (or Unfiled): create, open, delete; title + blocks.
- **Three block types:** `text`, `checkbox` (tappable, strikethrough when done),
  `photo` (inline, from camera or gallery, tap to view full-screen, removable).
- Add / edit / delete blocks; automatic save.
- Reached from **drawer → Notes** (full-screen routes; not a bottom-nav tab yet).

### Deferred to Phase 2 (explicitly out of scope now)
- Heading blocks + inline bold/italic formatting.
- Drag-to-reorder blocks.
- Wiring notes/notebooks into the **Archived** screen (the `archivedAt` columns
  and `archivedAt IS NULL` query filters ARE added now, so Phase 2 is a small
  UI step, not a migration).
- Promoting Notes to a bottom-nav `AppTab`.
- Custom-image logos on notebooks (shares the same `ImageStorageService`; its
  own future feature).

---

## Data Model — schema v14 (3 new tables)

Registered in `@DriftDatabase(tables: [...])` in
`lib/core/database/app_database.dart`. Patterns mirror the existing Lists tables
(`notebookId NULL = "Unfiled"`, exactly like `listId NULL = "Captured"`; nullable
`archivedAt` exactly like the archive system).

### `notebooks` — `lib/features/notes/data/tables/notebooks_table.dart`
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK autoincrement | |
| name | TEXT | |
| colorValue | INTEGER | ARGB int (`.toARGB32()`) |
| icon | TEXT | emoji, default '📓' |
| orderIndex | INTEGER | |
| createdAt | DATETIME | |
| archivedAt | DATETIME nullable | NULL = active (Phase 2 archive UI) |

### `notes` — `lib/features/notes/data/tables/notes_table.dart`
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK autoincrement | |
| notebookId | INTEGER nullable, FK → notebooks **SET NULL** | NULL = "Unfiled" |
| title | TEXT | may be empty string |
| createdAt | DATETIME | |
| updatedAt | DATETIME | bumped on any edit; sorts newest-edited first; cloud-sync LWW key |
| archivedAt | DATETIME nullable | NULL = active |

### `note_blocks` — `lib/features/notes/data/tables/note_blocks_table.dart`
| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK autoincrement | |
| noteId | INTEGER, FK → notes **CASCADE** | delete note → delete its blocks |
| type | TEXT | `'text'` \| `'checkbox'` \| `'photo'` |
| content | TEXT nullable | text body (text/checkbox) OR image **filename** (photo) |
| checked | BOOL default false | meaningful only for `checkbox` |
| orderIndex | INTEGER | block order within the note |

**FK pragma** is already `ON` app-wide (`beforeOpen`), so CASCADE/SET NULL fire.

### Block type — `lib/features/notes/data/models/note_block_type.dart`
A small pure enum mirroring `HomeBlockType`'s shape:
```dart
enum NoteBlockType {
  text,
  checkbox,
  photo;

  String get storageKey => name; // 'text' | 'checkbox' | 'photo'

  static NoteBlockType parse(String? raw) => switch (raw) {
        'checkbox' => NoteBlockType.checkbox,
        'photo' => NoteBlockType.photo,
        _ => NoteBlockType.text, // null / unknown → safe default
      };
}
```

---

## Image Storage — `lib/core/images/image_storage_service.dart`

Reusable across future features (task attachments, notebook logos). Stateless
service constructed with no args; provided via a plain `Provider`.

**Responsibilities:**
- `Future<String?> pickAndStore(ImageSource source)` — uses `image_picker` to
  pick from `ImageSource.camera` / `ImageSource.gallery`, copies the returned
  `XFile`'s bytes into `<appDocs>/note_images/`, returns the generated
  **filename** (not full path). Returns `null` if the user cancels.
- `Future<String> resolvePath(String filename)` — returns the absolute path
  `<appDocs>/note_images/<filename>` for display. The full app-documents path can
  change between installs, so we persist only the filename and resolve at runtime.
- `Future<bool> exists(String filename)` — for the "image unavailable" fallback.
- `Future<void> delete(String filename)` — removes the file (best-effort; ignores
  a missing file).

**Filename generation (pure, unit-testable):**
`lib/core/images/image_filename.dart` exports
`String buildImageFilename({required int seed, required String extension})`
returning `img_<seed>.<ext>` where `seed` is a caller-supplied monotonic value
(e.g. `DateTime.now().microsecondsSinceEpoch`). Keeping the timestamp OUTSIDE the
function makes it deterministic and testable. Extension is taken from the picked
file (defaults to `jpg`).

**Cleanup rules:**
- Removing a `photo` block deletes its file.
- Deleting a note gathers its `photo` blocks' filenames FIRST, deletes those
  files, THEN deletes the note row (CASCADE removes the block rows).

---

## DAO — `lib/features/notes/data/dao/notes_dao.dart`

Constructed directly (like `ListsDao`), NOT added to the generated `daos:` list.
Provided via `Provider<NotesDao>((ref) => NotesDao(ref.watch(appDatabaseProvider)))`.

**Notebooks**
- `Stream<List<Notebook>> watchNotebooks()` — `archivedAt IS NULL`, ordered by
  `orderIndex`.
- `Future<int> createNotebook({required String name, required int colorValue, required String icon})`
  — appends at `max(orderIndex)+1`.
- `Future<void> renameNotebook(int id, String name, int colorValue, String icon)`
- `Future<void> setNotebookArchived(int id, DateTime? at)`
- `Future<void> deleteNotebook(int id)` — its notes' `notebookId` SET NULL (become Unfiled).

**Notes**
- `Stream<List<Note>> watchNotes(int? notebookId)` — `archivedAt IS NULL`,
  filtered by notebook (or `notebookId IS NULL` when `null` = Unfiled), ordered by
  `updatedAt DESC`.
- `Future<int> createNote({int? notebookId, required DateTime now})` — empty title,
  `createdAt == updatedAt == now`.
- `Future<void> updateNoteTitle(int id, String title, DateTime now)` — bumps `updatedAt`.
- `Future<void> touchNote(int id, DateTime now)` — bumps `updatedAt` only.
- `Future<void> setNoteArchived(int id, DateTime? at)`
- `Future<List<NoteBlock>> getBlocks(int noteId)` — for pre-delete photo cleanup.
- `Future<void> deleteNote(int id)`.

**Blocks**
- `Stream<List<NoteBlock>> watchBlocks(int noteId)` — ordered by `orderIndex`.
- `Future<int> addBlock({required int noteId, required NoteBlockType type, String? content, required int orderIndex})`
- `Future<void> updateBlockContent(int id, String content)`
- `Future<void> setBlockChecked(int id, bool checked)`
- `Future<void> deleteBlock(int id)`.

---

## Repository — `lib/features/notes/data/repositories/notes_repository.dart`

Thin wrapper over the DAO + `ImageStorageService` for the photo-aware operations
(so screens never orchestrate file + DB together):
- `Future<void> addPhotoBlock(int noteId, ImageSource source, int orderIndex, {required DateTime now})`
  — `pickAndStore` → if non-null, `addBlock(type: photo, content: filename)` →
  `touchNote`. No-op if the pick was cancelled.
- `Future<void> removePhotoBlock(NoteBlock block, {required DateTime now})` —
  delete file (if `content != null`) → `deleteBlock` → `touchNote`.
- `Future<void> deleteNoteWithPhotos(int noteId)` — gather photo filenames →
  delete files → `deleteNote`.
- Passes text/checkbox mutations straight through, bumping `updatedAt` via
  `touchNote` on the enclosing note.

---

## Providers — `lib/features/notes/presentation/providers/notes_providers.dart`
- `appDatabaseProvider` (existing) → `notesDaoProvider` → `notesRepositoryProvider`.
- `imageStorageServiceProvider`.
- `notebooksProvider` = `StreamProvider(watchNotebooks)`.
- `notesForNotebookProvider = StreamProvider.family<List<Note>, int?>` (nullable
  key = Unfiled).
- `noteBlocksProvider = StreamProvider.family<List<NoteBlock>, int>`.

---

## Screens & Widgets (`lib/features/notes/presentation/`)

### `screens/notes_overview_screen.dart` — "Notebooks"
- AppBar "Notes"; a grid/list of notebook tiles (icon + name + note count),
  plus a fixed **"Unfiled"** entry for `notebookId IS NULL` notes.
- FAB → create-notebook dialog (reuse the Lists `showListFormDialog` pattern:
  name + color; add an emoji field). Tap a notebook → notebook detail.

### `screens/notebook_detail_screen.dart`
- AppBar = notebook name + ⋮ (rename/recolor, delete). List of `NoteTile`s
  (title or first text block as preview, `updatedAt` relative date, a 📷 count if
  it has photos), newest-edited first. FAB → create a blank note and push the editor.

### `screens/note_editor_screen.dart` — the block editor
- AppBar: back (auto-saves), title `TextField` in the body top.
- Body: a `ListView` of block widgets in `orderIndex` order (Phase 1: no reorder).
- Bottom toolbar: **+ Text · ☑ Checkbox · 📷 Photo**. Photo shows a
  camera/gallery chooser (bottom sheet). New block inserts after the focused
  block, else appends.
- Auto-save model:
  - **checkbox toggle** and **photo add/remove** → write immediately.
  - **text edits** (title and text/checkbox content) → write on focus-loss and on
    screen pop (debounced; never a write per keystroke). Every write bumps
    `updatedAt`.
- Empty note (no title, no non-empty blocks) on pop → deleted, so abandoned
  "new note" taps don't litter the notebook.

### `widgets/note_block_editor.dart` (dispatch) + one file per block widget
- `widgets/text_block_view.dart` — borderless auto-growing `TextField`.
- `widgets/checkbox_block_view.dart` — `Checkbox` + inline `TextField`;
  strikethrough + dimmed when `checked`.
- `widgets/photo_block_view.dart` — `FutureBuilder` on `resolvePath`; renders
  `Image.file`; tap → full-screen viewer; long-press or a corner ✕ → remove
  (confirm). If `exists` is false → an "Image unavailable" placeholder card.
- `widgets/notebook_tile.dart`, `widgets/note_tile.dart`.

### `screens/photo_view_screen.dart` (or a simple dialog)
- Full-screen `InteractiveViewer` (pinch-zoom) of one image; back to dismiss.

---

## Navigation — `lib/core/router/app_router.dart`
Full-screen routes (outside the shell), like `/schedule` and `/archived`:
- `/notes` → `NotesOverviewScreen`
- `/notes/notebook/:id` → `NotebookDetailScreen` (id, or the literal `unfiled`)
- `/notes/:id` → `NoteEditorScreen` (note id via `state.extra` or path param)

Drawer: add a **Notes** tile in the FEATURES section of
`lib/features/settings/presentation/widgets/app_drawer.dart` (icon
`Icons.sticky_note_2_rounded`, subtitle "Notebooks for rounds & knowledge",
`context.push('/notes')`).

---

## Backup interaction (known Phase-1 limitation)
`BackupService` exports table rows as JSON. Phase 1 adds the three new tables to
the export/restore set (so note text, checkboxes, structure round-trip), but the
photo **image files are NOT included** — a restore on a fresh device shows the
"Image unavailable" placeholder for photos. This is documented in-app (a one-line
note in the export section) and in CLAUDE.md. The real cross-device photo solution
is cloud sync (Supabase Storage), which is the next major feature — so no
throwaway photo-in-JSON packer is built now.

---

## Testing (TDD, per project convention)

### `test/core/database/notes_migration_test.dart`
- Open at v13, migrate to v14, assert `notebooks` / `notes` / `note_blocks` exist
  and accept an insert (mirror `archive_schema_test.dart` setup).

### `test/features/notes/notes_dao_test.dart` (DAOs constructed directly)
- create notebook → appears in `watchNotebooks`.
- create note in notebook → appears in `watchNotes(notebookId)`, not in another
  notebook's stream, and Unfiled note appears in `watchNotes(null)`.
- add text + checkbox + photo blocks → `watchBlocks` returns them in `orderIndex`.
- `setBlockChecked(true)` persists.
- `deleteNote` cascades: its blocks are gone.
- `deleteNotebook` sets its notes' `notebookId` to NULL (they move to Unfiled).
- archived notebook/note excluded from the active streams.

### `test/core/images/image_filename_test.dart` (pure)
- `buildImageFilename(seed: 123, extension: 'png') == 'img_123.png'`.
- default extension is `jpg`; extension is lowercased; a leading dot is stripped.

*(File I/O in `ImageStorageService` and the editor auto-save are verified via the
device Manual Test Steps, not unit tests — filesystem + `image_picker` need a real
platform.)*

---

## New Dependency
- **`image_picker`** — official Flutter plugin to pick an image from the camera or
  gallery. Adds camera/photo-library usage; on Android needs no manifest change
  for gallery, camera capture uses the system camera app (no `CAMERA` permission
  required when delegating to it). Announced before adding.

---

## File Manifest (new unless noted)
```
lib/features/notes/
  data/
    tables/      notebooks_table.dart, notes_table.dart, note_blocks_table.dart
    models/      note_block_type.dart
    dao/         notes_dao.dart
    repositories/ notes_repository.dart
  presentation/
    providers/   notes_providers.dart
    screens/     notes_overview_screen.dart, notebook_detail_screen.dart,
                 note_editor_screen.dart, photo_view_screen.dart
    widgets/     notebook_tile.dart, note_tile.dart, note_block_editor.dart,
                 text_block_view.dart, checkbox_block_view.dart, photo_block_view.dart
lib/core/images/
  image_storage_service.dart, image_filename.dart
test/core/database/notes_migration_test.dart
test/features/notes/notes_dao_test.dart
test/core/images/image_filename_test.dart

Modify:
  lib/core/database/app_database.dart          (register tables, v14 migration)
  lib/core/router/app_router.dart              (3 routes)
  lib/features/settings/.../app_drawer.dart    (Notes feature tile)
  lib/core/backup/backup_service.dart          (export/restore 3 new tables)
  pubspec.yaml                                 (image_picker)
  CLAUDE.md                                    (feature row, schema v14, backup note)
```

## Out of scope (v1)
Reorder blocks, headings/rich formatting, notes in the Archived screen UI,
notes-as-a-tab, notebook custom-image logos, sharing/export of a single note,
per-note reminders, photo-in-backup.
