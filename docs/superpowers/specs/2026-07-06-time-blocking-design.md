# Time Blocking — Design Spec

**Date:** 2026-07-06 · **Status:** approved by user (design presented in chat)

## Context

The user wants to optionally plan their day by blocking out time — without a
new entity or any added burden ("do not change anything, just add"). A task
can carry a time RANGE (or keep today's single fixed time), and the Planner's
day panel gains an enhanced view that organizes the day by time and urgency.

## Locked decisions

1. **No new entity.** A "time block" is a task whose `dueTime` (start) is
   paired with a new optional duration. Habits/trackers unchanged in v1.
2. **Storage: `durationMinutes` int, nullable** (schema v12, `m.addColumn`).
   End time is always computed (`dueTime + duration`). Duration — not a
   stored end time — so rescheduling the start moves the whole block.
3. **Editor:** when a due time is set, an optional **End time** tile appears
   (time picker; shows "14:00 – 15:30 · 1h 30m"; clearable). Validation:
   end must be after start on the same day, else rejected with a message.
   Quick-add sheet unchanged.
4. **Enhanced day view in the Planner** with a header row:
   - **View switch** icon button: List ⇄ Grid.
   - **⋮ menu:** Hide completed · Filter by list · Filter by label ·
     Default view (List/Grid — persisted; filters are per-visit, reset on
     reopen to stay lightweight).
5. **List view** = current day list, upgraded: timed tasks first sorted by
   start time showing a range chip ("14:00–15:30"), untimed after, sorted by
   urgency (overdue first, then priority desc).
6. **Grid view** = vertical 24-hour grid:
   - Ranged tasks as proportional slabs (priority colour); fixed-time-only
     tasks as compact 30-minute slabs.
   - Work shift hours shaded in the background (day shift ≈ 07–19, night
     ≈ 19–07 per ShiftType defaults already in the model).
   - Red current-time line; auto-scroll to now (or first item on other days).
   - "Anytime" collapsible strip above the grid: untimed tasks,
     urgency-sorted.
   - Tap slab → edit task. Long-press empty slot → new task pre-filled with
     that date + tapped hour.
   - Overlaps: side-by-side columns up to 3, then stacked in order.
7. **Default view + persistence:** `AppSettings.plannerDayView`
   ('list'|'grid', default list) via shared_preferences.

## Testing

Pure grid/layout math in its own file with unit tests:
- end-time computation + "end before start" rejection,
- range → top-offset/height maths for the grid,
- overlap column assignment (0, 2, 3, >3 overlapping items),
- list-view ordering (timed by start; untimed overdue→priority).

## Out of scope (recorded)

- Drag-to-reschedule / resize slabs on the grid.
- Ranges on habits, trackers, or workout sessions.
- Recurring blocks; grid view on the Today screen; week-grid view.
- Filters persisting across visits.

## Definition of done

flutter analyze clean · build_runner after schema change · new unit tests +
full suite pass · device pass on the Flip 6 (🧪 steps) · conventional
commits · CLAUDE.md schema v12 + feature row · release when user says so.
