# Round table, merged draft (chair, 2026-11-01 about 12:25)

IDs: C = code seat (`code.md`), P = product (`product.md`), L = looks (`looks.md`), W = chair (speed and the widget).

## The chair's own findings (measured on the Flip-like emulator, Android 16, demo data)
- **W1. A new note typed and left without pressing Enter vanishes (data loss).** Checked 3 of 3 on the emulator: new
  note, type one line, then Back twice or the on-screen arrow: the whole note is gone from the database. Editing an
  existing line and backing out normally kept the edit. This confirms C4's guess.
- **W2. The widget "+" sheet: 2.8 s from a closed app, 1.2 s with the app in memory (profile build); 5.4 s and 3.2 s on
  a debug build (what the phone runs).** Nothing is on screen until then (see-through window, no splash). The alarm
  plugin's start, awaited before `runApp`, takes 0.7–1.1 s (profile) / 0.8–1.6 s (debug) of that, on every app start.
  Fix: start it after the first frame.
- **W3. The launch work runs while he types:** re-booking every reminder takes 1.4 s (profile) / 2.4 s (debug) right
  after the sheet appears; about 40 skipped frames each time. Fix: skip it on quick-add opens; make the re-booking
  cheaper (today 9 platform calls per task with a reminder just to cancel).
- **W4. The sheet stretches to the top when the keyboard opens** (keyboard height added twice). S with a widget test.
- **W5. The phone runs a debug build:** opening is 2–3× slower than a profile build on the emulator. A profile build
  stays debuggable (`run-as` keeps working). Ahmed's decision.
- **W6. Every "+" restarts the app** (`SystemNavigator.pop` destroys the engine): a second "+" pays the full start
  again. Fix: keep the engine (move to back) or a cached engine. M–L.
- **W7. The whole app draws through a see-through window** (texture mode): no splash on any app open (5 of 14 cold
  starts on the foldable emulator showed nothing for 5+ s) and an extra copy per frame. Fix: opaque window + splash,
  a separate see-through activity for quick add. L.
- Sending in the sheet is fast on a profile build (0.08–0.14 s; 0.35–0.39 s on debug), so the save path is not the lag.

## Draft ranking: fix first (gain for cost; data safety before speed)
1. W1 + C4: notes save while typing and flush before leaving (no more vanishing notes). M.
2. P3 + the old-backup restore bug: "last backup N days ago" in Settings, and restoring a pre-v1.18 backup. S + S–M.
3. W2 + W3 + W4: alarm plugin after the first frame, no launch work on quick add, sheet keyboard gap. S–M.
4. C2: photos decoded at display size (`cacheWidth`). S.
5. C5: `.autoDispose` on the ten family streams that never close. S.
6. C3 + C1: workout clock in its own widget; typing a set no longer re-reads history. S + M.
7. L1 + L5: readable priority pills (2–3 looks first) and one secondary-text colour. S + M.
8. L4 (+ L idea 1): a 48 dp "done" target, or swipe right to complete. S.
9. L2: Trackers' double title bar. S.
10. P1: "move to tomorrow" for overdue tasks. M.

## Next
P2 one add-task sheet + "+" on Today and Planner (M) · C6 habit completions (M) · C8 Home per task change (S) ·
C9 indexes/WAL (S) · C10 notes grid queries (M) · C11 trackers (S/M, guess to check) · L6 dark shift calendar (S–M) ·
L3 Home spacing (S) · P7 Undo in the gym (S) · P8 menu "Coming in Phase 2" (S) · P9 dates (S–M) · P4 task search (M) ·
C7 start-workout history (S) · L7 tiny text (S–M) · W5 profile build on the phone (S, his call).

## Later or bigger
W6 · W7 · C12 hidden tabs · P6 gestures · P5 front door · P10 trackers tick · P11 complete from widget (L) · L10 style
consistency · L8 lavender · L9 strike-through · L11 wide screens · ideas: launcher shortcuts, share to Uplan, photo
thumbnails, slow-frame meter, one open-tasks stream, calm overdue stack, "New note" on the widget.

## Proposed fix batches for Ahmed
- A. Nothing gets lost: 1 + 2.
- B. The widget "+" (his report): 3 (+ W5 if he wants the fast build on the phone).
- C. Smooth everywhere: 4, 5, 6.
- D. Easier to read: 7, 8, 9, L6.
- E. Faster daily flow: 10, P2, P7.
