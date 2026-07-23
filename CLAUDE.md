# Habit & Life Tracker App

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

### MVP — build first
1. **Habits:** create, mark complete daily, view streaks
2. **Tasks:** create, complete, due dates, simple priorities (low/med/high)
3. **Today view:** today's habits + due tasks in one screen

### Phase 1.5
4. **Gym tracking:** exercises, sets / reps / weight, workout history, progress charts
5. **Medications:** schedule, reminders, intake log
6. **Planner:** day / week / month views with tasks + habits surfaced

### Phase 2
7. Cloud sync (Supabase)
8. Multi-device, account auth

### Phase 3 (stretch)
9. Stylus note-taking extension with PDF annotation

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
