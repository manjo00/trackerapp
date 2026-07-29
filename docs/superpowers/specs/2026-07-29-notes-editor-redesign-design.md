# Notes Editor Redesign — Design

**Date:** 2026-07-29
**Status:** Direction approved (user: "a complete open note", no per-line chrome; feel = "we'll see" → build clean/open, iterate on device).
**Origin:** `feedback/app.md` → "A NEW NOTE DESIGN CLOSER TO SAMSUNG'S / APPLE'S", plus user reaction after the photo-grid shipped: the block editor now looks cramped and busy next to the polished cards.

## Problem
Today every block row is `[⋮⋮ drag handle] [content] [✕ delete]`. Two chrome
icons flank every line, so the writing surface reads as a stack of boxed
controls instead of a note. Text lines are cramped (6px vertical padding), the
checkbox is a bulky 32px Material box, and the title has no separation from the
body.

## Direction — "a complete open note"
Strip the editor to just the writing. Controls appear on demand, never inline.

### 1. No per-line chrome (the core change)
- Remove the persistent drag handle **and** the ✕ delete button from every row.
- **Delete a text/checkbox line:** clear its text, then press Backspace on the
  now-empty line → the block is deleted (Samsung/Apple behaviour). Focus falls
  back to the note naturally.
- **Delete a photo:** keep the existing small ✕ overlay on the photo itself,
  but make it subtler.

### 2. Reorder lives in a mode, not inline
- AppBar ⋮ gains **"Reorder lines"**. Entering it swaps the clean view for a
  compact reorder list: each block shown as `[type icon] [one-line label] [≡]`,
  non-editable, drag to reorder (`ReorderableListView`, long-press or handle).
  A **Done** affordance (AppBar check / back) exits back to the clean editor.
- The normal editing view therefore has zero reorder chrome.

### 3. Calmer blocks + spacing ("paper-ish, open")
- **Title:** larger (`headlineSmall`→ roomier), bold, with generous top/bottom
  padding and a hairline divider (`cs.outlineVariant`) beneath it.
- **Text block:** line-height ~1.4, slightly larger body size, comfortable
  vertical padding (so consecutive text lines read as paragraphs).
- **Checkbox:** lighter — a rounded/circular check that visually recedes; tick
  still strikes through + dims.
- **Page margins:** comfortable horizontal padding so text isn't edge-to-edge.
- Flat/open surface for now (no card). "Paper" tint is a trivial follow-up once
  the user sees it and decides.

## Unchanged (must not regress)
- Auto-save (blocks on focus-loss, title on focus-loss + leave).
- Note↔task `@time` link (checkbox lines) — `reconcileBlock` / `onBlockChecked`.
- Empty-note auto-delete on exit.
- Add blocks via the bottom toolbar (Text / Checkbox / Photo).
- Photo tap → full-screen viewer.

## Scope
- Files: `note_editor_screen.dart` (clean view + reorder mode + backspace-delete
  wiring + title/divider), `text_block_view.dart` (spacing + backspace-empty
  callback), `checkbox_block_view.dart` (lighter checkbox + backspace-empty),
  `photo_block_view.dart` (subtler ✕).
- New pure helper `blockLabel(NoteBlock)` → the one-line label shown in reorder
  mode (unit-testable).

## Out of scope (Phase 2b, later)
Heading blocks, bold/italic inline formatting, Enter-to-split-line, cross-block
focus-follow after delete, notebook covers on the overview, wiring notes into
the Archived screen, Notes-as-a-tab.
