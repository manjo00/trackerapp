# The quick-add sheet in its own window: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> On Ahmed's PC the rule is superpowers:executing-plans, done in the chat itself, with no helpers unless he says yes
> (`C:\Users\kille\.claude\CLAUDE.md`). This plan is carried out by the Tester chat.

**Goal:** The widgets' "+" opens the quick-add sheet in a window of its own, so no app screen flashes behind the
sheet, the app keeps the screen it was on, and Uplan's icon always opens the app.

**Architecture:** A second Android screen, `QuickAddActivity` (a `FlutterActivity` with its own engine, always on
`/quick-add`), in a task of its own (`taskAffinity=""`, `singleTask`, `excludeFromRecents`). The three widgets' "+"
point to it; `MainActivity` keeps handling `uplan://add_task` for widget buttons drawn before the update. The sheet
now writes through its own database connection, so the app re-runs its task and list queries when it comes back to
the front.

**Tech Stack:** Kotlin on Flutter's Android embedding (Flutter 3.44.9), Dart (drift 2.28.2, Riverpod, go_router),
adb scripts on the emulator and the Z Flip 6.

**Spec:** `docs/superpowers/specs/2026-11-03-quick-add-own-window-design.md` (Ahmed, 2026-11-03: "Yes, build it").

## Global Constraints
- Flutter 3.44.9 (`D:\dev\flutter`), Java 21 (`D:\dev\jdk-21`), Android SDK `D:\dev\android-sdk`; Android CLI
  commands need `--no-metrics`; never change Smart App Control.
- No new packages.
- Code work in the worktree `D:\projects\trackerapp-tester` (branch `tester/speed`). Its builds carry the debug key,
  so they go on the emulator only. Phone builds come only from `D:\projects\trackerapp` (Uplan's key), as fast
  (profile) builds that stay debuggable.
- His phone: never uninstall Uplan. First copy his data off (`docs/superpowers/plans/2026-11-01-signing-key.md`, Task
  4 steps 2–4) into a new `D:\backups\uplan\<date>-own-window\`. Check the certificate SHA-256 `5b269323…c7ac5`
  before `adb install -r`. Check the window in front before every tap, and never press Home while the launcher is in
  front (Samsung then jumps to home page 1).
- Run one emulator or one build at a time (16 GB of RAM).
- Names fixed by the spec and the keyboard fix (`f348af0`): the class `QuickAddActivity`; the channel
  `uplan/quick_add` with the method `windowFocused`; the route `/quick-add`; the "+" intent is home_widget's
  `HomeWidgetLaunchIntent` (action `es.antonborri.home_widget.action.LAUNCH`) with data `uplan://add_task`.

## Review Focus
1. **A sheet left open with Home, then "+" again:** the same sheet comes back with what he typed, keyboard up.
   Covered by Task 1's `own_window_check.sh` case 5 and `kb_check.sh`.
2. **Back on the sheet:** the first Back hides the keyboard, the second closes the sheet's window for good (not
   parked in the background), the home screen is in front, and the app is untouched. Covered by case 4, with a
   fallback step in Task 4.
3. **A task filed into a list while the app sits on that list's screen:** the list shows it when he comes back.
   Covered by Task 2's tests and a Task 4 step.
4. **Widget buttons drawn before the update** still open the sheet (through MainActivity) until the widgets redraw.
   Covered by a Task 4 step.
5. **The sheet's window answers the `uplan/live` calls** the app makes when a window closes (the live dashboard's
   refresh), so the log shows no `MissingPluginException`. Covered by a Task 4 step.

---

### Task 1: The checks first, on today's build (emulator)

**Files:**
- Create: `tool/emulator/own_window_check.sh`
- Modify: `tool/emulator/plus_video.sh`, `tool/emulator/kb_check.sh`, `tool/emulator/fresh_plus.sh` (the "+" target
  is read from `TARGET`)

**Interfaces:**
- Produces: `TARGET=<.MainActivity|.QuickAddActivity> own_window_check.sh <serial> [dim-area x y]`, which prints
  `PASS`/`FAIL` per case. Every script sends the "+" as
  `am start -a es.antonborri.home_widget.action.LAUNCH -d uplan://add_task -n com.lifetracker.life_tracker/$TARGET`
  (`TARGET` defaults to `.QuickAddActivity`, which is not exported, so the emulator needs `adb root` first).

- [x] **Step 1:** Merge `master` into `tester/speed` (only docs are new since `a1fb63c`).
- [x] **Step 2:** Give `plus_video.sh`, `kb_check.sh` and `fresh_plus.sh` the `TARGET` variable for their `PLUS`
  line.
- [x] **Step 3:** Write `own_window_check.sh`. Start Uplan with its launcher intent plus `--es route /notes` (a
  screen other than the start tab), wait 8 s, take screenshot S1, then press Home. The cases:
  1. **own task:** after the "+", the focused window is `$TARGET`, and its task (`t<N>` in `dumpsys activity
     activities`) differs from MainActivity's.
  2. **app untouched:** after a tap on the dimmed area, MainActivity's record is still there and `$TARGET`'s is
     gone.
  3. **place kept:** Uplan's launcher intent then shows S1 again (mean grey-level difference under 6 of 255, top 5 %
     left out for the clock).
  4. **Back closes:** "+", Back, Back: `$TARGET`'s record is gone and the launcher is in front; the launcher intent
     shows S1 again.
  5. **a sheet left with Home comes back:** "+", type `milk`, Home, "+": the same task number as before. A
     screenshot shows the text, checked by eye.
- [x] **Step 4:** Build the profile APK in the worktree (`flutter build apk --profile`) and go on only after
  "Built build".
- [x] **Step 5:** Boot `uplan_flip_a16` on its own, run `adb root`, then `prepare.sh` (install, demo data,
  permissions).
- [x] **Step 6:** `TARGET=.MainActivity own_window_check.sh` must FAIL cases 1, 2, 3 and 4. This is the red run.
- [x] **Step 7:** `TARGET=.MainActivity plus_video.sh … warm` must show app frames between the "+" and the sheet
  (the flash).
- [x] **Step 8:** The owed device check of the keyboard fix: `TARGET=.MainActivity kb_check.sh` and
  `fresh_plus.sh` must show the keyboard up in every case.

### Task 2: Tasks written by another window show up when the app comes back

**Files:**
- Create: `lib/core/database/changed_elsewhere.dart` (an extension on `AppDatabase`; not inside
  `app_database.dart`, which the Uplan chat is changing for the workout log, uncommitted on 2026-11-03)
- Modify: `lib/app.dart` (`didChangeAppLifecycleState`, `resumed`)
- Test: `test/core/database/changed_elsewhere_test.dart`

**Interfaces:**
- Produces: `extension ChangedElsewhere on AppDatabase { void markTasksChangedElsewhere() }`, which re-runs this
  connection's stream queries that read `tasks` or `task_lists`.

- [x] **Step 1: Write the failing tests.** Open two `AppDatabase.forTesting(NativeDatabase(file))` on one temp
  file, called "the app" and "the sheet".
  - `'a list screen shows a task the sheet added, once told'`: the app listens to
    `TasksDao(app).watchTasksForList(listId)`, and the sheet calls
    `TasksRepository(TasksDao(sheet)).addTask('Milk', listId: listId)`. After 300 ms the app's latest list is still
    empty. After `app.markTasksChangedElsewhere()`, a list with titles `['Milk']` arrives within 2 s.
  - `'the sheet's list chips show a list the app added, once told'`: the sheet listens to
    `ListsDao(sheet).watchLists()`, and the app inserts a list named `Gym`. It is not seen after 300 ms. After
    `sheet.markTasksChangedElsewhere()`, the names include `Gym`.
- [x] **Step 2:** Add an empty `markTasksChangedElsewhere() {}`. Run
  `flutter test test/core/database/changed_elsewhere_test.dart`: both tests must FAIL on the "arrives" check.
- [x] **Step 3:** Implement it as `markTablesUpdated([tasks, taskLists])`. Run the same test: PASS.
- [x] **Step 4:** Call it from `app.dart` on `resumed`, with a comment naming the two writers: the quick-add sheet's
  own window and the live notification's background engine.
- [x] **Step 5:** `flutter analyze` must be clean and `flutter test` all green. Commit
  `fix(tasks): re-read tasks and lists another window wrote, on resume`.

### Task 3: The sheet's own window

**Files:**
- Create: `android/app/src/main/kotlin/com/lifetracker/life_tracker/UplanEngineSetup.kt`
- Create: `android/app/src/main/kotlin/com/lifetracker/life_tracker/QuickAddActivity.kt`
- Modify: `MainActivity.kt` (`configureFlutterEngine`, plus fallback comments)
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: the "+" in `UplanWidgetProvider.kt`, `UplanAgendaWidgetProvider.kt` and `UplanMonthWidgetProvider.kt`
- Modify (comments only): `lib/app.dart` (`_onWidgetMethod`), `quick_add_task_screen.dart` (`_windowChannel`,
  `_dismiss`), `lib/core/startup/launch_work.dart` (its "Quick-added tasks carry no reminder" is out of date since
  `cf5ce41`)

**Interfaces:**
- Produces: `object UplanEngineSetup { fun configure(activity: Activity, engine: FlutterEngine): MethodChannel }`.
  It re-books the widgets' midnight refresh (`MidnightRefreshReceiver.schedule` and `clearStaleSelection`) and
  answers `uplan/live`, then returns that channel. The `when` block moves from MainActivity unchanged, with
  `this@MainActivity` becoming `activity`.
- Produces: `class QuickAddActivity : FlutterActivity()`:
  - `getBackgroundMode()` returns transparent;
  - `getInitialRoute()` returns `"/quick-add"`;
  - `shouldHandleDeeplinking()` returns `false` (otherwise a second "+" pushes `uplan://add_task` into go_router
    through `onNewIntent`);
  - `configureFlutterEngine` makes the `uplan/quick_add` channel and calls `UplanEngineSetup.configure`, but never
    sets `MainActivity.liveChannel` (the notification buttons talk to the app);
  - `onWindowFocusChanged(true)` sends `windowFocused`.
- Manifest entry: `exported="false"`, `launchMode="singleTask"`, `taskAffinity=""`, `excludeFromRecents="true"`,
  the theme `@style/LaunchTheme` plus the NormalTheme meta-data, the same `configChanges` as MainActivity,
  `hardwareAccelerated="true"`, and `windowSoftInputMode="stateUnchanged|adjustResize"`.

- [x] **Step 1:** The failing check is Task 1's red run. This project has no native test harness, so the scripts are
  the native tests (spec, "Checks").
- [x] **Step 2:** Write `UplanEngineSetup`. MainActivity uses it (`liveChannel = UplanEngineSetup.configure(this,
  flutterEngine)`). MainActivity's `add_task` handling stays as the fallback for widget buttons drawn before the
  update, and its comments say so.
- [x] **Step 3:** Write `QuickAddActivity` and its manifest entry.
- [x] **Step 4:** Point the three "+" `HomeWidgetLaunchIntent.getActivity` calls at `QuickAddActivity::class.java`.
- [x] **Step 5:** Update the comments in Dart.
- [x] **Step 6:** `flutter analyze` clean, `flutter test` all green, and `flutter build apk --profile` until "Built
  build" (that compiles the Kotlin). Commit `feat(widget): the quick-add sheet opens in a window of its own`.

### Task 4: The checks on the new build (emulator)

- [x] **Step 1:** `adb install -r` the new APK on the same AVD, then start Uplan once normally.
- [x] **Step 2:** `own_window_check.sh` (default `TARGET`, `adb root`) must PASS cases 1–5.
- [x] **Step 3:** `plus_video.sh` in the warm, again, cold and dead modes must show no app frame before the sheet
  (contact sheets plus `frame_times.py`).
- [x] **Step 4:** `kb_check.sh` and `fresh_plus.sh` must show the keyboard up in every case.
- [x] **Step 5 (Review Focus 3):** Uplan open on a list (`--es route /lists/<id>`, the id read from the demo
  database), then Home and "+". Type `Milk`, pick that list's chip and send. The launcher intent must then show the
  list with "Milk".
- [x] **Step 6 (Review Focus 4):** A "+" sent the old way (`TARGET=.MainActivity`) must still open the sheet. Close
  it afterwards.
- [x] **Step 7 (Review Focus 5):** Over steps 2–6, `adb logcat -d | grep -c MissingPluginException` must give `0`.
- [x] **Step 8 (not needed: case 4 passed) (only if case 4 failed because the sheet's task was parked instead of closed):**
  - Add a failing widget test, `'Back closes the sheet'`, to `test/features/tasks/quick_add_sheet_test.dart`: a
    Back press sends `SystemNavigator.pop`.
  - Wrap the sheet in `PopScope(canPop: false, onPopInvokedWithResult: …)` that calls `_dismiss()`.
  - Run the test, the suite and case 4 again.

### Task 5: Onto master and his phone

- [x] **Step 1:** Fetch, then merge `tester/speed` into `master` in `D:\projects\trackerapp`. Run the suite there.
  Push (the secret check prints counts only).
- [x] **Step 2:** Build the profile APK in `D:\projects\trackerapp` and wait for "Built build". Check the certificate
  SHA-256 and `application-debuggable`. **Only from a clean tree:** if `git status` shows another chat's
  uncommitted work (on 2026-11-03 the Uplan chat's workout-log change, a database migration), don't build. Ask
  that chat first, because a build would carry its half-done migration onto his phone.
- [x] **Step 3:** When he plugs in:
  - copy his data off into `D:\backups\uplan\<date>-own-window\`, with the counts and the integrity check;
  - `adb install -r`;
  - start Uplan with its launcher intent (it re-books his reminders and redraws the widgets);
  - his booked reminders must be the same before and after.
- [x] **Step 4:** Real taps on his widget's "+", each after checking the window in front:
  - `QuickAddActivity` sits in a task of its own and the keyboard comes up;
  - after closing with a tap, Uplan's icon shows his app where he left it;
  - Back, Back closes the sheet;
  - read the time from the tap to "Displayed" in logcat.
- [ ] **Step 5:** He tries it himself, following the Manual Test Steps.

### Task 6: Handover and save

- [ ] **Step 1:** Update:
  - `docs/_Current_Task.md`;
  - `docs/_Task_History.md` (one line);
  - `docs/_Master_Plan.md`;
  - `docs/_Week_Log.md`;
  - CLAUDE.md START HERE;
  - the spec's Status line;
  - `docs/_Undo_Table.md` (the backup folder);
  - the Project Tracker's row.

  Then commit, run the secret check and push.
- [ ] **Step 2:** The retro, once he approves.
