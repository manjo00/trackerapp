# Home v2.1 — Control Pack + New Blocks + Responsive Columns — Design

**Date:** 2026-08-03
**Status:** Approved (the C + D + responsive follow-up the user queued after the
Home v2 foundation batch; "continue the queue")
**Area:** `lib/features/home` (+ read-only reuse of habits/shifts/tasks
providers)

## Goal
Finish the "not enough control and options" theme on the v21 foundation:
per-block settings (C), four new block types (D), and multi-column Home on wide
screens (#27). No schema change — everything rides in `home_blocks.configJson`.

## C — Per-block control pack
Config keys (all optional; absent = today's behavior):
- `limit` (int) — items shown by task blocks (urgent/dueToday/captured/list/
  label). Display-only cap with a muted "+N more"; **de-dupe claims only the
  shown tasks**, so a task hidden by one block's limit is still available to a
  later block (today claim() swallows all).
- `days` (int) — This-week window length (default 7).
- `hideWhenEmpty` (bool) — the whole block (header included) disappears while
  empty. Offered for urgent/dueToday/captured/list/label/shift.
- `collapsed` (bool) — every block header gains a ▾/▸ chevron on Home; folded =
  header only. Persisted per block.
Editing UX: each enabled row in **Edit Home** gets a ⚙ that opens a small
options sheet (only the options that apply to that type). Pinned-note rows keep
tap-to-change-note.

## D — New block types (HomeBlockType + renderers)
- **`list`** — one chosen list's incomplete tasks (config `listId`; header =
  the list's name; "+N more" taps through to `/lists/:id`). Multi-instance.
- **`label`** — incomplete tasks carrying a chosen label (config `labelId`;
  header = label name). Multi-instance. Sources: `taskIdsForLabelProvider` ∩
  `allTasksProvider`.
- **`habits`** — today's habits with check-off, straight reuse of
  `habitsWithStatusProvider` + `HabitTile`. Single-instance.
- **`shift`** — a compact glance: today's shift (ShiftStyle colors, sun/moon,
  rotation label, start–end) and the next upcoming shift within 14 days; taps
  to the Work schedule screen. Single-instance.
Add flow in Edit Home: `list`/`label` open a picker first (like pinned note).
Multi-instance set = {pinnedNote, list, label}; everything else stays unique.

## Responsive Home (#27)
- `LayoutBuilder`: width ≥ 720 → **2 columns**, ≥ 1080 → **3** (Tab S9 / unfolded
  Flip get columns, phone stays exactly as-is).
- Blocks are distributed **round-robin in user order** (block i → column i mod
  n) via a pure `distributeRoundRobin(items, n)` helper (tested) — the top of
  every column holds the user's highest-priority blocks.
- Wide layout scrolls as one page; **drag-reorder is single-column only** (wide
  screens reorder via Edit Home). De-dupe still walks the single user order.

## Files
**New:** `widgets/habits_block.dart` · `widgets/shift_block.dart` ·
`widgets/block_config_sheet.dart` · `data/home_layout.dart`
(distributeRoundRobin) + tests (config helpers, layout helper).
**Modify:** `data/home_block_config.dart` (generic get/merge + typed accessors)
· `data/home_block_type.dart` (+4 types) · `screens/home_screen.dart` (limits,
hide-empty, collapse chevron, new content builders, title overrides for
list/label, responsive body) · `screens/edit_home_screen.dart` (⚙ sheet,
list/label pickers, multi-instance set).

## Not doing
Per-block accent colors (visual-polish backlog) · quick-add per block ·
cross-column drag on tablets · habits hide-when-empty (a habitless day is
worth seeing).
