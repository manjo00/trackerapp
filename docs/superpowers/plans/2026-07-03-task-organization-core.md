# Task Organization Core — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lists (placeholder noun) containing sections, cross-cutting labels, and a Home dashboard replacing Inbox — per spec `docs/superpowers/specs/2026-07-03-task-organization-core-design.md`.

**Architecture:** Schema v11 adds `task_lists`/`list_sections`/`labels`/`task_labels` + nullable `tasks.listId`/`sectionId` (Approach A: no Inbox row — `listId NULL` = "Captured"). Nav: AppTab `inbox`→`home`, `tasks`→`lists`; defaults Home·Lists·Planner; Today moves to drawer. Home v1 = fixed blocks (Urgent/Due today/Captured/This week).

**Tech Stack:** Flutter 3.44 · Drift 2.28 (`m.createTable`/`m.addColumn` only) · Riverpod 2.6 (manual providers fine — codebase mixes) · freezed (TaskModel touch) · go_router StatefulShellRoute.

## Global Constraints

- The container noun is read from `kListNoun`/`kListNounPlural` (`lib/core/constants/app_strings.dart`) in ALL user-visible copy. Code identifiers use `list`/`TaskList`.
- Drift migrations: `m.createTable`/`m.addColumn` only, never raw SQL. `schemaVersion` 10→11.
- After any table/model change: `dart run build_runner build --delete-conflicting-outputs`.
- No `!` unless unavoidable. `.toARGB32()` not `.value`. One widget per file. `flutter analyze` clean before every commit. Conventional commits.
- Test DB pattern: `AppDatabase.forTesting(NativeDatabase.memory())` (see `test/features/shifts/shifts_repository_test.dart`).
- After every await in notifiers, re-read state before writing back.

---

### Task 1 — Naming constant, tables, schema v11 + migration tests

**Files:**
- Create: `lib/core/constants/app_strings.dart`
- Create: `lib/features/tasks/data/tables/task_lists_table.dart`
- Create: `lib/features/tasks/data/tables/labels_table.dart`
- Modify: `lib/features/tasks/data/tables/tasks_table.dart` (add 2 columns)
- Modify: `lib/core/database/app_database.dart` (tables list, schemaVersion 11, onUpgrade block)
- Test: `test/features/tasks/organization_schema_test.dart`

**Interfaces produced:** Drift row classes `TaskList`, `ListSection`, `Label`, `TaskLabel`; companions of same names + `Companion` suffix; `tasks.listId`/`tasks.sectionId` (`int?`).

- [ ] **Step 1: app_strings.dart**

```dart
/// User-visible wording that may change. The task-container noun is a
/// placeholder the user hasn't settled on — rename it HERE only.
const String kListNoun = 'List';
const String kListNounPlural = 'Lists';
```

- [ ] **Step 2: task_lists_table.dart** (lists + sections together — they change together)

```dart
import 'package:drift/drift.dart';

/// A user-created container of tasks ("List" is a placeholder noun —
/// see kListNoun). No row exists for Captured: tasks.listId NULL = captured.
class TaskLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF8AB4F8))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Named group inside a list (e.g. "Planning" / "Buying" / "Doing").
class ListSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(TaskLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 3: labels_table.dart**

```dart
import 'package:drift/drift.dart';
import 'tasks_table.dart';

/// Cross-cutting tag. Many-to-many with tasks via [TaskLabels].
class Labels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFFA6ABEC))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}

/// Junction: which labels a task carries. CASCADE both ways.
class TaskLabels extends Table {
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get labelId =>
      integer().references(Labels, #id, onDelete: KeyAction.cascade)();
  @override
  Set<Column> get primaryKey => {taskId, labelId};
}
```

- [ ] **Step 4: tasks_table.dart — append inside `class Tasks`** (import both new table files)

```dart
  /// Owning list; NULL = "Captured" (no Inbox row exists by design).
  IntColumn get listId => integer()
      .nullable()
      .references(TaskLists, #id, onDelete: KeyAction.setNull)();

  /// Section within [listId]'s list; NULL = list body. Repository guards
  /// that a section always belongs to the task's own list.
  IntColumn get sectionId => integer()
      .nullable()
      .references(ListSections, #id, onDelete: KeyAction.setNull)();
```

- [ ] **Step 5: app_database.dart** — add the 4 tables to `@DriftDatabase(tables:[…])` + imports; `schemaVersion => 11`; in `onUpgrade` append:

```dart
          if (from < 11) {
            await m.createTable(taskLists);
            await m.createTable(listSections);
            await m.createTable(labels);
            await m.createTable(taskLabels);
            await m.addColumn(tasks, tasks.listId);
            await m.addColumn(tasks, tasks.sectionId);
          }
```

- [ ] **Step 6: build_runner** — `dart run build_runner build --delete-conflicting-outputs` → expect `Succeeded`.

- [ ] **Step 7: failing-then-passing schema tests** — `organization_schema_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int> addList(String name) => db.into(db.taskLists).insert(
      TaskListsCompanion.insert(name: name, createdAt: Value(DateTime.now())));
  Future<int> addTask(String title, {int? listId, int? sectionId}) =>
      db.into(db.tasks).insert(TasksCompanion.insert(
          title: title,
          createdAt: DateTime.now(),
          listId: Value(listId),
          sectionId: Value(sectionId)));

  test('delete list -> tasks fall back to Captured, sections die', () async {
    final int l = await addList('Work');
    final int s = await db.into(db.listSections).insert(
        ListSectionsCompanion.insert(listId: l, name: 'Sprint'));
    final int t = await addTask('report', listId: l, sectionId: s);
    await (db.delete(db.taskLists)..where((r) => r.id.equals(l))).go();
    final task = await (db.select(db.tasks)..where((r) => r.id.equals(t))).getSingle();
    expect(task.listId, null);
    expect(task.sectionId, null);
    expect(await db.select(db.listSections).get(), isEmpty);
  });

  test('delete section -> task stays in list', () async {
    final int l = await addList('Home');
    final int s = await db.into(db.listSections).insert(
        ListSectionsCompanion.insert(listId: l, name: 'A'));
    final int t = await addTask('x', listId: l, sectionId: s);
    await (db.delete(db.listSections)..where((r) => r.id.equals(s))).go();
    final task = await (db.select(db.tasks)..where((r) => r.id.equals(t))).getSingle();
    expect(task.listId, l);
    expect(task.sectionId, null);
  });

  test('task_labels cascades from both sides', () async {
    final int t = await addTask('x');
    final int lb = await db.into(db.labels).insert(LabelsCompanion.insert(name: 'gym'));
    await db.into(db.taskLabels).insert(TaskLabelsCompanion.insert(taskId: t, labelId: lb));
    await (db.delete(db.labels)..where((r) => r.id.equals(lb))).go();
    expect(await db.select(db.taskLabels).get(), isEmpty);
  });
}
```

Run `flutter test test/features/tasks/organization_schema_test.dart` → PASS (FKs are ON via beforeOpen pragma).

- [ ] **Step 8: Commit** — `feat(tasks): schema v11 — lists, sections, labels (+captured semantics)`

---

### Task 2 — DAO + repository layer

**Files:**
- Create: `lib/features/tasks/data/dao/lists_dao.dart` (+ part `lists_dao.g.dart`)
- Modify: `lib/features/tasks/data/dao/tasks_dao.dart`
- Create: `lib/features/tasks/data/repositories/lists_repository.dart`
- Modify: `lib/features/tasks/data/models/task_model.dart` + `lib/features/tasks/data/repositories/tasks_repository.dart`
- Test: `test/features/tasks/lists_repository_test.dart`

**Interfaces produced:**
- `ListsDao`: `watchLists() → Stream<List<TaskList>>` (orderIndex,name), `insertList(TaskListsCompanion) → Future<int>`, `updateList`, `deleteList(int)`, `watchSections(int listId)`, `insertSection`, `updateSection`, `deleteSection(int)`, `watchLabels()`, `insertLabel`, `deleteLabel(int)`, `watchLabelIdsForTask(int taskId) → Stream<List<int>>`, `setTaskLabels(int taskId, Set<int> labelIds)` (delete-then-insert in transaction), `watchTaskCountsByList() → Stream<Map<int,int>>` (incomplete only, group by listId).
- `TasksDao` additions: `watchCapturedTasks()` (`listId IS NULL & !isCompleted`, priority desc/created asc — replaces `watchInboxTasks`, DELETE the old method), `watchTasksForList(int listId)` (incomplete first, sectionId asc nulls-first, priority desc), `watchTasksInRange(String from, String to)` (incomplete, dueDate BETWEEN inclusive).
- `ListsRepository(ListsDao dao, TasksDao tasksDao)`: thin passthroughs plus `Future<void> moveTaskToList(int taskId, int? listId, {int? sectionId})` — writes `TasksCompanion(id: Value(taskId), listId: Value(listId), sectionId: Value(sectionId))`; **guard:** when `listId` changes, `sectionId` is forced null unless the given section's own `listId` matches (single `getSingleOrNull` check).
- `TaskModel`: add `int? listId`, `int? sectionId` fields; `_fromRow` maps them; `TasksRepository.addTask` gains `int? listId, int? sectionId` named params; `updateTask` writes both.

- [ ] Step 1: write `lists_repository_test.dart` first — cases: create list + section + assign task; `moveTaskToList` to another list clears stale section; `setTaskLabels` replaces set atomically; `watchCapturedTasks` includes dated unassigned task, excludes tasks with list; `watchTaskCountsByList` counts only incomplete. (Same setup/teardown pattern as Task 1 tests.)
- [ ] Step 2: run → FAIL (missing symbols).
- [ ] Step 3: implement DAO/repo/model changes exactly per Interfaces above; build_runner; fix `inboxTasksProvider` compile break by renaming provider in `tasks_providers.dart` to `capturedTasksProvider` (stream from `watchCapturedTasks` mapped `_fromRow` via repository method `watchCapturedTasks()`).
- [ ] Step 4: `flutter test test/features/tasks/` → all PASS; `flutter analyze` clean (InboxScreen still references old provider — update it temporarily to `capturedTasksProvider`; screen is deleted in Task 3).
- [ ] Step 5: Commit — `feat(tasks): lists/labels DAO + repository, captured queries, TaskModel listId`

---

### Task 3 — Navigation restructure (AppTab, settings v3, router, drawer)

**Files:**
- Modify: `lib/core/settings/app_settings.dart` — enum values `inbox`→`home` (label `'Home'`, icons `Icons.home_outlined`/`Icons.home_rounded`), `tasks`→`lists` (label `kListNounPlural`, icons `Icons.folder_copy_outlined`/`Icons.folder_copy_rounded`); defaults `{home, lists, planner}`.
- Modify: `lib/core/settings/settings_provider.dart` — `_currentSettingsVersion = 3`; migration inside `_load()` BEFORE reading tabs:

```dart
    if (savedVersion < 3) {
      // v3: inbox tab became Home; tasks tab became Lists.
      final List<String>? raw = _prefs.getStringList(_kTabs);
      if (raw != null) {
        final List<String> mapped = raw
            .map((s) => switch (s) { 'inbox' => 'home', 'tasks' => 'lists', _ => s })
            .toList();
        // Old 3-tab default maps to {today,home,planner}: upgrade to the
        // new default so Lists is discoverable.
        final Set<String> set = mapped.toSet();
        if (set.length == 3 && set.containsAll({'today', 'home', 'planner'})) {
          _prefs.setStringList(_kTabs, ['home', 'lists', 'planner']);
        } else {
          _prefs.setStringList(_kTabs, mapped);
        }
      }
      _prefs.setInt(_kSettingsVersion, _currentSettingsVersion);
    }
```

- Modify: `lib/core/router/app_router.dart` — branch 1 route `/inbox`→`/home` (`HomeScreen`); branch 3 `/tasks`→`/lists` (`ListsOverviewScreen`); add full-screen `GoRoute(path: '/lists/:id', builder: (c,s) => ListDetailScreen(listId: int.parse(s.pathParameters['id']!)))` beside `/trackers/:id`; `/tasks/add` + `/tasks/edit` stay but `AddTaskScreen` gains `initialListId`/`initialSectionId` via a small `AddTaskArgs` extra (Task 5).
- Modify: `lib/core/router/shell_scaffold.dart` — `_labelForBranch` switch cases for home/lists; title builder.
- Modify: `lib/features/settings/presentation/widgets/app_drawer.dart` — "Tasks/All your tasks" tile → `kListNounPlural` → `context.go('/lists')`; add "Today" tile (drawer home for the demoted tab) → `/today`.
- Delete: `lib/features/inbox/` (screen replaced by Home; create placeholder `HomeScreen` in this task so the app compiles: `lib/features/home/presentation/screens/home_screen.dart` with `Scaffold(appBar: AppBar(title: Text('Home')), body: Center(child: Text('Home blocks land in the next commit')))`).
- Test: `test/core/settings_migration_v3_test.dart` — seed `SharedPreferences.setMockInitialValues` with `{'settings_version': 2, 'visible_tabs': ['today','inbox','planner']}` → after `SettingsNotifier` load, expect visibleTabs `{home, lists, planner}`; second case: custom set `['today','tasks','workout']` → maps to `['today','lists','workout']`.

- [ ] Steps: failing settings test → migration code → PASS → router/enum/drawer/placeholder edits → `flutter analyze` clean → deploy to device, tap through all tabs → Commit `feat(nav): Home & Lists tabs replace Inbox & Tasks (settings v3 migration)`.

---

### Task 4 — Providers for lists/labels/home blocks

**Files:**
- Create: `lib/features/tasks/presentation/providers/lists_providers.dart`
- Modify: `lib/features/tasks/presentation/providers/tasks_providers.dart`

**Interfaces produced (manual Riverpod, matching settings_provider style):**

```dart
final listsDaoProvider = Provider<ListsDao>((ref) => ListsDao(ref.watch(appDatabaseProvider)));
final listsRepositoryProvider = Provider<ListsRepository>((ref) =>
    ListsRepository(ref.watch(listsDaoProvider), TasksDao(ref.watch(appDatabaseProvider))));
final taskListsProvider = StreamProvider<List<TaskList>>((ref) => ref.watch(listsRepositoryProvider).watchLists());
final listTaskCountsProvider = StreamProvider<Map<int, int>>((ref) => ref.watch(listsRepositoryProvider).watchTaskCountsByList());
final sectionsForListProvider = StreamProvider.family<List<ListSection>, int>((ref, listId) => ref.watch(listsRepositoryProvider).watchSections(listId));
final tasksForListProvider = StreamProvider.family<List<TaskModel>, int>((ref, listId) => ref.watch(tasksRepositoryProvider).watchTasksForList(listId));
final labelsProvider = StreamProvider<List<Label>>((ref) => ref.watch(listsRepositoryProvider).watchLabels());
final labelIdsForTaskProvider = StreamProvider.family<List<int>, int>((ref, taskId) => ref.watch(listsRepositoryProvider).watchLabelIdsForTask(taskId));
// Home blocks:
final urgentTasksProvider = ...   // overdue ∪ (high-priority due today/tomorrow), de-duped by id
final thisWeekTasksProvider = ... // watchTasksInRange(today, today+6) grouped later in UI
```

`urgentTasksProvider`: combine `overdueTasksProvider` stream + repository `watchTasksInRange(today, tomorrow)` filtered `priority == TaskPriority.high`, merge, de-dupe by id, sort by dueDate. `capturedTasksProvider` already exists (Task 2); Home's Captured block additionally filters out overdue/due-today ids in the HomeScreen build (no extra provider).

- [ ] Steps: implement → analyze clean → commit `feat(tasks): providers for lists, labels, home blocks`.

---

### Task 5 — Screens: Home, Lists overview, List detail

**Files:**
- Rewrite: `lib/features/home/presentation/screens/home_screen.dart`
- Create: `lib/features/tasks/presentation/screens/lists_overview_screen.dart`
- Create: `lib/features/tasks/presentation/screens/list_detail_screen.dart`
- Create: `lib/features/tasks/presentation/widgets/list_form_dialog.dart` (name + 8-color preset row → returns `(String, int)`; reused for create/rename)
- Modify: `lib/features/tasks/presentation/widgets/task_tile.dart` — optional `showListName: bool` param; when true and task.listId != null, append list name (from `taskListsProvider`) in muted subtitle.

**HomeScreen spec (fixed v1):** `ListView` of block widgets, each `_HomeBlock(title, icon, color, tasks)` rendering header + `TaskTile`s; blocks: Urgent (`urgentTasksProvider`, red header), Due today (`tasksDueTodayProvider` minus urgent ids), Captured (`capturedTasksProvider` minus ids already shown), This week (`thisWeekTasksProvider` → 7 `_DayRow`s: weekday label + count + first 2 titles, tap → `/planner`). Empty blocks render nothing; all empty → centered "All clear 🎉". FAB "+" → `/tasks/add`.

**ListsOverviewScreen:** AppBar `kListNounPlural`. Body: `ListTile("All tasks")` → pushes existing `TaskListScreen` (kept as plain screen, no route change) · then lists from `taskListsProvider` (color dot, name, count from `listTaskCountsProvider`) → `context.push('/lists/$id')` · FAB "New $kListNoun" → `list_form_dialog` → `listsRepository.createList(name, color)`.

**ListDetailScreen(listId):** watches `tasksForListProvider(listId)` + `sectionsForListProvider(listId)`. Renders: unsectioned tasks, then per-section header (name + ⋮ menu: rename via dialog / delete via confirm "Tasks stay in the $kListNoun") + its tasks. AppBar ⋮ menu: rename/recolor (list_form_dialog), delete (confirm "Tasks return to Captured" → `deleteList` → pop). "＋ Add section" text button → name dialog. FAB → `/tasks/add` with `AddTaskArgs(listId: listId)`.

- [ ] Steps: build the three screens + dialog → analyze → deploy to Flip 6, manual pass (create list, sections, tasks land correctly, delete behaviors match spec, Home blocks populate) → commit `feat(tasks): Home dashboard, Lists overview, List detail screens`.

---

### Task 6 — Task editor + quick-add integration

**Files:**
- Modify: `lib/features/tasks/presentation/screens/add_task_screen.dart`
- Modify: `lib/features/tasks/presentation/screens/quick_add_task_screen.dart`
- Modify: `lib/core/router/app_router.dart` (`/tasks/add` extra becomes `AddTaskArgs{String? initialDate; int? listId; int? sectionId}` — plain class in `add_task_screen.dart`; keep back-compat: `state.extra is String` → date-only)
- Create: `lib/features/tasks/presentation/widgets/label_picker_row.dart` (chips from `labelsProvider`, multi-select into `Set<int>`, trailing "＋" chip → name+color dialog → `createLabel`)

**AddTaskScreen changes:** new state `int? _listId; int? _sectionId; Set<int> _labelIds = {};` (edit mode: init from task + `labelIdsForTaskProvider` one-shot read). UI rows after priority: List picker (`DropdownButtonFormField<int?>` — "Captured" null entry + lists) → on change, `_sectionId = null`; Section dropdown only when `_listId != null` (from `sectionsForListProvider`). `label_picker_row`. `_save()`: pass `listId/sectionId` into `addTask`/`updateTask`, then `await listsRepository.setTaskLabels(newIdOrTaskId, _labelIds)`.

**QuickAddTaskScreen:** single horizontal chip row above the text field: `[Captured] [list1] [list2] …` (ChoiceChips, default Captured) → chosen id passed to `addTask(listId: …)`. No labels/sections in quick-add (YAGNI, per spec).

- [ ] Steps: implement → analyze → device pass (assign at create, edit list/section/labels, quick-add files to list) → commit `feat(tasks): list/section/label pickers in editor + quick-add`.

---

### Task 7 — Ripple effects + ship

**Files:**
- Modify: `lib/core/notifications/live_dashboard_service.dart` — Captured card source: replace `pending.where((t) => t.dueDate == null)` inbox block with `pending.where((t) => t.listId == null && !(overdue-or-due-today))`; card `type` stays `'inbox'` (background complete action already works on tasks table — rename display sub to 'Captured').
- Verify: `lib/core/backup/backup_service.dart` restore order — its table loop uses `_db.allTables`; confirm FK-safe insert order lists→sections→labels→tasks→task_labels; if it inserts in `allTables` order, adjust its ordering list.
- Modify: `CLAUDE.md` (schema v11, nav structure, feature table row) + plan-file PENDING (slice 2 = Home block engine/saved filters, then deadlines, time blocks, auto-backups).
- Version: pubspec `1.1.1+3 → 1.2.0+4`.

- [ ] Steps: edits → `flutter analyze` + `flutter test` full suite → deploy → full 🧪 manual pass on the Flip 6 (existing data intact: old tasks all appear Captured; live-notif Captured card completes correctly; settings migration moved tabs) → commit `feat(tasks): captured semantics in live notification + docs` → push → (with user) publish release v1.2.0 to uplan-releases.

---

## Self-review

- **Spec coverage:** schema ✓(T1) deletion semantics ✓(T1 tests) DAO/repo+guard ✓(T2) nav+settings v3+drawer+Today demotion ✓(T3) providers ✓(T4) Home v1 blocks ✓(T5) lists/detail/sections UI ✓(T5) editor+quick-add+labels ✓(T6) live-notif/backup/docs ✓(T7). Naming constant ✓(T1, consumed T3/T5/T6).
- **Placeholders:** none — every task lists exact files, signatures, and behavior; UI tasks carry full widget specs with state fields and provider wiring.
- **Type consistency:** `TaskList/ListSection/Label/TaskLabel` row names used consistently; `capturedTasksProvider` named once in T2 and reused; `AddTaskArgs` defined T6 and referenced T3 note.
