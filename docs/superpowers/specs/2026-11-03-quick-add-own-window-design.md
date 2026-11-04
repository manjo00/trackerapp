# The quick-add sheet gets its own window (design)

**Date:** 2026-11-03 · **Status:** approved by Ahmed ("Yes, build it", 2026-11-03); built and checked on the
emulator the same evening (`b7c92c8` on `master`); on his phone since 2026-11-04 17:04, every check there passed
(`docs/_Current_Task.md`) · **By:** the Tester chat · **Plan:**
`docs/superpowers/plans/2026-11-03-quick-add-own-window.md`

Ahmed, 2026-11-03: "some times it comes sometimes no and the first time i open it after awhile i think the apps pops
up in the background for a split second and disappears. you work in that, no shortcuts and token preservation nor
time restrictions take your time"

## What is wrong today (all checked on the emulator and his Z Flip 6)

The home-screen widget's "+" starts `MainActivity` with `uplan://add_task`. If Uplan's window is still open in the
background, Android brings that same window forward and the app swaps whatever screen was showing for the sheet
(`onNewIntent` → `openQuickAdd` → `appRouter.go('/quick-add')`). That one choice causes three problems:

1. **The app flashes behind the sheet.** The window comes forward still showing his last app screen, and
   `/quick-add` then animates in with the default page transition. On video: about 0.35 s of the full app screen on
   the emulator (1.14–1.33 s fully on screen) and about 0.2 s of his dark app screen behind the sheet on the phone.
   No flash when the sheet gets a window of its own (a sheet closed earlier, or Uplan not in memory).
2. **His place in the app is lost.** The screen he was on is replaced by the sheet. On the emulator, Back then
   closed Uplan, so reopening it started fresh. On his phone, Back only sends Uplan to the background (Samsung, Android
   12+), so **tapping Uplan's icon afterwards showed the add-task sheet** instead of his app (screenshot, 16:02).
3. **The keyboard is a race** (being fixed separately, see below): the text field asks before Android gives the
   window focus, and which comes first changes from tap to tap.

And one note: after a **Force stop**, the widget's "+" does nothing on the first tap (force-stop cancels the app's
shortcuts; the tap only refreshes the widget). Normal background kills keep them. Not changed by this design.

## The idea

The widget's "+" opens the sheet in **a window of its own**: a second Android screen (`QuickAddActivity`) in its own
task, hidden from recent apps. The open app is never touched.

What Ahmed would notice:
- The "+" never shows the app behind the sheet.
- His place in the app stays where it was, and Uplan's icon always opens the app, never the sheet.
- Speed stays the same. With Uplan in memory a new window is fast on his phone (measured 2026-11-03: Dart running at
  +0.05 s, the first frame at +0.08 s after the tap); with Uplan not in memory it takes 1–3 s, as today.
- Leaving the sheet with Home and tapping "+" again brings the same sheet back with what he typed.
- The sheet doesn't show up in recent apps. (Found while building, 2026-11-03: it does show there right after he
  leaves an open sheet with Home, until he opens another app, because Android keeps the newest task in Recents even
  when it is marked hidden. Tapping that card brings the sheet back as it was.)

## How it works

- **`QuickAddActivity`** (Kotlin, a `FlutterActivity`): always starts on `/quick-add`; transparent like today; its
  own `taskAffinity`, `excludeFromRecents="true"`, `launchMode="singleTask"` (a second "+" brings the open sheet
  back), the same see-through theme, `windowSoftInputMode="stateUnchanged|adjustResize"` (today set in code by
  `MainActivity.keepKeyboardForQuickAdd`), and the same `configChanges` as `MainActivity` so folding doesn't restart
  it. It forwards Android's window focus to the sheet (the `uplan/quick_add` channel from the keyboard fix).
- **Shared native setup:** the channels the sheet's code calls (`uplan/live` for refreshing the live dashboard after a
  save) move into one helper used by both activities. `MainActivity.liveChannel`, which the notification buttons use to
  reach the app, stays set only by `MainActivity`.
- **The widgets' "+"** points to `QuickAddActivity`: all three widgets have one (`UplanWidgetProvider.kt:52`,
  `UplanAgendaWidgetProvider.kt:52`, `UplanMonthWidgetProvider.kt:146`, each `uplan://add_task`).
- **`MainActivity`** keeps handling `uplan://add_task` for widget buttons made before the update, until the widgets
  refresh (they do on the next widget update).
- **Dart:** nothing changes in the routes. The sheet's send and its dimmed area already close its own window
  (`SystemNavigator.pop()` → `finish()`), which now leaves the app untouched. A sheet start skips the launch work as
  today (`wantsLaunchWork`).
- **A task added while the app is open in the background:** the sheet writes through its own database connection, and
  the app's on-resume refresh (already there for the live notification's buttons) re-reads it when he comes back. To be
  checked.

## Costs and risks

- While the sheet is open and the app is also open, two Flutter engines run (more memory for those seconds; my guess:
  some tens of MB).
- Two database connections at once (the app's and the sheet's). The app already runs a background engine with its own
  connection for alarms and the live notification; the sheet's write is one short insert.
- Work: about 1.5–2.5 h with tests and checks on the emulator and his phone (a guess).

## Checks

- Videos (`tool/emulator/plus_video.sh`) of all four situations: no app screen before the sheet.
- The reopen check: after the "+", Back, then Uplan's icon → his app, at the screen he was on.
- The keyboard scripts (`kb_check.sh`, `fresh_plus.sh`) on the emulator and his phone.
- A quick add while the app is open in the background → the app shows the new task when he returns.
- Analyze clean, all tests green; native parts have no tests in this project, so the scripts are their checks.

## Alternatives considered

- **Keep borrowing the open window, but hide its old frame until the sheet draws, and lay the sheet over the screen
  instead of replacing it.** Fixes the flash only in part (the page under the sheet still has to be hidden, and there
  are still two different ways the sheet opens), and keeping his place gets complicated. Not chosen.
- **A warmed-up engine kept ready for the sheet:** faster when Uplan isn't in memory, but more memory all the time and
  more code. Not needed while a new window takes 0.08 s; parked.

## The keyboard fix that comes first (separate, already written)

`MainActivity` forwards `onWindowFocusChanged(true)` to the sheet (`uplan/quick_add` → `windowFocused`), and the sheet
then asks every 150 ms for 1.2 s while a field has focus, until a keyboard comes up, without trusting view insets left
from before. Root cause and evidence: `docs/_Current_Task.md`, "The '+' investigated properly". Commit `f348af0` on
`tester/speed`, 370 tests pass; to be tried on a device before it goes to `master`. With this design it moves into
`QuickAddActivity`.

## Decision

Approved by Ahmed, 2026-11-03: "Yes, build it". Built the same evening; what was checked is in
`docs/_Current_Task.md` ("The sheet in its own window").
