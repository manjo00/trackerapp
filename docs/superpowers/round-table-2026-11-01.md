# Uplan round table, 2026-11-01 (Tester chat)

**Page for Ahmed (private):** https://claude.ai/artifact/KCStP5nQos8BCrZo65hUca ("Uplan Round Table").
**Full seat reports:** `docs/superpowers/round-table-2026-11-01/` (`code.md`, `product.md`, `looks.md`, the seats'
`briefs.md` and the chair's `merged-draft.md`). Finding IDs below: C = code, P = product, L = looks, W = chair.

## How it was done
- Ahmed asked for a speed and quality pass: "make the app cleaner and fast and responsive", several emulators, a
  round table of helpers on product, visuals and code, and the laggy widget add-task first.
- Three emulators on this PC (Windows Hypervisor Platform on since 2026-11-01): `uplan_flip_a16` (1080 × 2640, 420 dpi,
  Android 16, like his Z Flip 6), `uplan_small_a13` (720 × 1280, 320 dpi, Android 13, font scale 1.3), `uplan_fold_a16`
  (1856 × 2160, 420 dpi, Android 16). A profile build of `d3b3165` with made-up demo data (8 habits with 4 months of
  check-offs, 125 tasks with 25 reminders, 14 notes with 10 photos, shifts, 2 trackers, Push / Pull / Legs with 15
  workouts). 65 screenshots, opened by route on cold starts.
- Seats: product and flows, looks, code (helpers on Sonnet), and the chair (Opus) on start-up speed and the widget.
  Each wrote a report, then reacted to the merged ranking. Helper tokens over both rounds: code about 403k, product
  about 193k, looks about 236k.

## The three things to know
1. **W1 + C4: a new note vanishes if you leave it without pressing Enter** (checked 3 of 3 on the emulator: new note,
   one typed line, then Back twice or the on-screen arrow; the note is gone from the database). Cause (code seat): text
   saves only on blur or Enter, and `_onLeave` (`note_editor_screen.dart`) deletes lines that read as empty before the
   blur save lands. Editing an existing line and backing out normally kept the edit.
2. **W2–W4: the widget "+" shows nothing for 1.2–5.4 s.** Every "+" restarts the app (`SystemNavigator.pop` destroys
   the engine); the see-through window gets no splash; `AndroidAlarmManager.initialize()` (which spins up a second
   engine) blocks 0.7–1.6 s before `runApp`; after the sheet appears, `_reschedule()` re-books every reminder for
   1.4–2.5 s while he types; the sheet also stretches to the top when the keyboard opens (keyboard inset counted twice,
   `quick_add_task_screen.dart:148`).
3. **W5: the phone runs a debug build**, 2–3× slower to open than a profile build on the emulator. A profile build
   stays debuggable (`aapt2`: `application-debuggable`), so `run-as` keeps working. Ahmed's decision.

## Widget timings (Flip emulator, Android 16; median of 5 runs profile, 3 runs debug)
| From the tap on "+" | Profile | Debug (his phone's kind) |
|---|---|---|
| Sheet drawn, app process killed first | 2.8 s | 5.4 s |
| Sheet drawn, process still alive | 1.2 s | 3.2 s |
| Of that: `AndroidAlarmManager.initialize()` | 0.7–1.1 s | 0.8–1.6 s |
| `_reschedule()` after the first frame (mostly `rescheduleAll`) | 1.4 s | 2.5 s |
| Send to `SystemNavigator.pop` | 0.08–0.14 s | 0.35–0.39 s |

Measured with `StartupTrace` marks (`--dart-define=UPLAN_TRACE=true`, only in the Tester worktree so far) and logcat
timestamps; the "+" was fired as `am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n
com.lifetracker.life_tracker/.MainActivity`. Android's own "Displayed" time stops early here: in texture mode Flutter
doesn't hold back the first Android draw (`FlutterActivity.java:807`).

## Ranked top ten (after the second round)
1. W1 + C4 notes: an S hotfix (don't delete a line that has text by the time it's checked; widget test: type, leave,
   reopen), then M: save while typing and on app pause, the Home pinned note too.
2. W2 + W3 + W4 widget: alarm plugin after the first frame (and `rescheduleAll` awaits it), no launch work on quick-add
   opens, the keyboard counted once. S–M. Plus W5 if Ahmed wants the profile build on the phone.
3. P3 backup: "Last backup: N days ago", saying photos and Settings aren't in it (S). Later: photos and Settings in the
   backup (L); restoring pre-v1.18 backups (S–M, can wait: the phone is on v1.18).
4. P1 overdue: Today / Tomorrow / Next week chips and "Move all to today" (M); swipe right stays for "done".
5. C2 photos decoded at display size (`cacheWidth`). S.
6. C3 workout clock in its own widget (about 15 min) + C1 typing a set re-reads history (M).
7. C5 `.autoDispose` on the ten hand-written family streams (S; gain worked out, not measured).
8. L1 light-mode priority pills (1.45–2.4:1; dark is 3.4–6.3:1) + L5 about 110 faint grey text colours. S + M, looks first.
9. L4 the 24 dp "done" circle (48 dp target, or swipe right to complete). S.
10. L2 Trackers' double title bar. S (5 min; rides with any batch).

Next: P2 one in-app add-task sheet with "+" on Today and Planner (after W4) · C6 habit completions · C11/P10 Today may
show stale tracker ticks (guess, check on the emulator) · L6 dark shift calendar (the legend at 1.5–2.2:1 is a plain
bug) · P7 Undo in the gym · P8 menu "Coming in Phase 2" · P9 dates · P4 task search · L3 Home spacing · C9 indexes (WAL
only with a device-skill rule to copy all three files) · C7 start-workout history (rides with batch C).
Later: W7a a separate see-through quick-add activity that dims at once (M, guess) · W7b opaque window + splash (L) ·
W6 keep the engine warm after a quick add · P11 complete a task from the widget (L) · L10 style consistency · ideas
(launcher shortcuts, share to Uplan, photo thumbnails, slow-frame meter).

## Fix batches offered to Ahmed (all four seats: A first, then B)
- **A. Nothing gets lost** (about 1½–2 h): 1 and 3.
- **B. The widget "+"** (about 1–1½ h): 2 and 10, timed before and after; optional W5.
- **C. Smooth everywhere** (about 2 h): 5, 6, 7, C7.
- **D. Easier to read** (about 1½–2 h): L6 legend, 8, 9, with 2–3 looks to pick first.
- **E. Faster daily flow** (about 2–3 h): 4, P2, P7.
