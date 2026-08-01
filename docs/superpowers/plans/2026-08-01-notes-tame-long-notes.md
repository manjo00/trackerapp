# "Tame Long Notes" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make long, photo-heavy rounds notes scrollable — fold sections under a heading (A7) and cap any single photo's height (A1).

**Architecture:** A7 is a persisted per-heading `collapsed` flag (schema v19) + a pure `computeSectionFold` helper that tells the editor which blocks to hide and how many are folded; the editor adds a caret to heading rows and a Collapse/Expand-all menu. A1 is a pure-rendering change in `PhotoBlockView` (bounded height, no toggle, no state).

**Tech Stack:** Flutter 3.44 / Dart (null-safe strict), Drift 2.22 (schema v19), Riverpod, image on disk via ImageStorageService.

## Global Constraints
- Drift migrations via `m.addColumn()` only — never raw `ALTER TABLE`.
- Bump `schemaVersion` to **19**; add an `if (from < 19)` migration block.
- Run `dart run build_runner build --delete-conflicting-outputs` after the table change (regenerates `NoteBlock` with the `collapsed` field + `.g.dart`).
- Colors use `.toARGB32()` not `.value`. Prefer `const`. No `!` null-bang.
- Pure logic gets a unit test alongside it. One widget per file, but private helper widgets may share the screen file (matches `_AddRow`/`_FormatRow` in the editor).
- All commands run from `C:\Projects\life_tracker`.
- End the feature with a `### 🧪 Manual Test Steps` section and install on the device.

---

### Task 1: Schema v19 — `note_blocks.collapsed` column + migration

**Files:**
- Modify: `lib/features/notes/data/tables/note_blocks_table.dart`
- Modify: `lib/core/database/app_database.dart:121` (schemaVersion) and the migration `onUpgrade` block (after the `from < 18` block, ~`:253`)
- Test: `test/features/notes/notes_dao_test.dart`

**Interfaces:**
- Produces: `NoteBlock.collapsed` (bool, default false) on the generated data class; column available to the DAO.

- [ ] **Step 1: Write the failing test** — append to `test/features/notes/notes_dao_test.dart` (inside the existing `main()` group; it already builds an in-memory `AppDatabase` + `NotesDao` — mirror the setup used by the `setBlockFormat` test):

```dart
test('new blocks default to collapsed = false', () async {
  final int noteId = await dao.createNote(now: DateTime.now());
  final int blockId = await dao.addBlock(
    noteId: noteId,
    type: NoteBlockType.text,
    content: 'Bed 1',
    orderIndex: 0,
  );
  final NoteBlock b = (await dao.getBlock(blockId))!;
  expect(b.collapsed, isFalse);
});
```

- [ ] **Step 2: Run it — expect a COMPILE failure** (`collapsed` isn't a member yet):

Run: `flutter test test/features/notes/notes_dao_test.dart`
Expected: FAIL — `The getter 'collapsed' isn't defined for the type 'NoteBlock'`.

- [ ] **Step 3: Add the column** — in `note_blocks_table.dart`, after the `italic` column:

```dart
  /// A7 (collapse under headings): true = this HEADING block's section is
  /// folded. Meaningful only on heading text blocks (headingLevel != 0);
  /// other block types ignore it. Default false → existing notes open expanded.
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
```

- [ ] **Step 4: Bump the schema + migrate** — in `app_database.dart` set `int get schemaVersion => 19;` and add, right after the `from < 18` block:

```dart
          if (from < 19) {
            // A7: per-heading collapse state. Default false → no backfill.
            await m.addColumn(noteBlocks, noteBlocks.collapsed);
          }
```

- [ ] **Step 5: Regenerate Drift code:**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: builds with no errors; `NoteBlock` now has `collapsed`.

- [ ] **Step 6: Run the test to verify it passes:**

Run: `flutter test test/features/notes/notes_dao_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit:**

```bash
git add lib/features/notes/data/tables/note_blocks_table.dart lib/core/database/app_database.dart "lib/**/*.g.dart" test/features/notes/notes_dao_test.dart
git commit -m "feat(notes): schema v19 — note_blocks.collapsed for section folding"
```

---

### Task 2: Pure `computeSectionFold` helper + tests

**Files:**
- Create: `lib/features/notes/domain/section_fold.dart`
- Test: `test/features/notes/section_fold_test.dart`

**Interfaces:**
- Produces: `class SectionFold { Set<int> hiddenIds; Map<int,int> hiddenCountByHeadingId; }` and `SectionFold computeSectionFold(List<NoteBlock> blocks)`.
- Consumes: `NoteBlock` (from `app_database.dart`) + `NoteBlockType` (from `../data/models/note_block_type.dart`) — same imports as `note_preview.dart`.

- [ ] **Step 1: Write the failing tests** — `test/features/notes/section_fold_test.dart`. Use a local builder so tests stay readable (named args match the generated `NoteBlock`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/domain/section_fold.dart';

NoteBlock _b(int id, {String type = 'text', int heading = 0, bool collapsed = false, int order = 0}) =>
    NoteBlock(
      id: id, noteId: 1, type: type, content: 't', checked: false,
      orderIndex: order, headingLevel: heading, highlighted: false,
      bold: false, italic: false, collapsed: collapsed,
    );

void main() {
  test('no headings → nothing hidden', () {
    final f = computeSectionFold([_b(1), _b(2, order: 1)]);
    expect(f.hiddenIds, isEmpty);
    expect(f.hiddenCountByHeadingId, isEmpty);
  });

  test('flat: collapsed heading hides its run until the next same-level heading', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true), // A
      _b(2, order: 1), _b(3, order: 2),   // hidden
      _b(4, heading: 1, order: 3),        // B (visible)
      _b(5, order: 4),                    // visible
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2});
  });

  test('nested: collapsing H1 hides its H2 and that H2\'s content', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, heading: 2, order: 1, collapsed: true),
      _b(3, order: 2),
      _b(4, heading: 1, order: 3),
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2}); // count rolls up to the visible H1
  });

  test('collapsing only an inner H2 hides just its run', () {
    final f = computeSectionFold([
      _b(1, heading: 1),
      _b(2, heading: 2, order: 1, collapsed: true),
      _b(3, order: 2),
      _b(4, heading: 1, order: 3),
    ]);
    expect(f.hiddenIds, {3});
    expect(f.hiddenCountByHeadingId, {2: 1});
  });

  test('trailing collapsed section runs to end of note', () {
    final f = computeSectionFold([
      _b(1, order: 0),
      _b(2, heading: 1, order: 1, collapsed: true),
      _b(3, order: 2), _b(4, order: 3),
    ]);
    expect(f.hiddenIds, {3, 4});
    expect(f.hiddenCountByHeadingId, {2: 2});
  });

  test('collapsed heading with nothing under it hides nothing (0 count)', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, heading: 1, order: 1),
    ]);
    expect(f.hiddenIds, isEmpty);
    expect(f.hiddenCountByHeadingId, isEmpty);
  });

  test('non-text blocks under a collapsed heading are hidden too', () {
    final f = computeSectionFold([
      _b(1, heading: 1, collapsed: true),
      _b(2, type: 'checkbox', order: 1),
      _b(3, type: 'photo', order: 2),
    ]);
    expect(f.hiddenIds, {2, 3});
    expect(f.hiddenCountByHeadingId, {1: 2});
  });
}
```

- [ ] **Step 2: Run — expect FAIL** (`section_fold.dart` doesn't exist):

Run: `flutter test test/features/notes/section_fold_test.dart`
Expected: FAIL — target of URI doesn't exist / `computeSectionFold` undefined.

- [ ] **Step 3: Implement the helper** — `lib/features/notes/domain/section_fold.dart`:

```dart
import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// Which blocks are hidden by collapsed headings, and how many blocks are
/// folded under each visible collapsed heading (for a "· N hidden" label).
/// Pure — no I/O — so it is unit-testable.
class SectionFold {
  const SectionFold(this.hiddenIds, this.hiddenCountByHeadingId);

  final Set<int> hiddenIds;
  final Map<int, int> hiddenCountByHeadingId;
}

bool _isHeading(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text && b.headingLevel != 0;

/// A collapsed, visible heading hides every following block until the next
/// heading whose level is the same or higher (smaller number), or end of note.
/// Nested headings inside a hidden run stay hidden; the count rolls up to the
/// outermost visible collapsed heading.
SectionFold computeSectionFold(List<NoteBlock> blocks) {
  final Set<int> hidden = <int>{};
  final Map<int, int> counts = <int, int>{};
  // Open collapsed sections, innermost last. In practice at most one is open
  // (a deeper heading inside a collapsed run is itself hidden, never pushed),
  // but a stack keeps the rule obviously correct.
  final List<({int id, int level})> open = [];

  void hide(int id) {
    hidden.add(id);
    final int owner = open.last.id;
    counts[owner] = (counts[owner] ?? 0) + 1;
  }

  for (final NoteBlock b in blocks) {
    if (_isHeading(b)) {
      while (open.isNotEmpty && open.last.level >= b.headingLevel) {
        open.removeLast();
      }
      final bool hiddenHere = open.isNotEmpty;
      if (hiddenHere) hide(b.id);
      if (b.collapsed && !hiddenHere) {
        open.add((id: b.id, level: b.headingLevel));
      }
    } else if (open.isNotEmpty) {
      hide(b.id);
    }
  }
  return SectionFold(hidden, counts);
}
```

- [ ] **Step 4: Run the tests to verify they pass:**

Run: `flutter test test/features/notes/section_fold_test.dart`
Expected: PASS (all 7).

- [ ] **Step 5: Commit:**

```bash
git add lib/features/notes/domain/section_fold.dart test/features/notes/section_fold_test.dart
git commit -m "feat(notes): computeSectionFold — pure fold logic for collapsible headings"
```

---

### Task 3: DAO — `setBlockCollapsed` + `setAllHeadingsCollapsed`

**Files:**
- Modify: `lib/features/notes/data/dao/notes_dao.dart` (after `setBlockFormat`, ~`:251`)
- Test: `test/features/notes/notes_dao_test.dart`

**Interfaces:**
- Produces: `Future<void> setBlockCollapsed(int id, bool collapsed)` and `Future<void> setAllHeadingsCollapsed(int noteId, bool collapsed)`.

- [ ] **Step 1: Write the failing tests** — append to `notes_dao_test.dart`:

```dart
test('setBlockCollapsed persists', () async {
  final int noteId = await dao.createNote(now: DateTime.now());
  final int h = await dao.addBlock(
      noteId: noteId, type: NoteBlockType.text, content: 'Bed 1', orderIndex: 0);
  await dao.setBlockCollapsed(h, true);
  expect((await dao.getBlock(h))!.collapsed, isTrue);
  await dao.setBlockCollapsed(h, false);
  expect((await dao.getBlock(h))!.collapsed, isFalse);
});

test('setAllHeadingsCollapsed flips only heading blocks', () async {
  final int noteId = await dao.createNote(now: DateTime.now());
  final int h = await dao.addBlock(
      noteId: noteId, type: NoteBlockType.text, content: 'H', orderIndex: 0);
  await dao.setBlockFormat(h, headingLevel: 1);
  final int body = await dao.addBlock(
      noteId: noteId, type: NoteBlockType.text, content: 'x', orderIndex: 1);
  await dao.setAllHeadingsCollapsed(noteId, true);
  expect((await dao.getBlock(h))!.collapsed, isTrue);
  expect((await dao.getBlock(body))!.collapsed, isFalse); // body untouched
});
```

- [ ] **Step 2: Run — expect FAIL** (methods undefined):

Run: `flutter test test/features/notes/notes_dao_test.dart`
Expected: FAIL — `setBlockCollapsed`/`setAllHeadingsCollapsed` undefined.

- [ ] **Step 3: Implement** — add to `NotesDao`:

```dart
  /// A7: fold/unfold a single heading's section.
  Future<void> setBlockCollapsed(int id, bool collapsed) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(collapsed: Value(collapsed)));

  /// A7: Collapse-all / Expand-all — flips every heading block in the note
  /// (headingLevel != 0), leaving body/checkbox/photo/divider untouched.
  Future<void> setAllHeadingsCollapsed(int noteId, bool collapsed) =>
      (update(noteBlocks)
            ..where((b) =>
                b.noteId.equals(noteId) & b.headingLevel.isBiggerThanValue(0)))
          .write(NoteBlocksCompanion(collapsed: Value(collapsed)));
```

- [ ] **Step 4: Run the tests to verify they pass:**

Run: `flutter test test/features/notes/notes_dao_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit:**

```bash
git add lib/features/notes/data/dao/notes_dao.dart test/features/notes/notes_dao_test.dart
git commit -m "feat(notes): DAO setBlockCollapsed + setAllHeadingsCollapsed"
```

---

### Task 4: Editor — caret on headings, hide folded blocks

**Files:**
- Modify: `lib/features/notes/presentation/screens/note_editor_screen.dart`

**Interfaces:**
- Consumes: `computeSectionFold` (Task 2), `NotesDao.setBlockCollapsed` (Task 3).

- [ ] **Step 1: Import the helper** — add near the other domain imports:

```dart
import '../../domain/section_fold.dart';
```

- [ ] **Step 2: Compute the fold + skip hidden blocks** — in `_editorBody`, replace the `else` branch's block loop. Compute the fold once, drop hidden blocks, and pass the fold into `_blockWidget`:

```dart
    final SectionFold fold = computeSectionFold(blocks);
    // ... inside the ListView children, replacing the existing `for` block:
        else
          for (final NoteBlock b in blocks)
            if (!fold.hiddenIds.contains(b.id))
              Padding(
                key: ValueKey(b.id),
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: _blockWidget(b, fold),
              ),
```

- [ ] **Step 3: Route heading text blocks to a caret row** — change `_blockWidget` to take the fold and branch on heading level:

```dart
  Widget _blockWidget(NoteBlock b, SectionFold fold) {
    final bool focusMe = b.id == _focusRequestId;
    switch (NoteBlockType.parse(b.type)) {
      case NoteBlockType.text:
        if (b.headingLevel != 0) {
          return _HeadingLine(
            block: b,
            hiddenCount: fold.hiddenCountByHeadingId[b.id] ?? 0,
            autofocus: focusMe,
            onToggle: () async {
              final dao = ref.read(notesDaoProvider);
              await dao.setBlockCollapsed(b.id, !b.collapsed);
              await dao.touchNote(b.noteId, DateTime.now());
            },
            onSplit: (after) => _splitBlock(b, after),
            onDeleteEmpty: () => _deleteBlock(b),
            onFocus: (id) => setState(() => _focusedBlockId = id),
            onBlur: () => setState(() => _focusedBlockId = null),
          );
        }
        return TextBlockView(
          block: b,
          autofocus: focusMe,
          onSplit: (after) => _splitBlock(b, after),
          onDeleteEmpty: () => _deleteBlock(b),
          onFocus: (id) => setState(() => _focusedBlockId = id),
          onBlur: () => setState(() => _focusedBlockId = null),
        );
      // checkbox / photo / divider cases unchanged
```

- [ ] **Step 4: Add the `_HeadingLine` widget** — at the bottom of the file (with the other private widgets):

```dart
/// A heading row: a fold caret in the left gutter + the editable heading field,
/// with a muted "· N hidden" when the section is folded. Tapping the caret
/// folds/unfolds; tapping the text edits (the caret avoids the tap conflict).
class _HeadingLine extends StatelessWidget {
  const _HeadingLine({
    required this.block,
    required this.hiddenCount,
    required this.onToggle,
    this.autofocus = false,
    this.onSplit,
    this.onDeleteEmpty,
    this.onFocus,
    this.onBlur,
  });

  final NoteBlock block;
  final int hiddenCount;
  final VoidCallback onToggle;
  final bool autofocus;
  final void Function(String after)? onSplit;
  final VoidCallback? onDeleteEmpty;
  final void Function(int blockId)? onFocus;
  final VoidCallback? onBlur;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: InkResponse(
            onTap: onToggle,
            radius: 20,
            child: Icon(
              block.collapsed
                  ? Icons.chevron_right_rounded
                  : Icons.expand_more_rounded,
              color: cs.onSurface.withAlpha(140),
            ),
          ),
        ),
        Expanded(
          child: TextBlockView(
            block: block,
            autofocus: autofocus,
            onSplit: onSplit,
            onDeleteEmpty: onDeleteEmpty,
            onFocus: onFocus,
            onBlur: onBlur,
          ),
        ),
        if (block.collapsed && hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Text('· $hiddenCount hidden',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(130))),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Verify it compiles:**

Run: `flutter analyze lib/features/notes/presentation/screens/note_editor_screen.dart`
Expected: No issues.

- [ ] **Step 6: Commit:**

```bash
git add lib/features/notes/presentation/screens/note_editor_screen.dart
git commit -m "feat(notes): fold caret on headings + hide collapsed sections in the editor"
```

---

### Task 5: Editor ⋮ — Collapse all / Expand all

**Files:**
- Modify: `lib/features/notes/presentation/screens/note_editor_screen.dart` (`_normalAppBar`)

**Interfaces:**
- Consumes: `NotesDao.setAllHeadingsCollapsed` (Task 3).

- [ ] **Step 1: Add the menu items + handlers** — in `_normalAppBar`, compute whether the note has a heading, add two cases, and two items shown only when a heading exists:

```dart
  AppBar _normalAppBar(List<NoteBlock> blocks) {
    final bool hasHeading = blocks.any((b) =>
        NoteBlockType.parse(b.type) == NoteBlockType.text && b.headingLevel != 0);
    return AppBar(
      title: const Text('Note'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            final dao = ref.read(notesDaoProvider);
            switch (v) {
              case 'collapse_all':
                await dao.setAllHeadingsCollapsed(widget.noteId, true);
                await dao.touchNote(widget.noteId, DateTime.now());
              case 'expand_all':
                await dao.setAllHeadingsCollapsed(widget.noteId, false);
                await dao.touchNote(widget.noteId, DateTime.now());
              case 'reorder':
                setState(() => _editingLines = true);
              case 'insert_template':
                _pickTemplateToInsert();
              case 'save_template':
                _saveAsTemplate();
              case 'delete':
                _deleteNote();
            }
          },
          itemBuilder: (context) => [
            if (hasHeading) ...[
              const PopupMenuItem(value: 'collapse_all', child: Text('Collapse all')),
              const PopupMenuItem(value: 'expand_all', child: Text('Expand all')),
            ],
            if (blocks.isNotEmpty)
              const PopupMenuItem(value: 'reorder', child: Text('Edit lines')),
            const PopupMenuItem(value: 'insert_template', child: Text('Insert template')),
            const PopupMenuItem(value: 'save_template', child: Text('Save as template')),
            const PopupMenuItem(value: 'delete', child: Text('Delete note')),
          ],
        ),
      ],
    );
  }
```

- [ ] **Step 2: Verify it compiles:**

Run: `flutter analyze lib/features/notes/presentation/screens/note_editor_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit:**

```bash
git add lib/features/notes/presentation/screens/note_editor_screen.dart
git commit -m "feat(notes): Collapse all / Expand all in the editor menu"
```

---

### Task 6: A1 — contained photo height

**Files:**
- Modify: `lib/features/notes/presentation/widgets/photo_block_view.dart`

- [ ] **Step 1: Add the cap const** — top of the file, after imports:

```dart
/// Max inline height for a note photo. Above this the photo is scaled down
/// (aspect kept, no crop) so no single image dominates the scroll; tap opens
/// it full-screen. Tune on device.
const double kNotePhotoMaxHeight = 220;
```

- [ ] **Step 2: Bound the image** — in `build`, wrap the tappable `Image.file` in a `ConstrainedBox` and switch to `BoxFit.contain`:

```dart
                ? GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PhotoViewScreen(path: path),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: kNotePhotoMaxHeight),
                      child: Image.file(
                        File(path),
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
```

- [ ] **Step 3: Verify it compiles:**

Run: `flutter analyze lib/features/notes/presentation/widgets/photo_block_view.dart`
Expected: No issues.

- [ ] **Step 4: Commit:**

```bash
git add lib/features/notes/presentation/widgets/photo_block_view.dart
git commit -m "feat(notes): cap inline photo height (contained, tap for full-screen)"
```

---

### Task 7: Full check, device verify, docs

**Files:**
- Modify: `docs/superpowers/STATUS-2026-07-28.md`, `docs/superpowers/NOTES-ROADMAP.md`, `CLAUDE.md` (OneDrive)

- [ ] **Step 1: Whole-suite green + analyze:**

Run: `flutter test` then `flutter analyze`
Expected: all tests pass (155 + new); analyze reports no issues.

- [ ] **Step 2: Install on the phone** (debug-signed release updates in place, no data loss):

```bash
flutter build apk --release
"$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" install -r build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 3: Device verify** — follow the Manual Test Steps below on a real multi-bed rounds note. Tune `kNotePhotoMaxHeight` if needed.

- [ ] **Step 4: Docs** — mark A7 + A1 done in `NOTES-ROADMAP.md`, add a shipped entry to `STATUS-2026-07-28.md`, and add a CLAUDE.md feature-table row (schema v19). Commit:

```bash
git add docs/superpowers/STATUS-2026-07-28.md docs/superpowers/NOTES-ROADMAP.md
git commit -m "docs: mark A7 collapse + A1 contained photos shipped"
```

(Release to `manjo00/uplan-releases` is a separate, user-gated step — bump pubspec `version:` first.)

---

### 🧪 Manual Test Steps
1. Open a note and add a couple of **H1/H2 headings** (via the format bar) with text/checkbox/photo lines under each (e.g. "Bed 1" … "Bed 2" …).
2. Tap the **caret** left of "Bed 1" → its lines collapse and the heading shows "· N hidden". Tap again → they return.
3. Make an **H2 under an H1**; collapse the H1 → the H2 and its lines all hide (one "N hidden" on the H1).
4. ⋮ → **Collapse all** → every heading folds; **Expand all** → all open.
5. Tap the heading **text** (not the caret) → it enters edit mode (caret doesn't fire).
6. **Close and reopen** the note → folded sections are still folded (persisted).
7. ⋮ → **Edit lines** → everything shows expanded (nothing hidden) so you can reorder; tap Done.
8. Add a **tall (portrait) photo** → it's capped at a bounded height, centered, not full-screen-tall; **tap it** → opens full-screen with full detail.
9. Add a **wide (landscape) photo** → full width, shorter; tap → full-screen.
