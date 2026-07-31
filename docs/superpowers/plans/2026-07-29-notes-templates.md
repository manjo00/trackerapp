# Notes Templates + Insert-Anywhere Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use `- [ ]` checkboxes.

**Goal:** Note templates (flagged notes you can save, build, and instantiate) + insert-new-blocks-after-the-current-line + fix the format bar hiding behind the keyboard.

**Architecture:** A template is a `notes.isTemplate = true` note, hidden from normal views, copied into a target note when used. The editor toolbar becomes a keyboard accessory (in the body, above the keyboard) with a persistent add-row (insert-after-current) and a conditional format-row.

**Tech Stack:** Drift (schema v18), Riverpod, go_router, ImageStorageService.

## Global Constraints

- Migrations via `m.addColumn()` only. Colors via `.toARGB32()`. New column defaults false → no backfill.
- `content` never touched by copy/format. Templates excluded from every active note view.
- Photo blocks are copied by **duplicating the file** (never share a filename).
- `flutter analyze` clean; DAO/repo copy logic unit-tested; end with 🧪 steps; deploy to phone.

---

### Task 1: Keyboard-accessory toolbar + insert-after-current

**Files:**
- Modify: `lib/features/notes/presentation/screens/note_editor_screen.dart`
- Modify: `lib/features/notes/data/dao/notes_dao.dart` (extend `insertBlockAfter`)

**Interfaces:**
- Produces: `insertBlockAfter` accepts optional formatting; `_addBlock` inserts after the focused block.

- [ ] **Step 1: Extend `insertBlockAfter` to carry formatting (defaults preserve today)**

In `notes_dao.dart`, change the insert inside `insertBlockAfter` to include the flag columns with body defaults:

```dart
        return into(noteBlocks).insert(NoteBlocksCompanion.insert(
          noteId: noteId,
          type: type.storageKey,
          content: Value(content),
          orderIndex: Value(afterOrderIndex + 1),
        ));
```
(No signature change needed for Task 1 — new blocks are unformatted body, which is what the defaults already give. Leave as-is; this step is a no-op checkpoint confirming defaults are correct.)

- [ ] **Step 2: `_addBlock` inserts after the focused line**

In `note_editor_screen.dart`, replace `_addBlock`:

```dart
  Future<void> _addBlock(NoteBlockType type) async {
    final dao = ref.read(notesDaoProvider);
    final List<NoteBlock> blocks =
        ref.read(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];
    final NoteBlock? focused = _focusedBlockId == null
        ? null
        : blocks.where((b) => b.id == _focusedBlockId).firstOrNull;

    final int id;
    if (focused != null) {
      id = await dao.insertBlockAfter(
        noteId: widget.noteId,
        type: type,
        content: '',
        afterOrderIndex: focused.orderIndex,
      );
    } else {
      id = await dao.addBlock(
          noteId: widget.noteId, type: type, content: '', orderIndex: _nextOrder);
    }
    await dao.touchNote(widget.noteId, DateTime.now());
    if (mounted) setState(() => _focusRequestId = id);
  }
```

And `_addDividerBlock` inserts after the focused line too:

```dart
  Future<void> _addDividerBlock() async {
    final dao = ref.read(notesDaoProvider);
    final List<NoteBlock> blocks =
        ref.read(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];
    final NoteBlock? focused = _focusedBlockId == null
        ? null
        : blocks.where((b) => b.id == _focusedBlockId).firstOrNull;
    if (focused != null) {
      await dao.insertBlockAfter(
          noteId: widget.noteId,
          type: NoteBlockType.divider,
          content: null,
          afterOrderIndex: focused.orderIndex);
    } else {
      await dao.addBlock(
          noteId: widget.noteId,
          type: NoteBlockType.divider,
          content: null,
          orderIndex: _nextOrder);
    }
    await dao.touchNote(widget.noteId, DateTime.now());
  }
```

- [ ] **Step 3: Move the toolbar into the body as a keyboard accessory**

In `build()`, drop `bottomNavigationBar` for the normal editor and make the body a Column: the scroll area in `Expanded`, the toolbar beneath it. Keep `resizeToAvoidBottomInset` at its default (true) so the Column's bottom sits above the keyboard.

Replace the Scaffold body/bottom for the non-edit-lines case:

```dart
        body: _editingLines
            ? _editLinesBody(blocks)
            : Column(
                children: [
                  Expanded(child: _editorBody(blocks)),
                  _bottomBar(blocks),
                ],
              ),
        bottomNavigationBar: _editingLines ? null : null,
```

(Edit-lines mode keeps its own body + no toolbar.) Remove the old
`bottomNavigationBar: _editingLines ? null : _bottomBar(blocks)` line.

- [ ] **Step 4: Two-row bar — format row (conditional) above add row (always)**

Rewrite `_bottomBar` to stack both rows, wrapped in `TextFieldTapRegion` and `SafeArea`:

```dart
  Widget _bottomBar(List<NoteBlock> blocks) {
    final NoteBlock? focused = _focusedBlockId == null
        ? null
        : blocks.where((b) => b.id == _focusedBlockId).firstOrNull;
    final NoteBlockType? kind =
        focused == null ? null : NoteBlockType.parse(focused.type);
    final bool formattable =
        kind == NoteBlockType.text || kind == NoteBlockType.checkbox;
    final dao = ref.read(notesDaoProvider);

    return TextFieldTapRegion(
      child: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (formattable)
                _FormatRow(
                  block: focused!,
                  isText: kind == NoteBlockType.text,
                  onHeading: (l) =>
                      dao.setBlockFormat(focused.id, headingLevel: l),
                  onBold: () =>
                      dao.setBlockFormat(focused.id, bold: !focused.bold),
                  onItalic: () =>
                      dao.setBlockFormat(focused.id, italic: !focused.italic),
                  onHighlight: () => dao.setBlockFormat(focused.id,
                      highlighted: !focused.highlighted),
                ),
              _AddRow(
                onText: () => _addBlock(NoteBlockType.text),
                onCheckbox: () => _addBlock(NoteBlockType.checkbox),
                onPhoto: _addPhoto,
                onDivider: _addDividerBlock,
                onTemplate: _pickTemplateToInsert, // Task 6
              ),
            ],
          ),
        ),
      ),
    );
  }
```

Rename the old `_FormatBar` → `_FormatRow` and `_BlockToolbar` → `_AddRow`, each returning a plain `SizedBox(height: 52, child: Row(...))` (NOT a `BottomAppBar`, since they're now inside the body). `_AddRow` gains an `onTemplate` button (`Icons.dashboard_customize_rounded`, tooltip "Insert template"). For Task 1, stub `_pickTemplateToInsert` as an empty `Future<void>` method (filled in Task 6).

- [ ] **Step 5: Analyze + device check (the key fix)**

Run: `flutter analyze lib/features/notes` → clean. Build + install; open a note, tap a line → **the format row sits directly above the keyboard** (not hidden); tap Checkbox with the cursor on a line → the new checkbox lands **right after that line**.

- [ ] **Step 6: Commit**

```bash
git add lib/features/notes
git commit -m "feat(notes): keyboard-accessory toolbar + insert-after-current line"
```

---

### Task 2: Schema v18 — notes.isTemplate

**Files:**
- Modify: `lib/features/notes/data/tables/notes_table.dart`, `notes_dao.dart`, `lib/core/database/app_database.dart`
- Test: `test/features/notes/templates_test.dart`

- [ ] **Step 1: Column**

In `notes_table.dart`:

```dart
  /// True = this note is a reusable template (hidden from notebooks; lives in
  /// the Templates area). Copied into a new/target note when "used".
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
```

- [ ] **Step 2: Schema bump + migration** — `schemaVersion => 18;` and:

```dart
          if (from < 18) {
            // Note templates: a flag on notes. Existing notes stay isTemplate
            // = false (normal notes) — nothing to backfill.
            await m.addColumn(notes, notes.isTemplate);
          }
```

- [ ] **Step 3: DAO — exclude templates + watchTemplates + createNote flag**

In `notes_dao.dart`:
- `watchNotes`: add `..where((n) => n.isTemplate.equals(false))`.
- `watchLastNoteEditByNotebook`: add `& notes.isTemplate.equals(false)` to its `where`.
- `createNote`: add `bool isTemplate = false` param → `isTemplate: Value(isTemplate)` in the companion.
- Add:

```dart
  /// Active templates, most-recently-edited first.
  Stream<List<Note>> watchTemplates() => (select(notes)
        ..where((n) => n.archivedAt.isNull() & n.isTemplate.equals(true))
        ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
      .watch();
```

- [ ] **Step 4: Regenerate** — `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 5: Test (exclusion + createNote flag)** — new `templates_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 29);
  setUp(() { db = AppDatabase.forTesting(NativeDatabase.memory()); dao = NotesDao(db); });
  tearDown(() async => db.close());

  test('templates are excluded from notebook views and listed separately', () async {
    final normal = await dao.createNote(now: now);
    final tmpl = await dao.createNote(now: now, isTemplate: true);
    expect((await dao.watchNotes(null).first).map((n) => n.id), [normal]);
    expect((await dao.watchTemplates().first).map((n) => n.id), [tmpl]);
  });
}
```

Run: `flutter test test/features/notes/templates_test.dart` → PASS.

- [ ] **Step 6: Commit** — `feat(notes): schema v18 notes.isTemplate + watchTemplates`.

---

### Task 3: DAO insertBlocksAt + ImageStorageService.duplicate

**Files:**
- Modify: `lib/features/notes/data/dao/notes_dao.dart`, `lib/core/images/image_storage_service.dart`
- Test: extend `templates_test.dart`, `test/features/notes/notes_dao_test.dart`

- [ ] **Step 1: `insertBlocksAt` (batch, order-shifting)**

```dart
  /// Inserts [companions] (already carrying every field) starting at
  /// [atOrderIndex], shifting existing blocks at/after that index down by the
  /// batch size. One transaction. Used to instantiate/insert a template.
  Future<void> insertBlocksAt(
    int noteId,
    int atOrderIndex,
    List<NoteBlocksCompanion> companions,
  ) =>
      transaction(() async {
        final int n = companions.length;
        if (n == 0) return;
        final List<NoteBlock> after = await (select(noteBlocks)
              ..where((b) =>
                  b.noteId.equals(noteId) &
                  b.orderIndex.isBiggerOrEqualValue(atOrderIndex)))
            .get();
        for (final NoteBlock b in after) {
          await (update(noteBlocks)..where((r) => r.id.equals(b.id)))
              .write(NoteBlocksCompanion(orderIndex: Value(b.orderIndex + n)));
        }
        for (int i = 0; i < n; i++) {
          await into(noteBlocks).insert(companions[i].copyWith(
            noteId: Value(noteId),
            orderIndex: Value(atOrderIndex + i),
          ));
        }
      });
```

- [ ] **Step 2: `ImageStorageService.duplicate`**

```dart
  /// Copies the file backing [filename] to a fresh filename (returned), so a
  /// copied photo block owns its own file. Returns [filename] unchanged if the
  /// source is missing (nothing to duplicate).
  Future<String> duplicate(String filename) async {
    final Directory dir = await _dir();
    final File src = File(p.join(dir.path, filename));
    if (!await src.exists()) return filename;
    final String ext = p.extension(filename).replaceFirst('.', '');
    final String newName = buildImageFilename(
      seed: DateTime.now().microsecondsSinceEpoch,
      extension: ext.isEmpty ? 'jpg' : ext,
    );
    await src.copy(p.join(dir.path, newName));
    return newName;
  }
```

- [ ] **Step 3: Test `insertBlocksAt`** (add to `notes_dao_test.dart`): create 2 blocks (a,b), `insertBlocksAt(note, 1, [text 'x', text 'y'])`, expect order `[a, x, y, b]`. Run → PASS.

- [ ] **Step 4: Commit** — `feat(notes): insertBlocksAt batch + ImageStorageService.duplicate`.

---

### Task 4: NotesRepository copy operations

**Files:**
- Modify: `lib/features/notes/data/repositories/notes_repository.dart`
- Test: extend `templates_test.dart`

**Interfaces:**
- Produces: `Future<int> saveAsTemplate(int noteId, {required DateTime now})`,
  `Future<int> newNoteFromTemplate(int templateId, {int? notebookId, required DateTime now})`,
  `Future<void> insertTemplateInto(int templateId, int targetNoteId, int afterOrderIndex, {required DateTime now})`.

- [ ] **Step 1: Private copy + the three ops**

```dart
  /// Builds companions for every block of [fromNoteId] (duplicating photo
  /// files so nothing is shared) — ready for insertBlocksAt.
  Future<List<NoteBlocksCompanion>> _copyCompanions(int fromNoteId) async {
    final List<NoteBlock> src = await _dao.getBlocks(fromNoteId)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final List<NoteBlocksCompanion> out = [];
    for (final NoteBlock b in src) {
      String? content = b.content;
      if (b.type == NoteBlockType.photo.storageKey &&
          content != null &&
          content.isNotEmpty) {
        content = await _images.duplicate(content);
      }
      out.add(NoteBlocksCompanion.insert(
        noteId: 0, // set by insertBlocksAt
        type: b.type,
        content: Value(content),
        checked: Value(b.checked),
        orderIndex: const Value(0), // set by insertBlocksAt
        headingLevel: Value(b.headingLevel),
        highlighted: Value(b.highlighted),
        bold: Value(b.bold),
        italic: Value(b.italic),
      ));
    }
    return out;
  }

  Future<int> saveAsTemplate(int noteId, {required DateTime now}) async {
    final Note? src = await _dao.getNote(noteId);
    final int tmpl = await _dao.createNote(now: now, isTemplate: true);
    if (src != null && src.title.isNotEmpty) {
      await _dao.updateNoteTitle(tmpl, src.title, now);
    }
    await _dao.insertBlocksAt(tmpl, 0, await _copyCompanions(noteId));
    return tmpl;
  }

  Future<int> newNoteFromTemplate(int templateId,
      {int? notebookId, required DateTime now}) async {
    final Note? t = await _dao.getNote(templateId);
    final int note = await _dao.createNote(notebookId: notebookId, now: now);
    if (t != null && t.title.isNotEmpty) {
      await _dao.updateNoteTitle(note, t.title, now);
    }
    await _dao.insertBlocksAt(note, 0, await _copyCompanions(templateId));
    return note;
  }

  Future<void> insertTemplateInto(int templateId, int targetNoteId,
      int afterOrderIndex,
      {required DateTime now}) async {
    await _dao.insertBlocksAt(
        targetNoteId, afterOrderIndex + 1, await _copyCompanions(templateId));
    await _dao.touchNote(targetNoteId, now);
  }
```

(Import `note_block_type.dart` if not already.)

- [ ] **Step 2: Test copy preserves formatting + order** — build a note with a H2 bold line + a checked checkbox, `saveAsTemplate`, then `newNoteFromTemplate`, assert the new note's blocks match types/flags/order. Run → PASS.

- [ ] **Step 3: Commit** — `feat(notes): template copy ops (save/instantiate/insert)`.

---

### Task 5: Templates screen + route + overview tile

**Files:**
- Create: `lib/features/notes/presentation/screens/templates_screen.dart`
- Modify: `lib/features/notes/presentation/providers/notes_providers.dart` (templatesProvider), the router, `notes_overview_screen.dart`

- [ ] **Step 1: Provider** — `final templatesProvider = StreamProvider<List<Note>>((ref) => ref.watch(notesDaoProvider).watchTemplates());`

- [ ] **Step 2: TemplatesScreen** — a `ListView` of templates (title or "Untitled", tap → `context.push('/notes/${t.id}')`, ⋮ → rename/delete via existing dao methods), FAB **New template**:

```dart
  Future<void> _newTemplate(BuildContext c, WidgetRef ref) async {
    final id = await ref.read(notesDaoProvider)
        .createNote(now: DateTime.now(), isTemplate: true);
    if (c.mounted) c.push('/notes/$id');
  }
```

- [ ] **Step 3: Route** — add `/notes/templates` → `TemplatesScreen` (place BEFORE `/notes/:id` so "templates" isn't captured as an id).

- [ ] **Step 4: Overview tile** — under Unfiled, a `NotebookTile(icon: '📄', name: 'Templates', ...) onTap push /notes/templates`.

- [ ] **Step 5: Analyze + commit** — `feat(notes): Templates screen + route + overview entry`.

---

### Task 6: Use templates — FAB sheet, editor ⋮, add-row button

**Files:**
- Modify: `notebook_detail_screen.dart`, `note_editor_screen.dart`

- [ ] **Step 1: Notebook `＋` sheet** — replace `_createNote` so that if `templatesProvider` is non-empty it shows a modal sheet: "Blank note" (current behaviour) + one tile per template → `newNoteFromTemplate(t.id, notebookId: notebookId, now)` then `context.push('/notes/$newId')`. No templates → create blank directly.

- [ ] **Step 2: Editor ⋮** — add `Save as template` (→ `saveAsTemplate(widget.noteId, now)`, snackbar "Saved to Templates") and `Insert template` (→ `_pickTemplateToInsert`).

- [ ] **Step 3: `_pickTemplateToInsert`** (also the add-row Templates button):

```dart
  Future<void> _pickTemplateToInsert() async {
    final templates = ref.read(templatesProvider).valueOrNull ?? const [];
    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No templates yet — make one in Templates')));
      }
      return;
    }
    final Note? chosen = await showModalBottomSheet<Note>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final t in templates)
            ListTile(
              leading: const Icon(Icons.dashboard_customize_rounded),
              title: Text(t.title.trim().isEmpty ? 'Untitled' : t.title),
              onTap: () => Navigator.of(c).pop(t),
            ),
        ]),
      ),
    );
    if (chosen == null) return;
    final blocks =
        ref.read(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];
    final NoteBlock? focused = _focusedBlockId == null
        ? null
        : blocks.where((b) => b.id == _focusedBlockId).firstOrNull;
    final int after = focused?.orderIndex ?? (blocks.length - 1);
    await ref.read(notesRepositoryProvider)
        .insertTemplateInto(chosen.id, widget.noteId, after, now: DateTime.now());
  }
```

- [ ] **Step 4: Analyze + full test + commit** — `feat(notes): use templates (new-from-template, save-as, insert)`.

---

### Task 7: Ship

- [ ] **Step 1: Build + install**, run the 🧪 steps.
- [ ] **Step 2: Docs** — STATUS + CLAUDE.md (templates + insert-after-current + keyboard fix). Commit + push.
- [ ] **Step 3: Release (on approval)** — bump pubspec → build → `gh release create v1.11.0 --repo manjo00/uplan-releases ...` (this rolls up rich text + templates).

## 🧪 Manual Test Steps

1. Open a note, tap a line → the **format row sits above the keyboard** (never hidden).
2. Cursor on a line → tap **Checkbox** → new checkbox appears **right under** that line (not at the end).
3. Build a note (e.g. `# Bed 1` / ☐ / divider / `# Bed 2`…) → ⋮ → **Save as template** → snackbar.
4. Drawer → Notes → **Templates** → your template is there; open it → edits like a normal note; **New template** FAB makes a blank one.
5. In a notebook, tap **＋** → sheet offers **Blank** + your templates → pick it → a new note appears pre-structured; fill it in.
6. In an existing note, ⋮ (or add-row **Templates** button) → **Insert template** → its blocks drop in after your cursor.
7. Template with a photo → instantiate → deleting the photo in the new note does **not** break the template's photo (separate files).
8. Templates never show up inside notebooks, Unfiled, the notes grid, or Home recent-notebooks.
9. Back out/reopen everything → persisted.
