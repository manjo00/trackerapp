# Uplan (Habit & Life Tracker App)

## START HERE: state as of 2026-10-31 (after the Windows reinstall)
Every AI working here reads this block first, then the current task (pulled in below) and the last 5 lines of
`docs/_Task_History.md` (shown at start-up). Update them after every task.

- **What this is:** Uplan, Ahmed's own Android app (Flutter) for habits, tasks, notes, workouts, work shifts and planning, which he uses daily on his Samsung Z Flip 6. Package `com.lifetracker.life_tracker`. Code in `manjo00/trackerapp`; updates ship through `manjo00/uplan-releases`.
- **Where it stands:** the code is v1.18.0+27 (last work 2026-09-30: Play-safe alarms, G4). The last public release is **v1.15.1 (2026-08-20)**: v1.16.0, v1.17.0 and v1.18.0 are built and committed but **not released**. The build tools are back since 2026-10-31, in `D:\dev`: the code checker is clean, all 303 tests pass, and debug and release builds work on this PC.
- **What's next:** `docs/_Master_Plan.md` (← we are here) and the current task below.
- **Traps:**
  - **The signing key changed on 2026-10-31.** Builds are debug-signed, and the laptop's debug key was lost with its C: drive (no copy on D:, OneDrive or the Recycle Bin). So a build from this PC won't install over the Uplan on the phone. Before the next release, decide with Ahmed: back up in the app (Settings > Export data), uninstall, install, restore, and make a real signing key that is backed up off C:. The new debug key is `C:\Users\kille\.android\debug.keystore`; nothing released is signed with it yet.
  - **Build tools live in `D:\dev`** (2026-10-31): Flutter 3.44.9 `D:\dev\flutter`, Java 21 `D:\dev\jdk-21`, the Android SDK with adb `D:\dev\android-sdk`, Dart packages `D:\dev\pub-cache`. They're on the user PATH, but a chat sees that only after the Claude app restarts; until then use the full paths in the device skill. After a Windows reinstall, `D:\dev\set-user-env.cmd` puts PATH back.
  - **Stay on Flutter 3.44** until a planned upgrade: on 3.47 the app's code generators (analyzer 7.6.0) crash. 3.47.9 waits in `D:\dev\flutter-3.47.9`.
  - **After a fresh clone, generate the code files first:** `dart run build_runner build --delete-conflicting-outputs` (the `*.g.dart` and `*.freezed.dart` files are git-ignored).
  - Google's Android CLI (`android.exe`, which now stands behind `sdkmanager`) sends usage counts unless you add `--no-metrics`; always add it.
  - **Smart App Control blocks release builds** (`flutter build apk --release` fails on `gen_snapshot.exe`) whenever it is on; debug builds still work. It is in evaluation mode and may turn itself on. Never change it (STATUS, 2026-09-29). A release build worked on this PC on 2026-10-31, in evaluation mode.
  - The old plans' check boxes were never ticked: `docs/_Master_Plan.md` is the record of what is done.
  - Device, screenshot and release steps: `.claude/skills/uplan-device-release/SKILL.md`.
- **Branches:** `master` only (the cloud branch `claude/costa-screen-recorder-issue-vh6yhx` was merged as PR #1). Work and push from `D:\projects\trackerapp`.
- **Handover files:** `docs/_Current_Task.md` · `docs/_Task_History.md` (append only) · `docs/_Master_Plan.md` · `docs/_Decisions_Log.md` · the code map `graphify-out/GRAPH_REPORT.md` · the detailed log and hard-won gotchas in `docs/superpowers/STATUS-2026-07-28.md` (kept up to date until 2026-09-30 despite its name) · `AGENTS.md` for other AI apps.
- **Code map:** `graphify-out/GRAPH_REPORT.md` sums up how the code fits together: read it for the big picture before opening many files. On the PC it refreshes itself in the background after each commit that changes code and after each pull (graphify's git hooks, on since 2026-10-30), and the refreshed file goes in with the next commit. A cloud chat can leave it alone: the PC catches up when it pulls.

### The current task (loaded automatically from docs/_Current_Task.md)
@docs/_Current_Task.md

## Project Goal
A personal habit tracker, task manager, and life planner — combining Notion-like flexibility with focused, fast UX for daily use. Tracks habits, tasks, gym progress, medications, and work schedules. Long-term vision includes a Notability/GoodNotes-style stylus note-taking extension.

## Target Platforms
- **Phase 1:** Android (primary)
- **Phase 2:** iOS (same codebase)
- **Phase 3 (stretch):** Stylus note-taking module, likely with native platform code

## Tech Stack

### Core
- **Framework:** Flutter (latest stable)
- **Language:** Dart (null safety, strict)
- **Minimum SDK:** Android 8.0 (API 26), iOS 13+

### Libraries
- **State management:** Riverpod (with riverpod_generator + freezed)
- **Routing:** go_router
- **Local database:** Drift (SQL-based, type-safe)
- **Preferences:** shared_preferences
- **Background tasks:** workmanager
- **Local notifications:** flutter_local_notifications
- **Date/time formatting:** intl

### Future Phases
- **Cloud sync:** Supabase (Postgres + Auth + Storage)
- **Stylus/ink:** Native Android Stylus API + iOS PencilKit via Flutter platform channels

## Folder Structure (feature-first)
```
lib/
  core/              # shared utilities, theme, constants, router
  features/
    habits/
      data/          # models, drift tables, repositories
      domain/        # business logic, use cases
      presentation/  # widgets, screens, providers
    tasks/
    gym/
    meds/
    planner/
  main.dart
```

## Code Conventions
- One widget per file
- Use `freezed` for data classes and unions
- Use `const` constructors wherever possible
- Async code uses `async/await`, not raw Futures
- No `!` (null-bang) operator unless truly unavoidable — explain why if used
- Prefer composition over inheritance
- Keep widgets small; extract subwidgets liberally

## Features Roadmap
Moved on 2026-10-27 to `docs/_Master_Plan.md`, with what is done ticked (✅ done · ⬜ to do · ⏸ parked).

## Working Style — Important

I am a **beginner** to Flutter and mobile development. When helping me:

1. **Explain before coding.** When introducing a new concept (Riverpod provider, Drift DAO, go_router shell route, etc.), give a 2–3 sentence explanation of what it does and why we're using it here.
2. **Plan, then build.** For non-trivial changes, propose the approach first (use Plan Mode). Don't refactor things I didn't ask about.
3. **One feature at a time.** Don't scaffold the whole app in one shot. Build incrementally so I can read every file.
4. **Teach me to test.** Write a basic test alongside any non-trivial logic. Explain what it covers.
5. **Flag tradeoffs.** When choosing between two reasonable options, state the alternatives and why you picked one.
6. **Announce new dependencies.** If you're adding a package to pubspec.yaml, mention it and what it does before adding.
7. **Idiomatic Dart/Flutter only.** No JavaScript/React patterns shoehorned in.
8. **No silent changes.** If you touch a file outside the current task, tell me what and why.

## Git Workflow
- Initialize on day one; commit after every working feature
- Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- `main` branch stays green; feature work in branches

## Open Questions / To Revisit
- **Note→task links — deleting the task directly.** Note lines starting with an
  `@time` token auto-create a linked task (feature added 2026-07). The note is
  currently the **source of truth**: if you delete the auto-created task from the
  Tasks screen while the `@…` line still exists, the task **respawns** the next
  time that note line is saved. This was chosen for simplicity but isn't
  necessarily the cleanest behaviour — revisit whether deleting the task should
  instead strip the token from the note (or "tombstone" the line so it doesn't
  respawn).
  **Resolved 2026-07-22** (commit 320a871, shipped in v1.9.0): deleting the task now deletes the note line and
  archiving it strips the token, so nothing respawns (STATUS, "DONE & SHIPPED").

## Out of Scope (for now)
- Web build, desktop builds
- Sharing / social features
- AI-assisted suggestions
- Custom theming beyond light / dark Material 3
- Wearable integrations

## Definition of Done (per feature)
- Compiles with zero warnings
- Has at least one widget test or unit test for core logic
- Manually verified on Android emulator
- Committed with a descriptive message

<!-- working-with-ahmed:start (from D:\projects\claude-setup\templates\working-with-ahmed.md: change it there first, then in every project) -->
## Working with Ahmed (every chat and AI app)
On Ahmed's PC these rules load by themselves from `C:\Users\kille\.claude\CLAUDE.md`. In a tablet (cloud) chat or
another AI app, read `CLAUDE.md` in his private GitHub repo `manjo00/claude-setup` first if you can reach it. Either
way, follow at least this:
- **Who he is:** not a programmer; he directs, you build and explain. Answer in plain English (he may write in
  Arabic), define any new term the first time, and describe bugs as behaviour, never as error dumps.
- **Questions:** one at a time. Real choices as numbered options with short trade-offs, the recommended one first and
  marked "(Recommended)". Exact click paths for anything he does by hand.
- **Challenge first:** restate the task in a sentence or two, push back on anything unclear or unsafe, then do what he
  decides.
- **Demo first:** a quick working version before any big process. Say the size and a time range before starting; past
  twice the estimate, stop and ask him.
- **Honest:** never say something works unless you checked it; say what the tests proved and what only his eyes can
  confirm. Anything that goes through Windows or another program gets one real try first.
- **Save as you go:** this repo's handover files (START HERE, the current task, the history) are the memory. Update
  them and push as one quick save per round; a tablet chat gets its work onto `main` before it ends.
- **Ask first** before installing anything, changing a setting, creating a repo, or publishing or sending anything.
  Never delete permanently, never force-push, and keep secrets out of git.
<!-- working-with-ahmed:end -->
