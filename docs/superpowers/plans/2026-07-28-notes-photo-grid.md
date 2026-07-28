# Notes Photo-Grid Redesign — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat vertical note list in notebook detail + Unfiled with a Samsung-style 2-column photo grid where each card shows the note's first photo (or a colored cover), title, snippet, date, and photo count.

**Architecture:** Pure UI. A new pure helper `notePreview(blocks)` derives the card's data (first-photo filename, snippet, photo count) from a note's blocks and is unit-tested. A new `NoteGridCard` widget renders one portrait card. `NotebookDetailScreen` swaps its `ListView` of `_NoteRow` for a `GridView` of the same rows, each feeding a `NoteGridCard`.

**Tech Stack:** Flutter 3.44, Riverpod (`noteBlocksProvider`), Drift models (`Note`, `NoteBlock`), `ImageStorageService.resolvePath` for thumbnails.

## Global Constraints

- No schema/data change, no new dependency (spec: "Out of scope").
- Colors via `.toARGB32()` not `.value` (deprecated in Flutter 3.44).
- One widget per file; `const` constructors where possible; no `!` null-bang unless unavoidable.
- Missing/absent image file → colored-cover fallback, never a broken-image icon.
- `flutter analyze` clean; unit test for the pure helper; end with 🧪 Manual Test Steps; deploy to the phone (`adb install -r`, USB permitting) — the emulator is fine for a first look.

---

### Task 1: Pure preview helper + test

**Files:**
- Create: `lib/features/notes/domain/note_preview.dart`
- Test: `test/features/notes/note_preview_test.dart`

**Interfaces:**
- Consumes: `NoteBlock` (Drift row: `.type` String, `.content` String?), `NoteBlockType` (`.storageKey`, `.photo`).
- Produces: `NotePreview notePreview(List<NoteBlock> blocks)` returning a class with fields `String? firstPhotoFilename`, `String snippet`, `int photoCount`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/models/note_block_type.dart';
import 'package:life_tracker/features/notes/domain/note_preview.dart';

void main() {
  late AppDatabase db;
  late NotesDao dao;
  final now = DateTime(2026, 7, 28, 9);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NotesDao(db);
  });
  tearDown(() async => db.close());

  Future<List<NoteBlock>> blocksFor(int noteId) => dao.watchBlocks(noteId).first;

  test('first photo, snippet from first text, and total photo count', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'Bed 9 vent', orderIndex: 0);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'a.jpg', orderIndex: 1);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'b.jpg', orderIndex: 2);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: 'later line', orderIndex: 3);

    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, 'a.jpg');
    expect(p.snippet, 'Bed 9 vent');
    expect(p.photoCount, 2);
  });

  test('checkbox text counts as snippet source; blank/whitespace ignored', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.text, content: '   ', orderIndex: 0);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.checkbox, content: 'take bloods', orderIndex: 1);

    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, isNull);
    expect(p.snippet, 'take bloods');
    expect(p.photoCount, 0);
  });

  test('photos only → empty snippet, first filename set', () async {
    final note = await dao.createNote(now: now);
    await dao.addBlock(
        noteId: note, type: NoteBlockType.photo, content: 'only.jpg', orderIndex: 0);

    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, 'only.jpg');
    expect(p.snippet, '');
    expect(p.photoCount, 1);
  });

  test('empty note → all defaults', () async {
    final note = await dao.createNote(now: now);
    final p = notePreview(await blocksFor(note));
    expect(p.firstPhotoFilename, isNull);
    expect(p.snippet, '');
    expect(p.photoCount, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/notes/note_preview_test.dart`
Expected: FAIL — `note_preview.dart` / `notePreview` not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// The three things a note-grid card needs, derived from a note's blocks:
/// the first photo's filename (for the thumbnail), a one-line text snippet,
/// and the total photo count. Pure — no I/O — so it is unit-testable.
class NotePreview {
  const NotePreview({
    required this.firstPhotoFilename,
    required this.snippet,
    required this.photoCount,
  });

  final String? firstPhotoFilename;
  final String snippet;
  final int photoCount;
}

/// Derives a [NotePreview] from a note's ordered [blocks].
///
/// - snippet = the first non-empty text/checkbox block, trimmed.
/// - firstPhotoFilename = the first photo block's stored filename (or null).
/// - photoCount = number of photo blocks.
NotePreview notePreview(List<NoteBlock> blocks) {
  final String photoKey = NoteBlockType.photo.storageKey;

  String? firstPhoto;
  String snippet = '';
  int photoCount = 0;

  for (final NoteBlock b in blocks) {
    final bool isPhoto = b.type == photoKey;
    if (isPhoto) {
      photoCount++;
      firstPhoto ??= b.content;
    } else if (snippet.isEmpty) {
      final String text = (b.content ?? '').trim();
      if (text.isNotEmpty) snippet = text;
    }
  }

  return NotePreview(
    firstPhotoFilename: firstPhoto,
    snippet: snippet,
    photoCount: photoCount,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/notes/note_preview_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/notes/domain/note_preview.dart test/features/notes/note_preview_test.dart
git commit -m "feat(notes): pure notePreview helper for grid cards"
```

---

### Task 2: NoteGridCard widget

**Files:**
- Create: `lib/features/notes/presentation/widgets/note_grid_card.dart`
- Delete: `lib/features/notes/presentation/widgets/note_tile.dart` (replaced; only used by notebook detail, swapped in Task 3)

**Interfaces:**
- Consumes: `Note`, `ImageStorageService.resolvePath`, `NotePreview` from Task 1.
- Produces: `NoteGridCard` — a `StatelessWidget` with
  `{required Note note, required VoidCallback onTap, required NotePreview preview, required int accentColorValue, ImageStorageService? images}`.
  `accentColorValue` is the notebook's `colorValue` (Unfiled passes the theme primary at the call site). Renders a portrait card: photo header (`Image.file`, `BoxFit.cover`) or a colored cover with a big faint note icon; body with title (bold, 1 line), snippet (1 line, muted), footer (relative date + `🖼 N`).

- [ ] **Step 1: Write the widget**

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/images/image_storage_service.dart';
import '../../domain/note_preview.dart';

/// One note as a Samsung-style portrait card: a photo header (the note's first
/// photo) over a title + snippet + footer. With no usable photo it falls back to
/// a solid cover tinted with the notebook's colour and a big faint note icon.
class NoteGridCard extends StatelessWidget {
  const NoteGridCard({
    required this.note,
    required this.onTap,
    required this.preview,
    required this.accentColorValue,
    this.images,
    super.key,
  });

  final Note note;
  final VoidCallback onTap;
  final NotePreview preview;
  final int accentColorValue;
  final ImageStorageService? images;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final bool untitled = note.title.trim().isEmpty;
    final Color accent = Color(accentColorValue);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _header(context, accent, cs)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    untitled ? 'Untitled' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontStyle: untitled ? FontStyle.italic : null,
                      color:
                          untitled ? cs.onSurface.withAlpha(130) : cs.onSurface,
                    ),
                  ),
                  if (preview.snippet.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview.snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withAlpha(140)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _relativeDate(note.updatedAt),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withAlpha(110)),
                      ),
                      const Spacer(),
                      if (preview.photoCount > 0) ...[
                        Icon(Icons.photo_outlined,
                            size: 13, color: cs.onSurface.withAlpha(120)),
                        const SizedBox(width: 3),
                        Text(
                          '${preview.photoCount}',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurface.withAlpha(120)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo header, or a colored cover when there is no usable photo.
  Widget _header(BuildContext context, Color accent, ColorScheme cs) {
    final String? filename = preview.firstPhotoFilename;
    if (filename == null || filename.isEmpty) {
      return _cover(accent);
    }
    final ImageStorageService store = images ?? ImageStorageService();
    return FutureBuilder<String>(
      future: store.resolvePath(filename),
      builder: (context, snap) {
        final String? path = snap.data;
        if (path == null) return _cover(accent);
        if (!File(path).existsSync()) return _cover(accent);
        return Image.file(File(path), fit: BoxFit.cover);
      },
    );
  }

  /// Solid notebook-tinted cover with a big faint note glyph.
  Widget _cover(Color accent) {
    return Container(
      color: Color.alphaBlend(accent.withAlpha(46), const Color(0x22000000)),
      alignment: Alignment.center,
      child: Icon(
        Icons.sticky_note_2_outlined,
        size: 40,
        color: accent.withAlpha(140),
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    const List<String> m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month]}';
  }
}
```

- [ ] **Step 2: Delete the old tile**

```bash
git rm lib/features/notes/presentation/widgets/note_tile.dart
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/notes`
Expected: no errors from `note_grid_card.dart` (the `note_tile.dart` import in the screen still errors until Task 3 — that's fine to see here, or run Task 3 before analyzing).

- [ ] **Step 4: Commit**

```bash
git add lib/features/notes/presentation/widgets/note_grid_card.dart
git commit -m "feat(notes): NoteGridCard photo-first note card"
```

---

### Task 3: Grid layout in NotebookDetailScreen

**Files:**
- Modify: `lib/features/notes/presentation/screens/notebook_detail_screen.dart`

**Interfaces:**
- Consumes: `NoteGridCard` (Task 2), `notePreview` (Task 1), `noteBlocksProvider`, the notebook's `colorValue`.
- Produces: no exported symbols — swaps `ListView` → `GridView.builder`; `_NoteRow` now computes `NotePreview` and passes it plus `accentColorValue`.

- [ ] **Step 1: Swap the body to a GridView**

Replace the `body:`'s non-empty branch (the `ListView(...)`) with:

```dart
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: notes.length,
              itemBuilder: (context, i) => _NoteRow(
                note: notes[i],
                accentColorValue: notebook?.colorValue ?? cs.primary.toARGB32(),
                onTap: () => context.push('/notes/${notes[i].id}'),
              ),
            ),
```

- [ ] **Step 2: Update `_NoteRow` to build a NoteGridCard**

Replace the whole `_NoteRow` class with:

```dart
/// A note card that derives its preview (first photo, snippet, count) from the
/// note's blocks and renders a [NoteGridCard].
class _NoteRow extends ConsumerWidget {
  const _NoteRow({
    required this.note,
    required this.onTap,
    required this.accentColorValue,
  });

  final Note note;
  final VoidCallback onTap;
  final int accentColorValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(note.id)).valueOrNull ?? const [];
    return NoteGridCard(
      note: note,
      onTap: onTap,
      preview: notePreview(blocks),
      accentColorValue: accentColorValue,
      images: ref.watch(imageStorageServiceProvider),
    );
  }
}
```

- [ ] **Step 3: Fix imports**

At the top of the file: remove `import '../widgets/note_tile.dart';` and
`import '../../data/models/note_block_type.dart';` (no longer referenced),
and add:

```dart
import '../../domain/note_preview.dart';
import '../widgets/note_grid_card.dart';
```

(Keep `import '../../../../core/database/app_database.dart';` — `Note`/`NoteBlock`/`Notebook` come from it.)

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/features/notes`
Expected: no errors, no warnings.

- [ ] **Step 5: Full test + analyze**

Run: `flutter test` then `flutter analyze`
Expected: all tests pass; analyze clean.

- [ ] **Step 6: Commit**

```bash
git add lib/features/notes/presentation/screens/notebook_detail_screen.dart
git commit -m "feat(notes): 2-column photo grid in notebook detail + Unfiled"
```

---

### Task 4: Device look + docs

**Files:**
- Modify: `docs/superpowers/STATUS-2026-07-28.md` (mark item 1 built)
- Modify: `C:\Users\kille\OneDrive\سطح المكتب\appproject\CLAUDE.md` (Notes Phase 2 row: photo-grid shipped)

- [ ] **Step 1: Deploy** — `flutter run -d emulator-5554` (or `adb install -r` a debug build on the phone if USB is up). Open drawer → Notes → a notebook with photos (e.g. "Ticu 27 july") and confirm the cards show the actual photos, two per row.
- [ ] **Step 2: Update STATUS + CLAUDE.md**, commit `docs: notes photo-grid Phase 1 shipped`.

## 🧪 Manual Test Steps

1. Drawer → **Notes** → open a notebook that has photo notes (e.g. "Ticu 27 july").
2. Notes now render as a **2-column grid** of portrait cards, not a vertical list.
3. A note with photos shows its **first photo** filling the top of the card; title + snippet + date + `🖼 N` below.
4. A note with **no photo** shows a solid cover tinted with the notebook's colour + a faint note icon.
5. A note whose photo file is missing shows the **colored cover**, never a broken-image icon.
6. Tap any card → opens the block editor (unchanged).
7. Open **Unfiled** → same grid; no-photo cards use the theme's primary tint.
8. Add a photo to a note, back out → its card's thumbnail updates.
