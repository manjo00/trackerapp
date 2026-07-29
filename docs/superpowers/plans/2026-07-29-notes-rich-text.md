# Notes Rich Text (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add whole-line (block-level) formatting to notes — Heading 1/2/3, Highlight, Bold, Italic — plus a Divider block, via a context-aware formatting toolbar, with zero inline markers.

**Architecture:** Formatting lives in new `note_blocks` columns (`headingLevel`, `highlighted`, `bold`, `italic`); `content` is never touched, so `@time` linking, backup, snippet, and search are unaffected. A new `divider` block type renders a horizontal rule. The editor's bottom bar switches between "add block" and "format the focused line".

**Tech Stack:** Drift (schema v17), Riverpod, Flutter TextField styling.

## Global Constraints

- Schema migrations via `m.addColumn()` only — never raw ALTER.
- Colors via `.toARGB32()` not `.value`.
- New block columns default to off/0 → existing blocks render as plain body; nothing to backfill.
- `NoteBlockType.parse` must keep falling back to `text` for unknown values.
- Formatting must NOT alter `note_blocks.content`.
- `flutter analyze` clean; pure helpers unit-tested; end with 🧪 Manual Test Steps; deploy to phone.

---

### Task 1: Schema v17 — formatting columns + divider type

**Files:**
- Modify: `lib/features/notes/data/tables/note_blocks_table.dart`
- Modify: `lib/features/notes/data/models/note_block_type.dart`
- Modify: `lib/core/database/app_database.dart` (schemaVersion + migration)
- Test: `test/features/notes/rich_text_schema_test.dart`

**Interfaces:**
- Produces: `NoteBlocks.headingLevel` (int, default 0), `.highlighted` `.bold` `.italic` (bool, default false); `NoteBlockType.divider`.

- [ ] **Step 1: Add the columns**

In `note_blocks_table.dart`, inside `class NoteBlocks`:

```dart
  /// Whole-block formatting (Phase-1 rich text). Defaults = unformatted body.
  IntColumn get headingLevel => integer().withDefault(const Constant(0))();
  BoolColumn get highlighted => boolean().withDefault(const Constant(false))();
  BoolColumn get bold => boolean().withDefault(const Constant(false))();
  BoolColumn get italic => boolean().withDefault(const Constant(false))();
```

- [ ] **Step 2: Add the divider type**

In `note_block_type.dart`, extend the enum + parse:

```dart
enum NoteBlockType {
  text,
  checkbox,
  photo,
  divider;

  String get storageKey => name;

  static NoteBlockType parse(String? raw) => switch (raw) {
        'checkbox' => NoteBlockType.checkbox,
        'photo' => NoteBlockType.photo,
        'divider' => NoteBlockType.divider,
        _ => NoteBlockType.text,
      };
}
```

- [ ] **Step 3: Bump schema + migration**

In `app_database.dart`: `int get schemaVersion => 17;` and add after the `from < 16` block:

```dart
          if (from < 17) {
            // Block-level rich text: whole-line formatting flags. Defaults
            // (0 / false) mean existing blocks stay plain body — no backfill.
            await m.addColumn(noteBlocks, noteBlocks.headingLevel);
            await m.addColumn(noteBlocks, noteBlocks.highlighted);
            await m.addColumn(noteBlocks, noteBlocks.bold);
            await m.addColumn(noteBlocks, noteBlocks.italic);
          }
```

- [ ] **Step 4: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success, `app_database.g.dart` updated.

- [ ] **Step 5: Migration/defaults test**

```dart
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 29);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  test('new blocks default to unformatted body', () async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 0);
    final b = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == id);
    expect(b.headingLevel, 0);
    expect(b.highlighted, false);
    expect(b.bold, false);
    expect(b.italic, false);
  });

  test('divider type round-trips and parses', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.divider, content: null, orderIndex: 0);
    final b = (await dao.watchBlocks(note).first).first;
    expect(NoteBlockType.parse(b.type), NoteBlockType.divider);
  });
}
```

Run: `flutter test test/features/notes/rich_text_schema_test.dart` → PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/notes/data lib/core/database test/features/notes/rich_text_schema_test.dart
git commit -m "feat(notes): schema v17 — block formatting columns + divider type"
```

---

### Task 2: Pure helpers (font size, label, preview guard)

**Files:**
- Create: `lib/features/notes/domain/note_text_style.dart`
- Modify: `lib/features/notes/domain/block_label.dart`
- Modify: `lib/features/notes/domain/note_preview.dart`
- Test: `test/features/notes/note_text_style_test.dart`, extend `block_label_test.dart`, extend `note_preview_test.dart`

**Interfaces:**
- Produces: `double noteHeadingFontSize(int level)` — level 0→16, 1→26, 2→22, 3→19 (else 16).

- [ ] **Step 1: Write the font-size helper + test**

`note_text_style.dart`:

```dart
/// Body/heading font size for a note text block by [level]:
/// 0 = body (16), 1 = H1 (26), 2 = H2 (22), 3 = H3 (19). Unknown → body.
double noteHeadingFontSize(int level) {
  switch (level) {
    case 1:
      return 26;
    case 2:
      return 22;
    case 3:
      return 19;
    default:
      return 16;
  }
}
```

`note_text_style_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/notes/domain/note_text_style.dart';

void main() {
  test('heading font sizes by level', () {
    expect(noteHeadingFontSize(0), 16);
    expect(noteHeadingFontSize(1), 26);
    expect(noteHeadingFontSize(2), 22);
    expect(noteHeadingFontSize(3), 19);
    expect(noteHeadingFontSize(9), 16); // unknown → body
  });
}
```

- [ ] **Step 2: blockLabel handles divider**

In `block_label.dart`, add a `divider` case returning `'Divider'`. Add to `block_label_test.dart`:

```dart
  test('divider block is labelled "Divider"', () async {
    final b = await makeBlock(NoteBlockType.divider, null);
    expect(blockLabel(b), 'Divider');
  });
```

(Update the `switch` in `blockLabel` to include `NoteBlockType.divider => 'Divider'`.)

- [ ] **Step 3: notePreview ignores dividers**

In `note_preview.dart`, in the loop, skip divider blocks so they never become a snippet or count. Concretely, at the top of the loop body:

```dart
    final NoteBlockType kind = NoteBlockType.parse(b.type);
    if (kind == NoteBlockType.divider) continue;
    final bool isPhoto = kind == NoteBlockType.photo;
```

(Replace the existing `final bool isPhoto = b.type == photoKey;` line; drop the now-unused `photoKey` if needed.)

Add to `note_preview_test.dart`:

```dart
  test('divider blocks are ignored in the preview', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.divider, content: null, orderIndex: 0);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'after', orderIndex: 1);
    final p = notePreview(await blocksFor(note));
    expect(p.snippet, 'after');
    expect(p.photoCount, 0);
  });
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/notes/note_text_style_test.dart test/features/notes/block_label_test.dart test/features/notes/note_preview_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/domain test/features/notes
git commit -m "feat(notes): pure helpers for heading size, divider label, preview guard"
```

---

### Task 3: DAO setBlockFormat

**Files:**
- Modify: `lib/features/notes/data/dao/notes_dao.dart`
- Test: extend `test/features/notes/notes_dao_test.dart`

**Interfaces:**
- Produces: `Future<void> setBlockFormat(int id, {int? headingLevel, bool? highlighted, bool? bold, bool? italic})` — writes only the provided fields.

- [ ] **Step 1: Add the method**

In `notes_dao.dart`, near `updateBlockContent`:

```dart
  /// Updates a block's whole-line formatting flags. Only non-null args change.
  Future<void> setBlockFormat(
    int id, {
    int? headingLevel,
    bool? highlighted,
    bool? bold,
    bool? italic,
  }) =>
      (update(noteBlocks)..where((b) => b.id.equals(id))).write(
        NoteBlocksCompanion(
          headingLevel:
              headingLevel == null ? const Value.absent() : Value(headingLevel),
          highlighted:
              highlighted == null ? const Value.absent() : Value(highlighted),
          bold: bold == null ? const Value.absent() : Value(bold),
          italic: italic == null ? const Value.absent() : Value(italic),
        ),
      );
```

- [ ] **Step 2: Round-trip test** (add to `notes_dao_test.dart`)

```dart
  test('setBlockFormat updates only the given flags', () async {
    final note = await dao.createNote(now: now);
    final id = await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'x', orderIndex: 0);
    await dao.setBlockFormat(id, headingLevel: 2, bold: true);
    var b = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == id);
    expect(b.headingLevel, 2);
    expect(b.bold, true);
    expect(b.highlighted, false); // untouched
    await dao.setBlockFormat(id, highlighted: true);
    b = (await dao.watchBlocks(note).first).firstWhere((x) => x.id == id);
    expect(b.highlighted, true);
    expect(b.headingLevel, 2); // still set
  });
```

Run: `flutter test test/features/notes/notes_dao_test.dart` → PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/notes/data/dao/notes_dao.dart test/features/notes/notes_dao_test.dart
git commit -m "feat(notes): NotesDao.setBlockFormat (partial flag update)"
```

---

### Task 4: Styled block widgets + divider widget

**Files:**
- Modify: `lib/features/notes/presentation/widgets/text_block_view.dart`
- Modify: `lib/features/notes/presentation/widgets/checkbox_block_view.dart`
- Create: `lib/features/notes/presentation/widgets/divider_block_view.dart`

**Interfaces:**
- Consumes: `noteHeadingFontSize`, the block's flag columns.
- Produces: text/checkbox blocks render their `TextStyle` + optional highlight wrapper from the flags, and expose `void Function(int blockId)? onFocus`. `DividerBlockView` renders a horizontal rule.

- [ ] **Step 1: Text block — style from flags + onFocus**

In `text_block_view.dart`: add `final void Function(int blockId)? onFocus;` to the constructor. In the focus listener, when focus is gained call `widget.onFocus?.call(widget.block.id)`. Build the style:

```dart
    final NoteBlock b = widget.block;
    final double size = noteHeadingFontSize(b.headingLevel);
    final bool heavy = b.headingLevel != 0 || b.bold;
    final TextStyle style = TextStyle(
      fontSize: size,
      height: 1.4,
      fontWeight: heavy ? FontWeight.w700 : FontWeight.w400,
      fontStyle: b.italic ? FontStyle.italic : FontStyle.normal,
      color: cs.onSurface,
    );
    final Widget field = TextField(/* ...existing, style: style... */);
    return b.highlighted
        ? Container(
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withAlpha(150),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: field,
          )
        : field;
```

(Import `../../domain/note_text_style.dart`. Keep the focus-only hint, Enter-split, backspace-delete logic intact.)

- [ ] **Step 2: Checkbox block — style from flags + onFocus (no heading)**

In `checkbox_block_view.dart`: add `onFocus` the same way; build the inner text style from `bold`/`italic` (ignore heading), and wrap the whole Row in the same highlight `Container` when `highlighted`. Keep the strike-through-when-checked behavior (compose it into the style).

- [ ] **Step 3: Divider widget**

`divider_block_view.dart`:

```dart
import 'package:flutter/material.dart';

/// A horizontal separator block. Not editable; managed via "Edit lines".
class DividerBlockView extends StatelessWidget {
  const DividerBlockView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, thickness: 1.5, color: cs.outlineVariant),
    );
  }
}
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/features/notes` → no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/presentation/widgets
git commit -m "feat(notes): render block formatting + divider widget"
```

---

### Task 5: Editor — context-aware toolbar, focus tracking, divider

**Files:**
- Modify: `lib/features/notes/presentation/screens/note_editor_screen.dart`

**Interfaces:**
- Consumes: `DividerBlockView`, block widgets' `onFocus`, `NotesDao.setBlockFormat`, `NoteBlockType.divider`.

- [ ] **Step 1: Track the focused block**

Add state `int? _focusedBlockId;`. Pass `onFocus: (id) => setState(() => _focusedBlockId = id)` to text + checkbox blocks. Clear it when appropriate (e.g. when a block reports blur — add an `onBlur` or reuse: simplest, keep last-focused; the toolbar reads the block from the streamed list, and if it's gone, falls back to the add bar).

- [ ] **Step 2: Render divider blocks**

In `_blockWidget`, add:

```dart
      case NoteBlockType.divider:
        return const DividerBlockView();
```

- [ ] **Step 3: Add-divider action + Divider toolbar button**

Add `void _addDivider() => _addBlock(NoteBlockType.divider);` (a divider needs no focus; acceptable to reuse `_addBlock`, which sets `_focusRequestId` — harmless for a non-focusable block, but prefer a dedicated insert that does NOT request focus). Implement:

```dart
  Future<void> _addDividerBlock() async {
    final dao = ref.read(notesDaoProvider);
    await dao.addBlock(
        noteId: widget.noteId,
        type: NoteBlockType.divider,
        content: null,
        orderIndex: _nextOrder);
    await dao.touchNote(widget.noteId, DateTime.now());
  }
```

Add a "Divider" button to the add-block toolbar (`_BlockToolbar`) → `onDivider`.

- [ ] **Step 4: Formatting bar**

Replace the fixed `bottomNavigationBar` with a chooser: when `_focusedBlockId` maps to a live text/checkbox block, show a `_FormatBar`; else show `_BlockToolbar`. `_FormatBar` gets the focused `NoteBlock` and callbacks:

```dart
  Widget _bottomBar(List<NoteBlock> blocks) {
    final NoteBlock? focused = _focusedBlockId == null
        ? null
        : blocks.where((b) => b.id == _focusedBlockId).firstOrNull;
    final bool formattable = focused != null &&
        (NoteBlockType.parse(focused.type) == NoteBlockType.text ||
            NoteBlockType.parse(focused.type) == NoteBlockType.checkbox);
    if (!formattable) {
      return _BlockToolbar(
        onText: () => _addBlock(NoteBlockType.text),
        onCheckbox: () => _addBlock(NoteBlockType.checkbox),
        onPhoto: _addPhoto,
        onDivider: _addDividerBlock,
      );
    }
    return _FormatBar(
      block: focused,
      isText: NoteBlockType.parse(focused.type) == NoteBlockType.text,
      onHeading: (level) => ref
          .read(notesDaoProvider)
          .setBlockFormat(focused.id, headingLevel: level),
      onBold: () => ref
          .read(notesDaoProvider)
          .setBlockFormat(focused.id, bold: !focused.bold),
      onItalic: () => ref
          .read(notesDaoProvider)
          .setBlockFormat(focused.id, italic: !focused.italic),
      onHighlight: () => ref
          .read(notesDaoProvider)
          .setBlockFormat(focused.id, highlighted: !focused.highlighted),
    );
  }
```

Set `bottomNavigationBar: _editingLines ? null : _bottomBar(blocks)`.

- [ ] **Step 5: Build `_FormatBar`**

A `BottomAppBar` with: for text blocks a heading cycle/segment (Body→H1→H2→H3, showing current), and Bold / Italic / Highlight `IconButton`s that appear "on" (filled/primary tint) when the focused block's flag is set. Icons: `format_bold`, `format_italic`, `format_ink_highlighter` (or `highlight`), heading via `title`/`text_fields`. Keep it a plain widget (no test needed — visual).

- [ ] **Step 6: Analyze + full test**

Run: `flutter analyze` → clean. `flutter test` → all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/notes/presentation/screens/note_editor_screen.dart
git commit -m "feat(notes): context-aware formatting toolbar + divider block"
```

---

### Task 6: Ship — device look, docs, release

- [ ] **Step 1: Build + install** — `flutter build apk --release` → `adb install -r`.
- [ ] **Step 2: Device pass** — run the 🧪 steps below on the phone.
- [ ] **Step 3: Docs** — update `STATUS-2026-07-28.md` (rich-text Phase 1 done) + CLAUDE.md Notes rows. Commit.
- [ ] **Step 4: Release (if user approves)** — bump pubspec → `flutter build apk --release` → `gh release create v1.11.0 --repo manjo00/uplan-releases ...`.

## 🧪 Manual Test Steps

1. Open a note, tap a text line → the bottom bar becomes a **formatting bar**.
2. Tap **H1** → the line jumps to large heading text; tap **Body** → back to normal.
3. Tap **Bold**, **Italic** → the whole line turns bold / italic; the buttons show "on".
4. Tap **Highlight** → the line gets a colored background; tap again → off.
5. Tap away (no line focused) → the bar returns to **Text · Checkbox · Photo · Divider**.
6. Tap **Divider** → a horizontal line appears between blocks.
7. Press **Enter** on a formatted line → the new line is plain **body** (formatting doesn't leak).
8. Backspace-delete + Edit-lines still work; a **Divider** shows as "Divider" in Edit-lines and can be dragged/deleted.
9. Back out and reopen → all formatting + the divider persisted.
10. A note whose first line is a **Divider** still shows the right photo/snippet on its grid card (divider ignored).
