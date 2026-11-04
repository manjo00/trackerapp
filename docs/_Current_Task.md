# Current Task: Tester, a speed and quality pass (2026-11-01)
**Date:** 2026-11-01 · **Branch:** master · **Chat:** Tester, a temporary chat the Uplan chat started at Ahmed's
request. It owns the repo's work until it hands back.

**Now (2026-11-04 20:45): the habits rebuild, demo 1 done.** After this chat's fresh start, Ahmed asked it: "i want to
rebuild the habit tracker research and come back to me with good design". He picked **Look A, the day list** (looks
page https://claude.ai/artifact/GAkkbPjK3PCQmd6S8hLNid), approved the design
`docs/superpowers/specs/2026-11-04-habits-rebuild-design.md` and the plan
`docs/superpowers/plans/2026-11-04-habits-demo-1.md`. **Demo 1 is on `master` (`98eb3d7`, schema 27, 479 tests;
tried on the Flip emulator with a copy of his newest data), not on his phone yet.** Next: when he says "Phone plugged
in", install from master under the install rule (tell the Uplan chat, copy his data off first, check the phone's
`241a187` is inside HEAD), then his Manual Test Steps (in the design's Status), then the plan for demo 2. Code goes on
`tester/speed` in `D:\projects\trackerapp-tester` (its builds carry the debug key: emulator only), merged into master
only after telling the Uplan chat. Note: the Flip emulator's Uplan now carries the worktree's debug-key build (the old
emulator data is in this chat's scratchpad), so a master build needs an uninstall there first (emulator only). The
older pick in step 6 (the main app's ordinary window, or the hand-back) is still open.

## Goal (Ahmed, 2026-11-01, his words)
"make the app cleaner and fast and responsive can you download it in multiple sims and ask helpers including yourself
to not just the product and visuals but the code also make a review in round table manner and find problems and fixes
and ideas need to be implemented like if something is coded inefficiently. i found that adding a task from the widget
is a bit laggy."

## Steps (in order)
1. ✅ Start: START HERE, this file, the history and the code map read (2026-11-01 09:50).
2. ✅ Size the whole job and get his yes before any helper starts: "Three helpers" (Ahmed, 2026-11-01 about 10:05;
   see "Size").
3. ✅ Emulators (2026-11-01 11:13–11:55; undo rows in `docs/_Undo_Table.md`): Ahmed turned on Windows Hypervisor
   Platform and restarted; the emulator 37.2.13 and Android 16 and 13 downloaded in 9 min; three AVDs in
   `D:\dev\android-avd`: `uplan_flip_a16` (1080 × 2640, 420 dpi), `uplan_small_a13` (720 × 1280, 320 dpi, run with font
   scale 1.3), `uplan_fold_a16` (1856 × 2160, 420 dpi). Start one at a time, headless:
   `ANDROID_AVD_HOME=D:\dev\android-avd emulator -avd <name> -no-window -no-audio -no-boot-anim -gpu host -no-metrics
   -crash-report-mode never` (boot 90–105 s). Demo data (made up): `tool/seed_demo_test.dart` in the worktree writes
   the database (`flutter test tool/seed_demo_test.dart`); 10 photos made with ffmpeg; the Tester's scratchpad scripts
   `prepare.sh` (install, permissions, data, settings with every first-run tip seen) and `capture.sh` (each screen by
   route on a cold start: `am start -n com.lifetracker.life_tracker/.MainActivity --es route /x`). 65 screenshots plus
   four overview sheets in the notes folder's `round-table\screens\` (`INDEX.md`).
4. ✅ The round table (2026-11-01 11:55–12:50): three seats plus the chair, then a second round on the merged list.
   Summary and ranking: `docs/superpowers/round-table-2026-11-01.md` (the seats' full reports beside it in
   `docs/superpowers/round-table-2026-11-01/`); Ahmed's page: https://claude.ai/artifact/KCStP5nQos8BCrZo65hUca.
   Helper tokens over both rounds: code about 403k (over its brief's 150–200k), product about 193k, looks about 236k.
   The round table: helpers plus this chat review the product and flows, the visuals and the code (needless
   rebuilds, database queries, startup, the home-screen widgets). Each finding: the problem as behaviour, where in
   the code, the fix, its cost, its gain. One ranked list, on a page for his tablet and in `docs/`.
5. ⬜ The widget's laggy add-task: reproduce, measure on a profile or release build (not debug), find the cause
   (superpowers' systematic-debugging), fix it with a regression test that fails on the old code. **Reproduced,
   measured and explained (2026-11-01)**: timings and causes in `docs/superpowers/round-table-2026-11-01.md`; the
   stopwatch (`lib/core/diagnostics/startup_trace.dart`, marks in `main.dart`, `app.dart`, `quick_add_task_screen.dart`)
   and the emulator scripts (`tool/emulator/`, `tool/seed_demo_test.dart`) sit uncommitted in the Tester worktree.
   The fix is batch B.
6. ⬜ **← here: the fix batches Ahmed picked, "A, then B" (2026-11-01 about 12:55).**
   - ✅ Batch A (13:15, `fcaab82`, on `master`): a typed line survives Back (`NoteLineSaves` in
     `lib/features/notes/presentation/note_line_saves.dart` saves every line before `_onLeave` prunes empty ones, and
     when the app goes inactive); a new line takes the cursor even when it is marked after it was built (it often
     didn't on the emulator); Settings › Data shows "Last backup: …" and says note photos and Settings aren't in the
     backup (`lib/core/backup/last_backup.dart`; recorded when the share sheet reports a chosen app). 11 new tests, each
     failed first on the old code; 340 pass; analyze clean; tried on the Flip emulator. Not on the phone yet.
   - ✅ Batch B (13:35, `44f8d2d`, on `master`): the quick-add sheet sits on the keyboard (inset counted once); an app
     start on `/quick-add` skips the launch work (`lib/core/startup/launch_work.dart`); Trackers has one title bar;
     `StartupTrace` (`lib/core/diagnostics/startup_trace.dart`, compiled out unless `--dart-define=UPLAN_TRACE=true`).
     4 new tests (each failed first); 344 pass; analyze clean; tried on the emulator. **Measured: the time until the
     sheet is drawn did not improve** (profile 2.9 s closed / 1.35 s in memory; debug 5.9 / 3.8 s; within session
     drift). The morning's "alarm plugin costs 0.7–1.6 s" was wrong: moving it after the first frame gained nothing
     (the next platform call waits for Android's busy main thread instead) and made a visible ~0.65 s freeze after the
     first frame, so it was reverted. What still makes the "+" slow: Android starting the app and its engine (every
     "+" starts it again) and the debug build. Next real levers: the fast build on the phone, keeping the app warm
     after a quick add (W6), a Perfetto trace of the busy main thread.
   - ✅ **The fast build on his phone** (2026-11-02 07:24; Ahmed: "Phone plugged in"). First his Uplan folder was copied
     the plan's way to `D:\backups\uplan\2026-11-02-fast-build\` (327 files = the phone's count, 569 MB in 38 s,
     integrity `ok`, 309 photos and 0 missing, database SHA-256 `199f598f…`; `phone_counts.txt` and `counts.txt` there),
     then `install -r` (fingerprint checked again). After it: v1.18.0+27, `DEBUGGABLE`, 327 files, the app's 3 booked
     reminders (`flutter.alarm_notif_*`) the same 3 before and after (the crude `dumpsys alarm` line count went 58 →
     57), Home shows his data, the widget intent opened the sheet and Back closed it with nothing added (34 tasks,
     integrity `ok`). Not timed on the phone. Note: the Z Flip 6 has two screens, so `screencap` needs `-d <id>` from
     `dumpsys SurfaceFlinger --display-id` (without it a warning lands in front of the PNG).
   - ✅ **The "+" on a running app brings the keyboard up** (2026-11-02 09:20–10:00, Ahmed: "Yes, fix it"; `64091f9`
     on `master`). Found on his phone at 07:25: the phone's log showed Flutter's two `showSoftInput` calls ignored
     ("… is not served") about 40 ms before the window gained focus. The emulator reproduced it (Flip, fast build:
     0 of 3 runs with a keyboard), and its full log showed the second half: Flutter's view doesn't count as a text box
     for Android (`FlutterView` has no `onCheckIsTextEditor`), so as the window comes to the front Android hides the
     keyboard (`HIDE_UNSPECIFIED_WINDOW` under the manifest's `adjustResize`, and
     `HIDE_WINDOW_GAINED_FOCUS_WITHOUT_EDITOR` whenever the keyboard was up just before), a hide that reached the app
     20–90 ms after focus, just after any ask made then. The fix: `quick_add_task_screen.dart` asks again on Flutter's
     "resumed" (sent only once the window has focus) and every 150 ms after, at most 5 times, while a field has focus
     and the keyboard isn't up; `MainActivity.keepKeyboardForQuickAdd` sets `SOFT_INPUT_STATE_UNCHANGED` while the
     activity shows the quick-add (cold or warm; the activity ends when the sheet closes), which stops the first hide
     so the first ask usually wins. Tried one half at a time first: the ask on "resumed" alone, 0 of 3; the native
     line alone, 0 of 2; both without the repeat: 3 of 3, but 0 of 3 after leaving with the keyboard up. The whole fix:
     every case with a keyboard (3 of 3 warm, cold, a cold sheet left with Home and reopened from the icon, and 3 of 3
     "+" after leaving with the keyboard up, where the log shows Android's hide and then the sheet's second ask
     winning); a normal start still has no keyboard. Check script: `tool/emulator/kb_check.sh <serial> <label> <runs>`
     (`.gitattributes` now keeps `*.sh` in Unix line endings, which Git Bash needs). 4 new tests in
     `test/features/tasks/quick_add_keyboard_test.dart` (3 failed on the code before them; the 4th fails on an
     always-ask version); 348 pass; analyze clean. No native test exists in this project, so the native line is
     covered by the emulator script only.
   - ✅ **The keyboard fix on his phone** (2026-11-02 15:37–15:41, Ahmed: "Phone plugged in"). Built from `64091f9`
     in `D:\projects\trackerapp` (09:55–09:56): `build\app\outputs\flutter-apk\app-profile.apk`, v1.18.0 (27),
     `application-debuggable`, certificate SHA-256 `5b269323…c7ac5` (Uplan's key; checked twice). The file is
     119.4 MiB, but its entries take 97.1 MB like yesterday's (93.0 MiB): the rest is free space the incremental
     packager left inside the file (checked with Python's `zipfile`). Before installing: master and the phone had
     nothing newer (origin `66a7c14`; the phone's build from 07:24); his folder copied the plan's way to
     `D:\backups\uplan\2026-11-02-keyboard\` (327 files = the phone's, 569 MB, integrity `ok`, 309 photos and 0
     missing, database SHA-256 `5325e54a…`, 35 tasks). `install -r` at 15:38: still `DEBUGGABLE`, 327 files, the same
     3 booked reminders (`flutter.alarm_notif_10105`–`10107`), 57 alarm lines before and after. The real try (the
     widget's intent sent by adb, not tapped by hand): Uplan open in the background, then "+": keyboard up
     (`mInputShown=true`; 4 early asks ignored, no hide from Android this time); keyboard up, Home, "+" again: up
     (Android's `HIDE_WINDOW_GAINED_FOCUS_WITHOUT_EDITOR`, then the sheet's later ask won); Back, Back: keyboard
     down, sheet closed, his home screen in front; nothing added (35 tasks, 126 notes, integrity `ok`, copy in
     `after\`).
   - ⬜ **Ahmed's own try of the "+": no keyboard** (2026-11-02 about 15:45, his words: "no but no problem"). So the
     fix works when the widget's intent comes over the cable but not when he taps the widget: a real tap differs
     somehow (my guesses, not checked: the launcher's opening animation delays the window's focus beyond the sheet's
     0.75 s of asks, or the launcher adds other intent flags). Not investigated yet. Cheapest next look: the next time
     the phone is on the cable, he taps the widget's "+" once while `adb logcat` records ImeTracker,
     InputMethodManager and WindowManager lines.
   - ✅ **Reminders in the quick-add sheet, and a custom 4th one** (2026-11-02 15:45–16:30; `cf5ce41` on `master`).
     His request: "add also the notification alert options to be added from here too and make a 4th option for
     alarms which adds a custom time other than i meant reminders by saying alarm." His picks: the custom one is "an
     amount before due" (not an exact date and time), and look B, "B is cleaner" (chips right in the sheet; the two
     looks were shown as a sketch first). What it does now: the quick-add sheet has a bell row under date, time and
     priority (1 day, 3 h, 5 min, + Custom: a number in min, hours or days, up to 30 days, via
     `lib/features/tasks/presentation/widgets/custom_lead_dialog.dart`); without a date it says "Set a date for
     reminders to go off"; send saves them (`reminderLeadTimes`) and books them like the full screen (best effort,
     6 s cap). The full task screen has a 4th tick, "Custom" ("Custom: 30 minutes before" once set). A custom amount
     equal to a standard one ticks that one. Booking: up to 4 reminders per task; slots 0–2 keep 10000 + id×3 + slot
     (already-booked reminders still get cancelled), the 4th is 40000 + id
     (`NotificationService.taskReminderId`, `maxTaskReminders`). Notifications say the exact amount ("Due in 90
     minutes"; the old wording rounded down). Rules and wording: `lib/features/tasks/domain/reminder_leads.dart`.
     19 new tests (8 rules, 3 booking numbers, 6 quick-add, 2 full screen; all but the "no reminders saves none"
     guard failed first); 367 pass; analyze clean. Tried on the Flip emulator's fast build: the bell row looks like
     look B; all three plus Custom 30 min for 5 Nov booked 10474–10476 and 40158 with the right words, and Android's
     alarm list holds them (4 Nov 09:00; 5 Nov 06:00, 08:30, 08:55). Not waited for one to fire. Not on the phone
     yet. The full screen's Custom tick was checked by its 2 widget tests only, not on the emulator.
   - ✅ **The reminders build on his phone** (2026-11-03 15:15–15:17, Ahmed: "Phone plugged in"). Before: origin
     still `fef5fc6`, the phone still on the 2026-11-02 15:38 build. His folder copied to
     `D:\backups\uplan\2026-11-03-reminders\` (327 files = the phone's, 569 MB, integrity `ok`, 309 photos and 0
     missing, database SHA-256 `fa9bb89d…`, 35 tasks, 126 notes). `install -r` at 15:16 of the fast build from
     `cf5ce41` (fingerprint checked): still `DEBUGGABLE`, 327 files, the same 3 booked reminders
     (`flutter.alarm_notif_10105`–`10107`). Android's alarm list then held Uplan's widget refresh (4 Nov 00:01) and
     that task's three reminders (11 Jan 2027 12:00; 12 Jan 09:00 and 11:55); the crude `dumpsys alarm` line count
     (65 → 60) moves with Android's removal history, not with pending alarms. The new bell row on his phone: not
     seen by me (his eyes).
   - ✅ **His real taps of the "+", logged** (2026-11-03; Ahmed: "Keyboard came up"). The first recording
     (15:17–15:27, 24,421 lines) caught no tap; the second (from about 15:30) caught two, at 15:32:21 and 15:32:30
     (both `START u0 {act=…home_widget.action.LAUNCH dat=uplan://add_task … flg=0x10000000}`, the same flags as the
     cable test). Tap 1 (Uplan open in the background): two early asks ignored (.545, .554), window focus .568, no
     `HIDE_*` from Android (the native line works), the sheet's ask at .618 shown at 22.333 (0.9 s after the tap).
     Between the taps he pressed Home with the sheet still open (28.95; the launcher's `HIDE_UNSPECIFIED_WINDOW`).
     Tap 2 (the same sheet still open, then "+"): two early asks ignored (.872, .878), window focus .926, and then
     **no ask at all** for 5 s; at 36.115 Android's `HIDE_SAME_WINDOW_FOCUSED_WITHOUT_EDITOR` (the window focused
     again), then two asks 148 ms apart (the sheet's repeat, so a fresh "resumed") and the keyboard at 36.721. So
     tap 2 got its keyboard only after a second focus change. The same case passed 3 of 3 on the emulator. My reading
     (not proven): on his phone Flutter reported "resumed" before the window had focus (the early asks are the
     restored focus reopening the text field), so the sheet's one-time check ran while its field had no focus yet and
     didn't start the repeats, and the real focus brought no new "resumed". Logs: the Tester's scratchpad
     `tap_log2.txt` (not in the repo).
   - ✅ **The "+" investigated properly** (2026-11-03 15:45–16:15; Ahmed: "some times it comes sometimes no and the
     first time i open it after awhile i think the apps pops up in the background for a split second and disappears.
     you work in that, no shortcuts and token preservation nor time restrictions take your time"). Tools made in the
     worktree's `tool/emulator/`: `plus_video.sh` (films a "+" in one situation; `TAP="x y"` taps the widget instead
     of sending its intent), `frame_times.py` (each frame's time and brightness), `phone_plus.sh` (real widget taps in
     four situations), `fresh_plus.sh` (a "+" on a truly closed sheet, with a check of the window in front before every
     tap). Videos and logs: the Tester's scratchpad (`video\`, `phone_runs\`; his data, not in the repo). Found:
     1. **The flash** (checked on video): when Uplan's own window is open in the background, the "+" reuses it
        (`onNewIntent` → `openQuickAdd` → `appRouter.go('/quick-add')`, and `/quick-add` uses the default page
        transition), so his last app screen shows first: emulator 1.14–1.33 s fully on screen (light mode), phone about
        0.2 s behind the sheet (dark mode). No flash when the sheet gets a new window, or when it was left open.
     2. **His place in the app is lost**: the reused window's screen is replaced by the sheet. On the emulator, Back
        then closed the app and reopening showed a fresh Home; on his phone (Samsung), Back only sends the app back, so
        **tapping Uplan's icon afterwards showed the add-task sheet** instead of his app (screenshot, 16:02).
     3. **The keyboard**: Flutter's engine starts each window believing it has focus
        (`LifecycleChannel.java:41`, `private boolean lastFocus = true;`), so a new window reports "resumed" at
        `onResume`, before Android gives it focus, and nothing new when the focus comes. His phone is fast: on a "+"
        with a new window (the sheet closed with its dimmed area first, `fresh_plus.sh`), Dart's `main()` printed at
        +0.047 s, the first frame at +0.075 s, the text field's two keyboard requests at +0.088 and +0.102 s (both
        "not served"), the window's focus at +0.150 s, and then nothing: **no keyboard in 3 of 3**. The emulator is
        slower, so its first frame came after the focus and it never missed. In the reused-window cases the order
        varied (keyboard 9 of 9 in scripted real taps, but his tap 2 at 15:32 missed), and a keyboard left up when
        leaving may also leave Flutter's view insets stale, which makes the sheet's re-ask skip.
     4. **After `am force-stop`** the widget's "+" does nothing on the first tap: force-stop cancels the app's
        shortcuts (the widget's PendingIntents); the tap only made Android refresh the widget (`APPWIDGET_UPDATE`).
        Only matters after a Force stop; a normal background kill keeps them.
     Also learned: Back on the sheet doesn't close Uplan on his phone (Samsung moves the task back), but the sheet's
     own send or a tap on its dimmed area does (`SystemNavigator.pop()` → `activity.finish()`). Mistake: my first
     scripted runs pressed Home while his home screen was already showing, which jumps to his first page; taps then
     hit his date and weather widget and opened Weather and Google Calendar (nothing changed in them; his phone was
     left on his first home page). The scripts now check the window in front before every tap.
   - ✅ **The keyboard fix, tried on the emulator** (`f348af0`: `onWindowFocusChanged(true)` → `uplan/quick_add`
     `windowFocused`, then the sheet asks every 150 ms for 1.2 s while a field has focus, until a keyboard comes up,
     without trusting view insets left from before; 3 new tests, each failed first). On the Flip emulator's fast build
     (`3946054`, 2026-11-03 20:40–20:44) the keyboard came up in every case: the "+" on a running app 3 of 3 (Android
     ignored the first two asks each time), a stopped app, keyboard up then Home then "+", a fresh window 3 of 3
     (drawn about 1.0 s after the "+"). Its first emulator run (16:27) had been spoiled twice: the build had failed on
     a damaged Kotlin cache and my command still installed the old APK (the pipe into `grep` hid the failure), then
     **the PC had 0.2 GB free** while Ahmed played Phantom Blade Zero (`PBZ.exe`, about 13 GB) and my Gradle and two
     Kotlin daemons held about 5 GB (stopped). Two damaged build caches went to the Recycle Bin
     (`D:\dev\pub-cache\hosted\pub.dev\jni-1.0.0\android\.cxx`, the side checkout's
     `build\app\kotlin\compileProfileKotlin`). Since then a build goes on only after "Built build", and one emulator or
     one build runs at a time.
   - ✅ **The sheet in its own window** (Ahmed, 2026-11-03: "Yes, build it"; 20:23–21:15; design
     `docs/superpowers/specs/2026-11-03-quick-add-own-window-design.md`, plan
     `docs/superpowers/plans/2026-11-03-quick-add-own-window.md`; `7d33c89`, `c2dee3f`, `2f87784`, merged with the Uplan
     chat's workout log as `b7c92c8` on `master`, pushed). What it does now: the widgets' "+" opens `QuickAddActivity`,
     the sheet in a window and a task of its own (`taskAffinity ""`, `singleTask`, `excludeFromRecents`, not
     exported), with its own Flutter engine; `UplanEngineSetup.kt` holds what both windows set up (the widgets'
     midnight refresh, the `uplan/live` channel); MainActivity keeps the old `uplan://add_task` path for a "+" drawn
     before the update (the app's next start redraws the widgets). Whenever the app comes back to the front it re-reads
     tasks and lists another window wrote (`lib/core/database/changed_elsewhere.dart`, `markTasksChangedElsewhere`).
     Checked: 2 new tests (two connections to one database file; both failed first on an empty stub); 388 pass with
     the workout log; analyze clean. On the Flip emulator, `tool/emulator/own_window_check.sh` (new) failed cases 1–4
     on today's build (the "+" in the app's task, closing ended the app's window, the icon then showed Home instead of
     Notes) and passes all 5 on the new one (its own task; the app untouched; Notes again from the icon, difference
     0.0; Back, Back closes the sheet for good; a sheet left with Home comes back with its text). Videos (warm, again,
     cold, dead): no app frame before the sheet (today's build showed the app's Home for about 0.3–0.4 s). The
     keyboard came up in every case; fresh windows were drawn about 0.8 s after the "+" (1.0 s before). A task filed
     into Errands from the sheet while the app sat on Lists: Errands went 17 → 18 when the app came back. An old-style
     "+" still opens the sheet. With only the sheet's window alive and the live dashboard switched on (emulator only,
     off again after), the dashboard's service started, so the new window answers `uplan/live`. The log over 21 sheet
     openings: no missing-channel errors, crashes or Flutter errors. **One difference from the design:** the sheet's
     card shows in Recents right after he leaves an open sheet with Home (Android keeps the newest task even when it is
     marked hidden), until he opens another app; tapping it brings the sheet back as it was. Not on the phone yet.
   - ✅ **One install on his phone for both** (2026-11-04 17:00–17:12; Ahmed told both chats "Phone plugged in" and
     asked them to coordinate; agreed by message that the Tester installs and the Uplan chat stays off the phone).
     Master's code hadn't moved since `b7c92c8`; the fast build from it (built 2026-11-03 21:14) was checked again:
     Uplan's key `5b269323…c7ac5`, v1.18.0 (27), `application-debuggable`, `QuickAddActivity` inside. adb first listed
     no device although Windows showed the phone's "ADB Interface" (WinUSB, the ADB interface GUID); a few seconds
     later it did (`R5CX631BMJB`), nothing restarted. Before: the phone still had the 2026-11-03 15:16 build; his
     folder copied to `D:\backups\uplan\2026-11-04-own-window\` in 38 s (327 files = the phone's, 568.5 MB, integrity
     `ok`, 309 photos and 0 missing, database SHA-256 `fa9bb89d…` = yesterday's backup, user_version 25, 77 workouts,
     308 sets, 35 tasks, 126 notes; booked reminders `flutter.alarm_notif_10105`–`10107`). `install -r` at 17:04:12
     (fingerprint checked right before). First start from the launcher intent: Uplan drawn in 0.27 s, no crash, no
     Flutter errors, no missing channels, no freeze, the same 3 booked reminders. The database afterwards (copied off
     to `after\`, the app idle): user_version 26, integrity `ok`, 0 foreign-key problems, `completed_at` and
     `finished_at` present, every one of the 24 tables kept its row count (the Uplan chat's check, passed). Real taps
     on his month widget's "+" (its second home page; every tap guarded: the launcher in front and on the widget's
     page, compared with a screenshot; scripts in the Tester's scratchpad, his data, not in the repo): the "+" started
     `QuickAddActivity` (the widgets had redrawn) in a task of its own, drawn 85–135 ms after the tap; on film his
     home screen, then the sheet over it: **no app frame**. The keyboard came up in every case: 5 of 5 fresh windows
     (0 of 3 on 2026-11-03), each time after Android ignored the sheet's early asks, with no hide from Android. A tap
     on the dimmed area closed the sheet and left the app's window alive; Uplan's icon then showed exactly the screen
     from before the "+" (difference 0.0, twice). Back, Back closed the sheet for good. A sheet left with Home came
     back as the same sheet with "milk" still typed; the dimmed-area tap then threw it away (35 tasks, no "milk",
     integrity `ok`). Not tried on the phone: a task sent from the sheet into a list open in the app (checked on the
     emulator), the live dashboard from the sheet's window (emulator), the Recents card after Home.
   - ✅ **His own try: "Works well"** (Ahmed, 2026-11-04 about 17:15, after the Manual Test Steps in the chat). The
     retro is in `D:\projects\claude-setup\workflow\retros.md` (2026-11-04 entry; about 1.67M tokens for the whole
     "+" fix, counted from this chat's transcript). After it the Tester chat cleared itself for a fresh start in place
     (a long, twice-compacted chat makes every reply expensive), so the next message starts from these files.
   - ⬜ **← next: Ahmed's pick** (asked 2026-11-04 in the chat's box, buttons "Yes, show looks first" and "Hand back
     now"):
     1. **An ordinary window for the main app** (the first "Noticed" item below; recommended). MainActivity gets a
        theme of its own that isn't see-through, and `getBackgroundMode()` stays default (opaque), so every app screen
        moves to Flutter's faster surface drawing and Android shows a start screen at once when he taps the icon;
        QuickAddActivity keeps the see-through theme. The start screen is something he judges by eye, so first show
        him 2–3 looks of it on the emulator (for example the app's own background colour only; Android's start screen
        with Uplan's icon; that icon on a dark background), build the one he picks, then measure: the time to the
        first frame from the icon and scroll smoothness on a long list, before and after, on the emulator and his
        phone. Size guess: small to medium, 45–90 min of work plus one install (his data copied off first).
     2. **Hand back** (step 7): the round table's other ranked items stay parked in
        `docs/superpowers/round-table-2026-11-01.md` for him to pick later; the Uplan chat takes the repo back, and
        this chat offers to be archived.
   - ✅ (yesterday's state, kept for the record) the fast build was picked (Ahmed, 2026-11-01 about 14:50: "Fast build", after asking how it
     differs: both builds carry the same fixes; only the speed differs). Built 14:51–14:54 in `D:\projects\trackerapp`
     from `ed1ad20` (code = `44f8d2d`): `build\app\outputs\flutter-apk\app-profile.apk`, 93.0 MB, v1.18.0+27,
     certificate SHA-256 `5b269323…c7ac5` (Uplan's key), `application-debuggable` (so `run-as` stays open). Tried for
     real on the Flip emulator with the worktree's profile APK (same code, debug key): Settings › Diagnostics › "Test
     scheduled reminder (1 min)" went off with the app's process killed (scheduled 14:54:30; Android started the app
     for the alarm at 14:55:28; notification 997 posted by 14:55:31), and a live-notification snooze broadcast
     (`uplan://live?action=snooze&type=task&id=1`) ran `liveBackgroundCallback` from a cold start (`live_snoozes`
     `{}` → `task:1`). Both background entry points carry `@pragma('vm:entry-point')` (checked); nothing in the app's
     own code acts differently between debug and profile (only generated Riverpod hashes read `dart.vm.product`).
     **Waiting: the phone wasn't on the cable** (`adb devices` empty at 14:47 and 14:56). When it is: copy his data off
     (signing-key plan Task 4 steps 2–4, into a new `D:\backups\uplan\2026-11-01-fast-build\`, never the morning's
     folder), `adb -s R5CX631BMJB install -r` that APK (never uninstall), start it normally (re-books the reminders
     that the copy's force-stop cancelled), compare Uplan's alarm count before and after, open the widget's quick-add
     once and close it with Back. No stopwatch build on his phone (not asked). The Uplan chat was idle since 11:06 and
     wasn't woken; it learns of the fast build from these files and START HERE.
7. ⬜ Hand back: state into these files, then offer to be archived.

## Checked so far (2026-11-01, read only; nothing on the PC or the phone changed)
- **The PC can run emulators after one Windows switch.** AMD virtualization is on in the BIOS
  (`Win32_Processor.VirtualizationFirmwareEnabled` True) and Windows' own hypervisor already runs for Memory Integrity
  (`Win32_DeviceGuard`: VBS and HVCI running). Windows Hypervisor Platform, Virtual Machine Platform and Hyper-V are
  all off (`Win32_OptionalFeature` InstallState 2). The emulator needs Windows Hypervisor Platform on: Ahmed's own
  click (Turn Windows features on or off), then a restart. Google's AMD driver (AEHD) is no way around it: as I
  remember Google's docs, it can't run while Windows' hypervisor does (not checked).
- 16 GB RAM (one emulator at a time is the comfortable load), 6 cores; free space C: 348 GB, D: 230 GB.
- `D:\dev\android-sdk` has no emulator, no system images and no AVDs (platforms 34–36, build-tools 36.0.0,
  cmdline-tools whose `sdkmanager` now hands over to `android.exe`: pass `--no-metrics`).
- Download sizes (Google's repository lists, read 2026-11-01): emulator 37.2.13 (stable) 455 MB; Android 16
  `system-images;android-36;google_apis;x86_64` 1,895 MB; Android 13 `android-33` 1,708 MB (Android 12 `android-31`
  1,471 MB; Android 17 `android-37.0` 2,144 MB). The emulator plus Android 16 and 13: about 4.1 GB.
- The code: 215 hand-written Dart files, about 36,700 lines in `lib/` (workout 8.4k, notes 5.0k, tasks 4.0k, trackers
  2.6k, home 2.1k), 46 test files. The home-screen widgets: Kotlin in
  `android/app/src/main/kotlin/com/lifetracker/life_tracker/` (`Uplan*WidgetProvider.kt`, `*RemoteViewsFactory.kt`,
  `MainActivity.kt`) plus `lib/core/widget/home_widget_service.dart` and
  `lib/features/tasks/presentation/screens/quick_add_task_screen.dart`.
- Not checked yet: whether a profile build keeps the phone's `run-as` door open (as I remember it, Flutter's profile
  build type copies the debug one, so probably yes; check the APK's `debuggable` flag before saying so).

## The widget's add-task: what the code shows (read 2026-11-01; nothing measured yet)
- The "+" opens `MainActivity` with `uplan://add_task` (`UplanWidgetProvider.kt:49`). A new engine starts on
  `/quick-add` (`MainActivity.getInitialRoute`); a running one gets `openQuickAdd` (`onNewIntent`, then
  `app.dart` `_onWidgetMethod`).
- Saving or dismissing calls `SystemNavigator.pop()` (`quick_add_task_screen.dart:63`), which finishes the activity,
  and an activity that made its own engine destroys it (checked: Flutter's `FlutterActivity.shouldDestroyEngineWithHost`,
  `D:\dev\flutter\engine\src\flutter\shell\platform\android\...\FlutterActivity.java:1081`). So every "+" starts the
  whole Flutter app again, `main()` and the launch work included.
- The whole app runs in a see-through window: `windowIsTranslucent` in both themes (`res/values*/styles.xml`) and
  `getBackgroundMode()` transparent (`MainActivity.kt:22`), which puts every screen on Flutter's texture rendering
  instead of its faster surface rendering (checked: `FlutterActivity.getRenderMode`, `FlutterActivity.java:1248`).
  Android shows no splash for a see-through window (as I remember Android's starting-window rule; to check on the
  emulator), so nothing appears between the tap and Flutter's first frame.
- Before the first frame `main.dart` awaits the alarm plugin's start (which spins up a second, background Flutter engine:
  checked, `android_alarm_manager_plus-4.0.8` `AndroidAlarmManagerPlugin.java:98`), the widget callback, SharedPreferences
  and `NotificationService.init` (three channels, a permission request, the exact-alarm check).
- Right after the first frame `app.dart` `_reschedule()` re-books every reminder (`NotificationService.rescheduleAll`:
  for each open task with a reminder, 9 platform calls just to cancel its 3 slots, then 3 more per future slot),
  purges Recently deleted, syncs the widgets and the live dashboard and checks for an update, while the sheet opens
  and the keyboard comes up.
- Saving awaits the insert, then `HomeWidgetService.sync` (one query per habit, every task, every shift; about 13
  preference writes and 3 widget redraws when anything changed) before the sheet closes (`quick_add_task_screen.dart:98-111`).
- And the phone runs a debug build, which does all of this much more slowly.
- **A profile build keeps the phone's `run-as` door open** (checked 2026-11-01): Flutter's Gradle plugin makes the
  profile build type from the debug one (`FlutterPlugin.kt:209`, `initWith(debugBuildType)`), and the worktree's
  `app-profile.apk` (v1.18.0+27, 92.9 MB, arm64 + arm32 + x86_64, target SDK 36) shows `application-debuggable` in
  `aapt2 dump badging`. So the phone could run a fast (AOT) profile build without losing the full-copy backup path.
  First worktree build: pub get 10 s, build_runner 79 s, `flutter build apk --profile` 3 min 45 s.
- **Seen on the emulators (2026-11-01, profile build, demo data):** when the keyboard opens, the quick-add sheet
  stretches to the top of the screen with a blank band above the keyboard: `quick_add_task_screen.dart:148` adds
  `MediaQuery.of(context).viewInsets.bottom` while `resizeToAvoidBottomInset: true` already lifts the body, so the
  keyboard's height counts twice (seen on all three emulators). The first launch after install took 4.5 s to
  "Displayed"; later cold starts about 2.1 s, but Flutter doesn't hold back Android's first draw in texture mode
  (checked: `FlutterActivity.java:807`), so that number stops before Flutter's first frame. On the foldable emulator
  5 of 14 cold starts had drawn nothing after 5 s (all had by 9 s). The alarm plugin's second engine starts about 1–5 s
  after the window appears (logcat: a second "Using the Impeller rendering backend" line).
- Next: measure on a profile build (an emulator first): tap to sheet, send to closed, with and without the launch work.

## Size (Ahmed chose three helpers, 2026-11-01 about 10:05)
The helpers' briefs: `round-table\briefs.md` in the shared notes folder
(`C:\Users\kille\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_48e18ebc-7554-47c5-9e1a-ac62e7be4fcb`).
Seats: product and flows, looks, code; the chair (this chat) takes start-up speed and the widget. Big, in rounds: my work about 2–3 h before the fixes (emulators 20–30 min, screenshots on three sizes 20–30 min, the
widget lag 45–90 min, the ranked page 30–45 min), plus 30–60 min of waiting (downloads, builds, tests); the fixes get
their own estimate once he picks. Tokens (guesses from earlier helpers' costs): two helpers (product and looks; code)
plus this chat about 0.9–1.4M; three helpers about 1.1–1.7M; this chat alone about 0.7–1.0M. His yes also covers the
4.1 GB download above.

## Must know (from the Uplan chat's brief)
- The phone's Uplan is a fast (profile) build since 2026-11-02, still debuggable (`run-as` works): judge speed on a
  profile or release build (an emulator, or his phone with his OK). A release build on the phone closes `adb run-as`, today the only full copy of its data: his call.
- Never uninstall the phone's app. Check an APK's fingerprint before `adb install -r` (device skill), and copy his
  data off first the way the move did (`docs/superpowers/plans/2026-11-01-signing-key.md`, Task 4).
- Stay on Flutter 3.44. Android CLI commands need `--no-metrics`. Never change Smart App Control.

## Carried over from the signing-key move (2026-11-01)
- **The signing-key move is done** (2026-11-01; plan `docs/superpowers/plans/2026-11-01-signing-key.md`, design
  `docs/superpowers/specs/2026-11-01-signing-key-design.md`). The phone's Uplan (v1.18.0+27, a debuggable build) is
  now signed with Uplan's own key (START HERE has its place and fingerprint), under the same app ID, with all its
  data: the database byte for byte (SHA-256 `9a9ad0ad…`), all 309 photos, the Settings. Uplan's alarm entries came
  back (40 after the move, 38 before). Ahmed's first look: "initial; look is ok".
- The checked copy of the phone's folder stays in `D:\backups\uplan\2026-11-01\` (personal data, never in git) until
  Ahmed is happy; what happens to it then is his call.
- Asked of Ahmed after the move, not confirmed yet: Alarms & reminders on, battery Unrestricted, the widgets added
  again, the feedback key typed in again if he uses it, and the key's password copied into his own safe place.

## Later
1. Release v1.18.0 (it carries v1.16.0 and v1.17.0 too) with the release ritual in
   `.claude/skills/uplan-device-release/SKILL.md`. A release build needs Smart App Control in evaluation mode. A
   release build on the phone isn't debuggable, so `run-as` would stop working there, and the app's backup leaves out
   photos and Settings: decide that with Ahmed first.
2. G4's owed check: time the inexact-alarm path on the Z Flip 6 (recipe in `docs/superpowers/STATUS-2026-07-28.md`, G4 section).
3. **Heavy testing, then Google Play** (Ahmed, 2026-10-31; master plan, "Before a Play Store launch").

## What the signing-key move found (2026-11-01; checked unless marked)
- **Google Play accepts our own key** (checked: support.google.com/googleplay/android-developer/answer/9842756):
  "Must be an RSA key of 2048 bits or more", uploaded with Google's PEPK tool. So a key made now can serve Play later,
  and the phone needs only this one reinstall. A lost upload key is recoverable later (Play's upload key reset).
- **The app ID `com.lifetracker.life_tracker` isn't used by any public app on Play** (checked: its Play page answers
  404 "Not Found"). An unpublished or removed app could still hold it; Play only says so at the first upload.
- **The backup has no photo files** (checked: `lib/core/backup/backup_service.dart`,
  `lib/core/images/image_storage_service.dart`). Photos live in `<app documents>/note_images/`; the backup JSON keeps
  only their file names, and the app has no share or save action for photos. Settings (SharedPreferences) aren't in
  it either.
- **But the phone's Uplan is a test build, so the cable tool can copy everything** (checked on the phone over adb,
  2026-11-01, after Ahmed asked why the photos can't move): `dumpsys` shows v1.18.0 (versionCode 27), installed
  2026-06-29, last updated 2026-09-29 23:49, with the `DEBUGGABLE` flag, and `adb shell run-as
  com.lifetracker.life_tracker` opens its private folder. Inside: `app_flutter/life_tracker.db`,
  `app_flutter/note_images/` (309 photos, 457 MB; `app_flutter` is 543 MB in all), `shared_prefs/` (settings, widget
  data, scheduled notifications), `databases/`, `files/`. The external folder
  `/sdcard/Android/data/com.lifetracker.life_tracker/files` is empty.
- **One thing can't be copied:** `flutter_secure_storage` keeps its values under a key in Android's key store, which
  dies with the install. Only `lib/core/github/github_feedback_service.dart` uses it (the in-app feedback's GitHub
  key), so that sign-in gets entered again. Its value is a secret: don't read or copy it.
- **The phone already runs v1.18.0, not v1.15.1** (the old assumption was wrong), so its data is already at schema 25
  and the old-backup restore bug (under Noticed) doesn't block this move.
- Assumed, not checked: only Ahmed uses Uplan.

## Decided
- **One app with the same ID, moved by a full copy of its private folder** (Ahmed, 2026-11-01: "Yes, one app").
  It replaced his earlier "side by side" pick, made while the photos looked impossible to copy. The uninstall comes
  only after the copy is checked on D: and a dress rehearsal in a throwaway test copy has passed.

## Also waiting on Ahmed
- **His opinion of the signing-key move, for its retro** (the retro is in `D:\projects\claude-setup\workflow\retros.md`
  with his words so far, "initial; look is ok"; add his opinion as a new line when he gives it).
- Written 2026-10-31 20:40, before that chat's fresh start:
- **His opinion for two retros** (asked: "in a few words, how did this install round feel to you?"). Then add both to
  `D:\projects\claude-setup\workflow\retros.md`:
  1. The auto-load kit's first live test (2026-10-31): START HERE, the current task and the last 5 history lines all
     loaded by themselves.
  2. The build-tools install (2026-10-31): estimate "small: 20–30 min of my work, 20–40 min of downloads, then a
     5–10 min first build"; real about 75 min (14:16–15:30), with an unplanned switch from Flutter 3.47.9 to 3.44.9
     and a 17-min first build. Demo first, no helpers. Mistakes: the newest Flutter went in before reading the app's
     pinned version; two Android SDK installs sent Google usage data before `--no-metrics`; the build estimate forgot
     a fresh PC's downloads. Tokens: not counted yet (count them from this chat's transcript the Live Tracker's way).
- **His own OK for two START HERE lines** (from this chat's round-table plan, which he approved through the Manager on
  2026-10-31; a `CLAUDE.md` edit waits for his word in this chat): the pinned versions (Flutter 3.44 from `.metadata`;
  AGP, Gradle, Kotlin and the NDK from the Android build files), and `docs/_Undo_Table.md` in the handover-files line.
- **His yes to switch Flutter's and Dart's usage reporting off outside the Claude app too.** Checked from outside on
  2026-10-31: the opt-out was saved under `%APPDATA%`, so it holds only inside the app (`docs/_Undo_Table.md`, row 3).
  Nothing runs Flutter outside the app today. The fix: run `D:\dev\flutter\bin\flutter.bat --disable-analytics` and
  `D:\dev\flutter\bin\dart.bat --disable-analytics` from a `.cmd` started through explorer.exe.
- This chat's round-table plan (approved 2026-10-31) also says: read the project's pinned versions before any install,
  switch a new tool's usage reporting off before its first run, and lead every reply with the answer.

## Done means (Tester)
- [x] A ranked round-table report Ahmed has read (a page for his tablet, a copy in `docs/`): he picked from it on
      2026-11-01 ("A, then B").
- [x] The widget's add-task lag fixed, or explained with numbers from a profile or release build. (Explained with
      numbers on 2026-11-01; batch B built; the fast build on the phone 2026-11-02; the missing keyboard on a running
      app's "+" found on the phone 2026-11-02, fixed the same morning (`64091f9`) and on the phone since 15:38; the
      sheet in its own window, with the keyboard asked on window focus, on his phone since 2026-11-04 17:04: no app
      flash on film, the keyboard up 5 of 5 times; Ahmed: "Works well".)
- [x] The fixes he picked built, analyze clean, all tests green, committed on `master` and pushed.
- [ ] The handover files updated; Tester hands back and offers to be archived.
(The signing-key move's own checklist is all done: `docs/superpowers/plans/2026-11-01-signing-key.md` and the history.)

## Do not touch
- **The gym smart-order files are free again** (the Uplan chat, 2026-11-01: committed and pushed as `d3b3165`, analyze
  clean, 329 tests pass; if Ahmed's phone try finds a bug, it says so before touching them again): the workout DAO,
  repository and providers, `program_session_editor_screen.dart`, `active_workout_screen.dart` and the new
  `smart_order.dart` (design and status: `docs/superpowers/specs/2026-11-01-gym-smart-order-design.md`). The Tester
  still builds and changes code in its separate worktree, `D:\projects\trackerapp-tester` on branch `tester/speed`
  (made 2026-11-01 from `eb587fa`, fast-forwarded to `d3b3165`), and merges into `master` when a fix batch is done.
  That worktree has no `key.properties`, so its builds carry the debug key: emulators only, never the phone. The
  handover files stay in `D:\projects\trackerapp`.
- The phone's Uplan: never uninstall it to get past an install error (that deletes its data). A build carrying the
  new key updates it in place with `adb install -r`.
- No key file or password in git, chat or logs. Smart App Control and other security settings stay as they are.
- `D:\backups\uplan\2026-11-01\` until Ahmed decides.

## Noticed (not fixing now)
- **The main app no longer needs a see-through window** (found 2026-11-03, building the sheet's own window): only
  the quick-add sheet shows the home screen behind it, and it now has a window of its own. MainActivity is still
  see-through (`windowIsTranslucent` in `LaunchTheme`, `getBackgroundMode()` transparent), which keeps every app
  screen on Flutter's slower texture drawing (`FlutterActivity.getRenderMode`) and gives no start screen between a
  tap on the icon and Flutter's first frame. An ordinary window for MainActivity (its own theme, QuickAddActivity
  keeping the see-through one) would fix both; a "+" drawn before the update would then open the sheet over the
  app's window background instead of the home screen, until the widgets redraw. Worth doing once the own window is
  on his phone; it changes how the app's start looks, so show it first.
- **v1.18.0 can't restore a backup made by an older version** (checked in the code, not by a test): schema 24 added
  `notes.isFavorite` and 25 added `notebooks.isFavorite`, both required booleans, and the generated `fromJson` throws
  on a missing key, so the whole import rolls back. Not needed for the signing-key move (the phone is on v1.18.0);
  worth a fix with a regression test before anyone restores an old backup. Found 2026-11-01.
- **The backup could carry photos and Settings** (a zip with the JSON plus `note_images/`), so a lost phone or a
  future reinstall keeps them. Found 2026-11-01; not this task. For the master plan's parked list if Ahmed wants it.
- **AppData writes from a chat stay inside the Claude app's private copy**, like the registry. Checked from outside on
  2026-10-31: `%LOCALAPPDATA%\pip`, `%LOCALAPPDATA%\npm-cache` and `%APPDATA%\GitHub CLI` exist only inside the app.
  That's why the build tools and the Dart package cache live in `D:\dev`. Passed to the AI management chat.
- `flutter doctor` says "Android license status unknown": it can't read the new Android CLI's license list. The build's
  own license check passes. Only the Android SDK license was accepted (Ahmed's OK, 2026-10-31).
- The first build on this PC left `android/.kotlin/` (Kotlin's build session folder) untracked. It belongs in `android/.gitignore`; not committed.
- The 10 plan files in `docs/superpowers/plans/` never had their check boxes ticked, although the work shipped. The master plan is the record of what is done.
- `feedback/app.md` still shows all 4 items unticked. 3 are done (today marker in v1.9.1; per-list auto-archive and photo crop in v1.10.0); the 4th (a Samsung- or Apple-style note design) is largely answered by the notes redesign.
- STATUS refers to "Working Style #11" (general, non-clinical examples in user-facing text), but this repo's `CLAUDE.md` lists only 8 Working Style rules. STATUS also says the durable project history lived in a CLAUDE.md in OneDrive, outside the repo. No such file was found in OneDrive on this PC (2026-10-27), so rules 9 and up may be lost. The decisions log records #11.
- STATUS's "IN-FLIGHT" section (2026-07-28) is out of date: the editor redesign and the photo grid shipped in v1.10.0, and the August shift entry is long past.
- `README.md` is still Flutter's default text.
- GitHub shows this repo as public, while the device skill calls it "the private source repo". Worth checking which one Ahmed wants.
