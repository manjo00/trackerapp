# Graph Report - trackerapp  (2026-11-01)

## Corpus Check
- 285 files · ~145,917 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: (none) 5, .pro 1)

## Summary
- 4164 nodes · 6191 edges · 253 communities (188 shown, 65 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d3b3165c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- workout_providers.dart
- note_editor_screen.dart
- notification_service.dart
- notes_dao.dart
- add_task_screen.dart
- archive_service.dart
- lists_dao.dart
- home_screen.dart
- when_parser.dart
- note_arrange_view.dart
- package:flutter_test/flutter_test.dart
- archived_screen.dart
- add_tracker_screen.dart
- day_detail_view.dart
- _
- app_database.dart
- archiveServiceProvider
- notes_providers.dart
- shell_scaffold.dart
- tasks_providers.dart
- program_repository.dart
- workout_repository.dart
- package:life_tracker/core/database/app_database.dart
- task_detail_sheet_test.dart
- set_row.dart
- app_router.dart
- today_screen.dart
- settings_provider.dart
- drag_drop.dart
- StatelessWidget
- trackers_providers.dart
- program_session_editor_screen.dart
- ConsumerWidget
- recently_deleted_test.dart
- _
- pinned_note_block.dart
- day_column.dart
- app.dart
- shift_month_calendar.dart
- home_blocks_providers.dart
- package:flutter/material.dart
- coach_overlay.dart
- quick_add_task_screen.dart
- trackers_dao.dart
- program_dao.dart
- program_detail_screen.dart
- Color
- exercise_picker_screen.dart
- workout_dao.dart
- notebook_detail_screen.dart
- DateTime?
- app_settings.dart
- coach_controller.dart
- ../../../../core/database/app_database.dart
- archive_providers.dart
- _
- tracker_detail_screen.dart
- shifts_providers.dart
- trackers_repository.dart
- @Riverpod
- add_habit_screen.dart
- coach_tip.dart
- tasks_repository.dart
- list_detail_screen.dart
- settings_screen.dart
- codex_topic.dart
- _
- github_feedback_service.dart
- _
- muscle_targets_editor_screen.dart
- log_entry_screen.dart
- CombinedTasksRemoteViewsFactory
- create_program_screen.dart
- @freezed
- shell_scaffold.dart
- habits_repository.dart
- lists_repository.dart
- taskListsProvider
- task_detail_sheet.dart
- exercise_accordion_card.dart
- day_time_grid.dart
- program_exercises_table.dart
- habits_dao.dart
- .configureFlutterEngine
- MonthRemoteViewsFactory
- text_block_view.dart
- checkbox_block_view.dart
- _
- home_block_config.dart
- tasks_table.dart
- package:drift/drift.dart
- program_template_data.dart
- programs_table.dart
- List
- tracker_template.dart
- photo_block_view.dart
- IntColumn get
- WidgetDates
- UplanAgendaWidgetProvider.kt
- day_grid_layout.dart
- int?
- list_form_dialog.dart
- notebook_form_dialog.dart
- workout_list_screen.dart
- LiveDashboardService.kt
- UplanMonthWidgetProvider.kt
- core/settings/settings_provider.dart
- ../../../coach/presentation/coach_controller.dart
- tracker_logs_table.dart
- notes_repository.dart
- exercise_history_sheet.dart
- week_strip.dart
- image_storage_service.dart
- Table
- lists_repository_test.dart
- ../../../../core/database/app_database.dart
- archive_search_test.dart
- live_notification_settings_screen.dart
- codex_screen.dart
- ConsumerState
- app_drawer.dart
- group_score.dart
- note_blocks_table.dart
- workout_sets_table.dart
- workoutRepositoryProvider
- RestLiveUpdate.kt
- block_config_sheet.dart
- task_priority.dart
- note_task_linker.dart
- package:go_router/go_router.dart
- live_background_callback.dart
- widget_settings_screen.dart
- task_lists_table.dart
- smart_order.dart
- custom_trackers_table.dart
- .build
- week_attendance_strip.dart
- shifts_repository.dart
- weekly_scoreboard_card.dart
- tracker_progress_card.dart
- markdown_feedback_builder.dart
- String get
- _
- time_block_utils.dart
- build
- notes_table.dart
- shifts_dao.dart
- AppDatabase
- work_shift_model.dart
- workout_summary_screen.dart
- Route /workout/active
- _
- habit_list_screen_test.dart
- home_blocks_dao_test.dart
- workout_actions.dart
- State
- return
- archived_item.dart
- notebooks_table.dart
- note_sort.dart
- heading_line_view.dart
- shift_picker_sheet.dart
- program_templates_test.dart
- diagnostics_screen.dart
- MainActivity
- rest_timer_bar.dart
- _NoteEditorScreenState
- smart_order_start_test.dart
- notesDaoProvider
- HabitsDao
- habits_table.dart
- Color
- work_shifts_table.dart
- whats_new_test.dart
- home_block_type.dart
- priority_badge.dart
- home_blocks_dao.dart
- note_outline.dart
- weight_steps.dart
- program_sessions_table.dart
- ../../../../core/settings/settings_provider.dart
- LiveActionReceiver.kt
- startup_tab.dart
- bool get
- tracker_item_model.dart
- coach_due.dart
- note_search_test.dart
- static const int
- shift_date_picker_sheet.dart
- .onGetViewFactory
- _
- archive_search.dart
- coachControllerProvider
- streak_logic_test.dart
- streak_badge.dart
- _ArchivedScreenState
- _
- package:life_tracker/core/database/app_database.dart
- drag_drop_test.dart
- widget_payload.dart
- _DiagnosticsScreenState
- @pragma
- app_strings.dart
- image_filename.dart
- SettingsNotifier
- note_text_style.dart
- _onWidgetMethod
- widget_test.dart
- _AddTaskScreenState
- WorkoutDao

## God Nodes (most connected - your core abstractions)
1. `_` - 62 edges
2. `_` - 32 edges
3. `AppDatabase` - 31 edges
4. `_` - 31 edges
5. `notesDaoProvider` - 30 edges
6. `settingsProvider` - 30 edges
7. `_` - 30 edges
8. `archiveServiceProvider` - 26 edges
9. `_` - 24 edges
10. `taskListsProvider` - 19 edges

## Surprising Connections (you probably didn't know these)
- `_RecordingToggle` --inherits--> `ToggleTask`  [EXTRACTED]
  test/features/tasks/task_detail_sheet_test.dart → lib/features/tasks/presentation/providers/tasks_providers.dart
- `_split` --references--> `notesDaoProvider`  [EXTRACTED]
  lib/features/home/presentation/widgets/pinned_note_block.dart → lib/features/notes/presentation/providers/notes_providers.dart
- `_toggleFold` --references--> `notesDaoProvider`  [EXTRACTED]
  lib/features/home/presentation/widgets/pinned_note_block.dart → lib/features/notes/presentation/providers/notes_providers.dart
- `_createNotebook` --references--> `notesDaoProvider`  [EXTRACTED]
  lib/features/notes/presentation/screens/notes_overview_screen.dart → lib/features/notes/presentation/providers/notes_providers.dart
- `_save` --references--> `notesDaoProvider`  [EXTRACTED]
  lib/features/notes/presentation/widgets/checkbox_block_view.dart → lib/features/notes/presentation/providers/notes_providers.dart

## Import Cycles
- None detected.

## Communities (253 total, 65 thin omitted)

### Community 0 - "workout_providers.dart"
Cohesion: 0.03
Nodes (74): active, ActiveWorkoutState, _adaptScore, addSeconds, addSet, build, cancel, comp (+66 more)

### Community 1 - "note_editor_screen.dart"
Cohesion: 0.05
Nodes (35): _addPhoto, _AddRow, _arrangeAppBar, _arrangePreview, block, createState, _deleted, _deleteNote (+27 more)

### Community 2 - "notification_service.dart"
Cohesion: 0.03
Nodes (52): areNotificationsEnabled, _cancel, cancelAll, cancelDailyReminder, cancelHabitReminder, cancelTaskReminders, cancelTrackerReminder, _canUseExact (+44 more)

### Community 3 - "notes_dao.dart"
Cohesion: 0.03
Nodes (54): addBlock, applyArrangement, archiveNotesInNotebook, createNote, createNotebook, deleteBlock, deletedNotesInNotebook, deleteNote (+46 more)

### Community 4 - "add_task_screen.dart"
Cohesion: 0.04
Nodes (50): active, AddTaskArgs, _applyDetected, build, _buildLeadTimesStr, createState, _DateTimeTile, _detected (+42 more)

### Community 5 - "archive_service.dart"
Cohesion: 0.04
Nodes (45): archiveHabit, archiveList, archiveNote, archiveNotebook, archiveTask, archiveTracker, daysLeftInTrash, destroyHabit (+37 more)

### Community 6 - "lists_dao.dart"
Cohesion: 0.04
Nodes (43): deleteLabel, deleteList, deleteSection, getList, getListForNote, getSection, insertLabel, insertList (+35 more)

### Community 7 - "home_screen.dart"
Cohesion: 0.10
Nodes (13): _BlockHeader, _coachWrap, collapsed, color, _dayRow, days, _headerColor, onToggleCollapse (+5 more)

### Community 8 - "when_parser.dart"
Cohesion: 0.04
Nodes (44): _adjacent, date, _dateAtStart, _dayMonthRe, _dayMonthTightRe, _dayOrdinalRe, end, _findDate (+36 more)

### Community 9 - "note_arrange_view.dart"
Cohesion: 0.05
Nodes (31): _autoDelta, _autoTimer, block, blocks, bottom, build, center, createState (+23 more)

### Community 10 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.07
Nodes (10): main, main, main, main, main, _tip, main, _b (+2 more)

### Community 11 - "archived_screen.dart"
Cohesion: 0.05
Nodes (33): _confirmDestroy, _confirmEmpty, _count, createState, _delete, _destroy, dispose, _Empty (+25 more)

### Community 12 - "add_tracker_screen.dart"
Cohesion: 0.06
Nodes (35): _addItem, AddTrackerScreen, _AddTrackerScreenState, build, _buildCustomiseForm, _buildTemplatePicker, _colorValue, createState (+27 more)

### Community 13 - "day_detail_view.dart"
Cohesion: 0.06
Nodes (28): build, HabitsBlock, DotSummary, habitsDone, habitsForDateProvider, habitsTotal, hasAnyData, tasksCompleted (+20 more)

### Community 14 - "_"
Cohesion: 0.06
Nodes (28): _, _addExercise, build, _buildItems, _buildSummary, _byMuscle, createState, _deleteSet (+20 more)

### Community 15 - "app_database.dart"
Cohesion: 0.05
Nodes (9): migration, _newRotationColor, _oldRotationColor, _openConnection, _retagArmExercises, schemaVersion, _seedExerciseLibrary, _seedMuscleTargets (+1 more)

### Community 16 - "archiveServiceProvider"
Cohesion: 0.10
Nodes (17): _reschedule, archiveServiceProvider, _confirmDelete, _archiveNote, _onAction, _showCardActions, _showNotebookActions, listsDaoProvider (+9 more)

### Community 17 - "notes_providers.dart"
Cohesion: 0.11
Nodes (14): allNotesProvider, db, lastEdit, lastNoteEditByNotebookProvider, names, nbs, notebooks, notes (+6 more)

### Community 18 - "shell_scaffold.dart"
Cohesion: 0.12
Nodes (15): build, child, CoachRegistry, CoachTarget, _CoachTargetState, createState, didUpdateWidget, dispose (+7 more)

### Community 19 - "tasks_providers.dart"
Cohesion: 0.09
Nodes (26): deleteTaskProvider, _fixReminders, add, AddTask, allTasks, build, capturedTasks, dao (+18 more)

### Community 20 - "program_repository.dart"
Cohesion: 0.06
Nodes (29): addExercise, addSession, _copySessionsInto, createFromTemplate, createFromUserTemplate, createProgram, deleteExercise, deleteProgram (+21 more)

### Community 21 - "workout_repository.dart"
Cohesion: 0.06
Nodes (31): addCustomExercise, addSet, createSession, _dao, _dateFmt, deleteSession, deleteSet, _exerciseFromRow (+23 more)

### Community 22 - "package:life_tracker/core/database/app_database.dart"
Cohesion: 0.09
Nodes (19): NotesDao, dao, db, main, makeBlock, now, blocksFor, dao (+11 more)

### Community 23 - "task_detail_sheet_test.dart"
Cohesion: 0.07
Nodes (17): main, task, main, task, main, _task, build, calls (+9 more)

### Community 24 - "set_row.dart"
Cohesion: 0.06
Nodes (33): _apply, build, controller, _copyPrev, createState, didUpdateWidget, dispose, _flush (+25 more)

### Community 26 - "today_screen.dart"
Cohesion: 0.06
Nodes (27): build, _buildHabitsSection, _buildOverdueSection, _buildTasksSection, _buildTrackersSection, _checkedIds, color, count (+19 more)

### Community 27 - "settings_provider.dart"
Cohesion: 0.06
Nodes (32): _currentSettingsVersion, _kDevMode, _kExperimentalTargets, _kHomeBlocks, _kNotebooksSort, _kNotesSort, _kNotifications, _kPlannerDayView (+24 more)

### Community 28 - "drag_drop.dart"
Cohesion: 0.06
Nodes (31): above, aboveContainer, applyDrop, Arrangement, bedSize, ci, containerIdOf, d (+23 more)

### Community 29 - "StatelessWidget"
Cohesion: 0.05
Nodes (37): build, EmptyHabitsPlaceholder, build, EmptyTasksPlaceholder, _DayTimerHeader, _MuscleHeader, _NoExercisesPlaceholder, _SmartOrderNote (+29 more)

### Community 30 - "trackers_providers.dart"
Cohesion: 0.07
Nodes (27): deleteLogProvider, deleteTrackerProvider, add, AddTracker, build, checklistTrackersForToday, dao, addTrackerProvider (+19 more)

### Community 31 - "program_session_editor_screen.dart"
Cohesion: 0.07
Nodes (30): _addExercise, build, color, createState, _deleteExercise, _editExercise, exercise, _ExerciseEditDialog (+22 more)

### Community 32 - "ConsumerWidget"
Cohesion: 0.10
Nodes (24): build, githubFeedbackConfigProvider, settingsProvider, tasksForDateProvider, build, _HabitItem, initState, _onMenu (+16 more)

### Community 33 - "recently_deleted_test.dart"
Cohesion: 0.07
Nodes (24): ArchiveService, NotesRepository, addHabit, addTask, archive, db, habits, ids (+16 more)

### Community 34 - "_"
Cohesion: 0.11
Nodes (18): deleteHabitProvider, _rescheduleReminders, add, AddHabit, build, dao, addHabitProvider, habitsWithStatusProvider (+10 more)

### Community 35 - "pinned_note_block.dart"
Cohesion: 0.09
Nodes (12): _append, createState, _focusRequestId, _indentStep, kPinnedNoteMaxHeight, _line, PinnedNoteBlock, _PinnedNoteBlockState (+4 more)

### Community 36 - "day_column.dart"
Cohesion: 0.07
Nodes (24): build, isEmpty, _key, ShiftBlock, dayDotSummaryProvider, build, color, date (+16 more)

### Community 37 - "app.dart"
Cohesion: 0.09
Nodes (15): createState, didChangeAppLifecycleState, dispose, initState, LifeTrackerApp, _LifeTrackerAppState, _liveChannel, _maybeOfferUpdate (+7 more)

### Community 38 - "shift_month_calendar.dart"
Cohesion: 0.07
Nodes (25): color, _CountTile, createState, dateStr, day, initialMonth, initState, isSelected (+17 more)

### Community 39 - "home_blocks_providers.dart"
Cohesion: 0.08
Nodes (31): allNotesProvider, dao, ensureSeeded, homeBlockRowsProvider, homeBlocksDaoProvider, shiftGlanceEmptyProvider, watch, watchNoteProvider (+23 more)

### Community 40 - "package:flutter/material.dart"
Cohesion: 0.20
Nodes (6): AppTheme, _base, dark, light, build, DividerBlockView

### Community 41 - "coach_overlay.dart"
Cohesion: 0.08
Nodes (22): CoachStep, createState, hole, _i, index, initState, isLast, isNew (+14 more)

### Community 42 - "quick_add_task_screen.dart"
Cohesion: 0.08
Nodes (25): active, activeColor, _Chip, createState, _cyclePriority, _dateLabel, _dateStr, _dismiss (+17 more)

### Community 43 - "trackers_dao.dart"
Cohesion: 0.07
Nodes (22): deleteItemsForTracker, deleteLog, deleteLogsForDate, deleteTracker, deleteValuesForLog, getAllTrackers, getItemsForTracker, getLogsForDate (+14 more)

### Community 44 - "program_dao.dart"
Cohesion: 0.07
Nodes (23): countCompletedSessionsForProgram, deleteProgram, deleteProgramExercise, deleteProgramSession, findTemplateByName, getAllPrograms, getExercisesForSession, getProgramById (+15 more)

### Community 45 - "program_detail_screen.dart"
Cohesion: 0.09
Nodes (20): _addSession, build, createState, _deleteProgram, _deleteSession, exercise, _ExerciseRow, _labels (+12 more)

### Community 46 - "Color"
Cohesion: 0.12
Nodes (3): AgendaRemoteViewsFactory, Item, AgendaRemoteViewsService

### Community 47 - "exercise_picker_screen.dart"
Cohesion: 0.08
Nodes (24): build, createState, dispose, _equipment, _equipments, exercise, _ExerciseTile, _formKey (+16 more)

### Community 48 - "workout_dao.dart"
Cohesion: 0.07
Nodes (22): deleteSession, deleteSet, getAllExercises, getAllSessions, getBestWeightForExercise, getExercisesByMuscle, getLastSessionSets, getMuscleTargets (+14 more)

### Community 49 - "notebook_detail_screen.dart"
Cohesion: 0.09
Nodes (16): noteSearchItemsProvider, accentColorValue, note, notebookId, onLongPress, onTap, build, _createNotebook (+8 more)

### Community 50 - "DateTime?"
Cohesion: 0.08
Nodes (16): blanks, day, monthLeadingBlanks, startOfWeek, subtract, weekdayHeaderLetters, main, now (+8 more)

### Community 51 - "app_settings.dart"
Cohesion: 0.08
Nodes (20): copyWith, defaults, devMode, experimentalTargets, homeBlocks, icon, label, notebooksSort (+12 more)

### Community 52 - "coach_controller.dart"
Cohesion: 0.09
Nodes (17): build, _busy, child, CoachController, createState, hasSeenAnything, _kSeenKey, _kVersionKey (+9 more)

### Community 53 - "../../../../core/database/app_database.dart"
Cohesion: 0.13
Nodes (12): ImageStorageService, accentColorValue, build, _cover, _header, images, note, NoteGridCard (+4 more)

### Community 54 - "archive_providers.dart"
Cohesion: 0.08
Nodes (19): archivedHabitsProvider, archivedListsProvider, archivedNotebooksProvider, archivedNotesProvider, archivedNoteTextProvider, archivedTasksProvider, archivedTrackersProvider, deletedHabitsProvider (+11 more)

### Community 55 - "_"
Cohesion: 0.09
Nodes (20): _, appVersion, batteryExempt, _channel, checks, collect, deviceModel, DiagnosticsService (+12 more)

### Community 56 - "tracker_detail_screen.dart"
Cohesion: 0.08
Nodes (22): build, _confirmDelete, _confirmDeleteTracker, date, _DateGroup, _EmptyHistory, fieldType, _formatDate (+14 more)

### Community 57 - "shifts_providers.dart"
Cohesion: 0.12
Nodes (11): appDatabase, appDatabaseProvider, db, addRotation, assign, build, clear, deleteRotation (+3 more)

### Community 58 - "trackers_repository.dart"
Cohesion: 0.09
Nodes (17): addTracker, _dao, _dateFmt, deleteLog, deleteTracker, getAllTrackers, _itemFromRow, logChecklist (+9 more)

### Community 59 - "@Riverpod"
Cohesion: 0.06
Nodes (38): exerciseFilterProvider, filteredExercisesProvider, lastSessionHintsProvider, ToggleCompletion, rotationsProvider, shiftEditorProvider, rotations, ShiftEditor (+30 more)

### Community 60 - "add_habit_screen.dart"
Cohesion: 0.09
Nodes (20): AddHabitScreen, _AddHabitScreenState, build, createState, _DayTargetSelector, dispose, _formKey, habit (+12 more)

### Community 61 - "coach_tip.dart"
Cohesion: 0.09
Nodes (22): codexTopicId, id, kCoachActiveWorkout, kCoachArchived, kCoachCodex, kCoachHabits, kCoachHome, kCoachListDetail (+14 more)

### Community 62 - "tasks_repository.dart"
Cohesion: 0.09
Nodes (20): addTask, _compareDueDates, _dao, _dateFmt, _dateStr, deleteTask, _fromRow, getAllTasks (+12 more)

### Community 63 - "list_detail_screen.dart"
Cohesion: 0.11
Nodes (11): listsRepositoryProvider, _addSection, _deleteSection, listId, onAddTask, onDelete, onRename, _promptForName (+3 more)

### Community 64 - "settings_screen.dart"
Cohesion: 0.09
Nodes (15): _checkForUpdates, _configureGithub, _exportData, _formatTime, _importData, isLastVisible, isVisible, label (+7 more)

### Community 65 - "codex_topic.dart"
Cohesion: 0.09
Nodes (20): body, bullet, category, CodexBlock, CodexBlockKind, CodexCategory, data, heading (+12 more)

### Community 66 - "_"
Cohesion: 0.09
Nodes (18): _, _agendaHorizonDays, _agendaProvider, _androidProvider, _buildAgenda, _buildCombinedTasks, _buildMonthCells, _dateKey (+10 more)

### Community 67 - "github_feedback_service.dart"
Cohesion: 0.09
Nodes (19): failure, GithubFeedbackConfig, GithubFeedbackService, GithubPushResult, _headers, isValidRepo, _kRepo, _kToken (+11 more)

### Community 68 - "_"
Cohesion: 0.09
Nodes (21): _, cancelRest, canPromote, _channel, _dateKey, _decodeMap, _enabledKey, _habitsDoneKey (+13 more)

### Community 69 - "muscle_targets_editor_screen.dart"
Cohesion: 0.12
Nodes (16): _btn, build, frequency, _Header, label, _maxFreq, _maxSets, muscle (+8 more)

### Community 70 - "log_entry_screen.dart"
Cohesion: 0.10
Nodes (21): build, _buildChecklistItems, _buildSessionFields, _checked, _controllers, createState, dispose, initState (+13 more)

### Community 71 - "CombinedTasksRemoteViewsFactory"
Cohesion: 0.15
Nodes (3): CombinedTasksRemoteViewsFactory, Item, Task

### Community 72 - "create_program_screen.dart"
Cohesion: 0.10
Nodes (18): build, _createCustom, createState, _deleteMyTemplate, dispose, icon, _loading, _nameCtrl (+10 more)

### Community 73 - "@freezed"
Cohesion: 0.14
Nodes (9): HabitCompletionModel, HabitModel, HabitWithStatus, _, TaskModel, TrackerLogModel, TrackerLogValueModel, TrackerWithProgress (+1 more)

### Community 74 - "shell_scaffold.dart"
Cohesion: 0.12
Nodes (9): build, _buildTitle, createState, _formattedDate, HomeShell, _HomeShellState, _labelForBranch, navigationShell (+1 more)

### Community 75 - "habits_repository.dart"
Cohesion: 0.10
Nodes (14): addHabit, calculateStreak, _completionFromRow, _dao, _dateFmt, _dateStr, deleteHabit, getAllHabits (+6 more)

### Community 76 - "lists_repository.dart"
Cohesion: 0.10
Nodes (17): addLabel, addList, addSection, _dao, deleteLabel, deleteList, deleteSection, moveTaskToList (+9 more)

### Community 77 - "taskListsProvider"
Cohesion: 0.19
Nodes (13): _pickListFilter, build, labelIdsForTaskProvider, listTaskCountsProvider, taskListsProvider, _buildListPicker, build, ListsOverviewScreen (+5 more)

### Community 78 - "task_detail_sheet.dart"
Cohesion: 0.06
Nodes (25): _CompletedHeader, count, _sectionHeader, _SectionHeaderSentinel, TaskListScreen, block, dao, _dueText (+17 more)

### Community 79 - "exercise_accordion_card.dart"
Cohesion: 0.06
Nodes (25): onChanged, selected, checkedItemIds, colorValue, icon, name, trackerId, TrackerTodayStatus (+17 more)

### Community 80 - "day_time_grid.dart"
Cohesion: 0.17
Nodes (8): dateStr, _gutter, _hourHeight, item, shift, _shiftBands, _Slab, tasks

### Community 81 - "program_exercises_table.dart"
Cohesion: 0.10
Nodes (16): exerciseId, exerciseName, id, orderIndex, ProgramExercises, programSessionId, restSeconds, targetReps (+8 more)

### Community 82 - "habits_dao.dart"
Cohesion: 0.10
Nodes (17): deleteCompletion, deleteHabit, getAllHabits, getCompletionsForHabit, getHabit, insertCompletion, insertHabit, isCompletedOn (+9 more)

### Community 84 - "MonthRemoteViewsFactory"
Cohesion: 0.12
Nodes (3): Cell, MonthRemoteViewsFactory, MonthRemoteViewsService

### Community 85 - "text_block_view.dart"
Cohesion: 0.11
Nodes (16): autofocus, block, build, createState, _ctrl, didUpdateWidget, dispose, _focus (+8 more)

### Community 86 - "checkbox_block_view.dart"
Cohesion: 0.11
Nodes (17): autofocus, block, build, CheckboxBlockView, _CheckboxBlockViewState, createState, _ctrl, didUpdateWidget (+9 more)

### Community 87 - "_"
Cohesion: 0.11
Nodes (15): _, autoCheck, _autoCheckEvery, check, download, downloadUrl, _isNewer, _lastCheckKey (+7 more)

### Community 88 - "home_block_config.dart"
Cohesion: 0.05
Nodes (33): _boolOf, collapsedFromConfig, daysFromConfig, _decode, hideWhenEmptyFromConfig, _intOf, jsonEncode, labelConfig (+25 more)

### Community 89 - "tasks_table.dart"
Cohesion: 0.11
Nodes (16): archivedAt, createdAt, deletedAt, dueDate, dueTime, durationMinutes, id, isCompleted (+8 more)

### Community 90 - "package:drift/drift.dart"
Cohesion: 0.11
Nodes (13): id, itemId, logId, TrackerLogValues, valueText, compensationStep, frequency, groupKey (+5 more)

### Community 91 - "program_template_data.dart"
Cohesion: 0.11
Nodes (18): colorValue, description, exerciseName, exercises, ExerciseTemplateData, kBuiltInProgramTemplates, kTemplatePPL, kTemplateUpperLower (+10 more)

### Community 92 - "programs_table.dart"
Cohesion: 0.11
Nodes (15): equipment, ExerciseLibrary, id, isCustom, name, primaryMuscle, secondaryMuscles, createdAt (+7 more)

### Community 93 - "List"
Cohesion: 0.11
Nodes (9): kCoachTips, kCodexTopics, kCurrentRelease, kReleaseHighlights, kSeedExercises, exercises, kQuickStartTemplates, name (+1 more)

### Community 94 - "tracker_template.dart"
Cohesion: 0.11
Nodes (12): fromString, sessionLog, TrackerModel, TrackerType, value, color, description, icon (+4 more)

### Community 95 - "photo_block_view.dart"
Cohesion: 0.12
Nodes (15): _photo, imageStorageServiceProvider, _arrangePhoto, _NoteRow, block, build, _circleButton, isCover (+7 more)

### Community 96 - "IntColumn get"
Cohesion: 0.12
Nodes (12): date, habitId, id, configJson, id, orderIndex, type, colorValue (+4 more)

### Community 99 - "day_grid_layout.dart"
Cohesion: 0.14
Nodes (12): column, columns, DayGridItem, durationMin, i, layoutDayItems, result, splitTimed (+4 more)

### Community 100 - "int?"
Cohesion: 0.22
Nodes (7): id, notebookId, notebookName, noteMatchLine, searchNotes, text, title

### Community 101 - "list_form_dialog.dart"
Cohesion: 0.12
Nodes (14): build, _color, createState, dispose, hintText, initialColor, initialName, initState (+6 more)

### Community 102 - "notebook_form_dialog.dart"
Cohesion: 0.12
Nodes (15): build, _color, createState, dispose, _icon, initialColor, initialIcon, initialName (+7 more)

### Community 103 - "workout_list_screen.dart"
Cohesion: 0.12
Nodes (16): _ActiveBanner, _buildExerciseChips, color, _EmptyState, icon, label, onResume, session (+8 more)

### Community 107 - "../../../coach/presentation/coach_controller.dart"
Cohesion: 0.08
Nodes (13): CoachTip, CodexTopic, coachTipForTopic, fallback, _block, topic, build, createState (+5 more)

### Community 108 - "tracker_logs_table.dart"
Cohesion: 0.12
Nodes (12): fieldType, id, name, sortOrder, trackerId, TrackerItems, createdAt, id (+4 more)

### Community 109 - "notes_repository.dart"
Cohesion: 0.13
Nodes (11): addPhotoBlock, _copyCompanions, cropPhotoBlock, _dao, deleteNoteWithPhotos, duplicateNote, _images, insertTemplateInto (+3 more)

### Community 110 - "exercise_history_sheet.dart"
Cohesion: 0.13
Nodes (14): ExerciseHistoryEntry, build, createState, entry, ExerciseHistorySheet, _ExerciseHistorySheetState, exerciseName, _HistoryTile (+6 more)

### Community 111 - "week_strip.dart"
Cohesion: 0.13
Nodes (14): createState, initState, _isCurrentWeek, _jumpToToday, _monthLabel, _nextWeek, onDateSelected, _prevWeek (+6 more)

### Community 112 - "image_storage_service.dart"
Cohesion: 0.13
Nodes (9): cropExisting, delete, _dir, duplicate, exists, pickAndStore, _picker, resolvePath (+1 more)

### Community 113 - "Table"
Cohesion: 0.13
Nodes (13): HabitCompletions, HomeBlocks, colorValue, id, labelId, Labels, name, orderIndex (+5 more)

### Community 114 - "lists_repository_test.dart"
Cohesion: 0.18
Nodes (9): ListsRepository, addList, addSection, addTask, db, listsDao, main, repo (+1 more)

### Community 115 - "../../../../core/database/app_database.dart"
Cohesion: 0.12
Nodes (10): blockLabel, chosenCover, firstPhoto, firstPhotoFilename, NotePreview, photoCount, snippet, NotebookChoice (+2 more)

### Community 116 - "archive_search_test.dart"
Cohesion: 0.22
Nodes (5): all, gymHabit, main, shoppingList, weekendNote

### Community 117 - "live_notification_settings_screen.dart"
Cohesion: 0.14
Nodes (10): build, _canPromote, createState, _enabled, initState, _load, _loaded, _setSnoozeMode (+2 more)

### Community 118 - "codex_screen.dart"
Cohesion: 0.09
Nodes (14): hiddenGems, inBody, inTitle, q, searchCodex, browsableTopics, whatsNewTopics, build (+6 more)

### Community 119 - "ConsumerState"
Cohesion: 0.20
Nodes (12): _TrackerInlineCard, _TrackerInlineCardState, ActiveWorkoutScreen, _ActiveWorkoutScreenState, CreateProgramScreen, _CreateProgramScreenState, _AddCustomExerciseSheet, _AddCustomExerciseSheetState (+4 more)

### Community 120 - "app_drawer.dart"
Cohesion: 0.13
Nodes (12): AppDrawer, createState, _DrawerTile, enabled, icon, label, _lastTap, onTap (+4 more)

### Community 121 - "group_score.dart"
Cohesion: 0.13
Nodes (12): frequencyMet, frequencyTarget, fullyMet, group, label, muscleKey, MuscleScore, sessionsDone (+4 more)

### Community 122 - "note_blocks_table.dart"
Cohesion: 0.13
Nodes (13): bold, checked, collapsed, content, headingLevel, highlighted, id, indent (+5 more)

### Community 123 - "workout_sets_table.dart"
Cohesion: 0.13
Nodes (12): durationSeconds, exerciseId, exerciseName, id, isPr, isWarmup, reps, restSeconds (+4 more)

### Community 124 - "workoutRepositoryProvider"
Cohesion: 0.10
Nodes (18): allWorkoutSessionsProvider, allWorkoutSessions, deleteSet, discard, updateSet, weekFreeDays, weeklyScoreboard, weeklyTargets (+10 more)

### Community 126 - "block_config_sheet.dart"
Cohesion: 0.10
Nodes (8): blockHasOptions, blockId, kHideableTypes, kLimitableTypes, showBlockConfigSheet, type, notes, showNotePicker

### Community 127 - "task_priority.dart"
Cohesion: 0.14
Nodes (10): color, fromInt, high, label, toInt, _, color, _dayLabels (+2 more)

### Community 128 - "note_task_linker.dart"
Cohesion: 0.14
Nodes (8): _dateFmt, _ensureNoteList, _listsDao, mirrorTaskCompletionToBlock, _notesDao, onBlockCheckedChanged, reconcileBlock, _tasksDao

### Community 129 - "package:go_router/go_router.dart"
Cohesion: 0.10
Nodes (10): kPatchNotesSeenKey, seen, setString, build, HabitListScreen, _archive, build, HabitTile (+2 more)

### Community 130 - "live_background_callback.dart"
Cohesion: 0.10
Nodes (16): BackupService, _db, _deleteOrder, exportToJson, _formatVersion, importFromJson, action, _dateKey (+8 more)

### Community 131 - "widget_settings_screen.dart"
Cohesion: 0.14
Nodes (12): _apply, _bgColor, _bgPresets, build, createState, _defaultBg, _Header, initState (+4 more)

### Community 132 - "task_lists_table.dart"
Cohesion: 0.14
Nodes (12): archivedAt, autoArchiveCompleted, colorValue, createdAt, deletedAt, id, listId, ListSections (+4 more)

### Community 133 - "smart_order.dart"
Cohesion: 0.05
Nodes (34): all, backwards, before, cameFrom, cost, earlyLastTime, _earlySlots, entries (+26 more)

### Community 134 - "custom_trackers_table.dart"
Cohesion: 0.14
Nodes (13): archivedAt, colorValue, createdAt, CustomTrackers, deletedAt, description, icon, id (+5 more)

### Community 135 - ".build"
Cohesion: 0.36
Nodes (3): Card, Item, LiveCards

### Community 136 - "week_attendance_strip.dart"
Cohesion: 0.10
Nodes (13): db, program, repo, _AttendanceChip, build, ids, logged, loggedIds (+5 more)

### Community 137 - "shifts_repository.dart"
Cohesion: 0.15
Nodes (10): addRotation, clearShift, _dao, deleteRotation, _fromRow, _rotationFromRow, setShift, updateRotation (+2 more)

### Community 138 - "weekly_scoreboard_card.dart"
Cohesion: 0.15
Nodes (9): color, done, _FrequencyDots, _GroupHeader, label, _MuscleRow, score, target (+1 more)

### Community 139 - "tracker_progress_card.dart"
Cohesion: 0.15
Nodes (11): build, color, done, isSession, onArchive, onTap, _ProgressBadge, _subtitle (+3 more)

### Community 140 - "markdown_feedback_builder.dart"
Cohesion: 0.15
Nodes (10): buildFeedbackMarkdown, date, FeedbackSection, general, md, sectionIds, slug, slugify (+2 more)

### Community 141 - "String get"
Cohesion: 0.12
Nodes (11): divider, NoteBlockType, parse, storageKey, fromString, glutes, label, MuscleGroup (+3 more)

### Community 142 - "_"
Cohesion: 0.15
Nodes (12): _, _append, clear, CrashLog, _file, _fileName, _maxBytes, note (+4 more)

### Community 143 - "time_block_utils.dart"
Cohesion: 0.15
Nodes (12): durationBetween, e, end, endTimeOf, formatRange, h, _hhmm, m (+4 more)

### Community 144 - "build"
Cohesion: 0.18
Nodes (3): build, maybeShowPatchNotes, build

### Community 145 - "notes_table.dart"
Cohesion: 0.15
Nodes (11): archivedAt, coverBlockId, createdAt, deletedAt, id, isFavorite, isTemplate, notebookId (+3 more)

### Community 146 - "shifts_dao.dart"
Cohesion: 0.15
Nodes (10): deleteRotation, deleteShiftForDate, getAllShifts, getRotations, getShiftForDate, insertRotation, insertShift, updateRotation (+2 more)

### Community 147 - "AppDatabase"
Cohesion: 0.07
Nodes (23): AppDatabase, NoteTaskLinker, ListsDao, TasksDao, addTask, db, habitsDao, listsDao (+15 more)

### Community 148 - "work_shift_model.dart"
Cohesion: 0.17
Nodes (9): defaultEnd, defaultStart, fromString, label, night, ShiftRotationModel, ShiftType, value (+1 more)

### Community 149 - "workout_summary_screen.dart"
Cohesion: 0.17
Nodes (10): build, _fmtDuration, _fmtNum, icon, label, _StatCard, summary, value (+2 more)

### Community 150 - "Route /workout/active"
Cohesion: 0.18
Nodes (9): build, _targetsCard, _buildWorkoutSection, _startWorkout, _startSession, _startWorkout, build, build (+1 more)

### Community 151 - "_"
Cohesion: 0.09
Nodes (20): AppColors, darkBackground, darkElevated, darkSurface, lightBackground, lightSurface, seed, streakAmber (+12 more)

### Community 152 - "habit_list_screen_test.dart"
Cohesion: 0.11
Nodes (8): githubFeedbackServiceProvider, watch, _pushToGithub, _habit, _item, main, router, _wrap

### Community 153 - "home_blocks_dao_test.dart"
Cohesion: 0.17
Nodes (5): main, dao, db, main, main

### Community 154 - "workout_actions.dart"
Cohesion: 0.18
Nodes (7): active, byName, library, order, planned, read, startProgramSession

### Community 155 - "State"
Cohesion: 0.14
Nodes (16): CoachOverlay, _CoachOverlayState, CodexScreen, _CodexScreenState, NoteArrangeView, _NoteArrangeViewState, PlannerScreen, _PlannerScreenState (+8 more)

### Community 156 - "return"
Cohesion: 0.20
Nodes (7): inBody, inTitle, matchingContentLine, null, q, n, out

### Community 157 - "archived_item.dart"
Cohesion: 0.18
Nodes (10): archivedAt, ArchivedKind, body, colorValue, deletedAt, id, key, kind (+2 more)

### Community 158 - "notebooks_table.dart"
Cohesion: 0.18
Nodes (10): archivedAt, colorValue, createdAt, deletedAt, icon, id, isFavorite, name (+2 more)

### Community 159 - "note_sort.dart"
Cohesion: 0.18
Nodes (10): activity, byActivity, byEdited, fromKey, key, label, NoteSort, out (+2 more)

### Community 160 - "heading_line_view.dart"
Cohesion: 0.18
Nodes (8): autofocus, block, build, HeadingLineView, hiddenCount, onBlur, onDeleteEmpty, onToggle

### Community 161 - "shift_picker_sheet.dart"
Cohesion: 0.12
Nodes (13): build, _editDialog, _palette, RotationsEditorScreen, _assign, build, createState, date (+5 more)

### Community 162 - "program_templates_test.dart"
Cohesion: 0.11
Nodes (12): ProgramRepository, buildProgram, db, main, repo, dao, day, db (+4 more)

### Community 163 - "diagnostics_screen.dart"
Cohesion: 0.10
Nodes (17): DiagnosticCheck, DiagnosticsReport, build, check, _CheckTile, createState, didChangeAppLifecycleState, dispose (+9 more)

### Community 165 - "rest_timer_bar.dart"
Cohesion: 0.12
Nodes (12): build, isCover, onUseAsCover, path, PhotoViewScreen, build, cs, _fmt (+4 more)

### Community 166 - "_NoteEditorScreenState"
Cohesion: 0.15
Nodes (18): build, noteBlocksProvider, notebooksProvider, notesForNotebookProvider, notesRepositoryProvider, templatesProvider, _addAnchor, build (+10 more)

### Community 167 - "smart_order_start_test.dart"
Cohesion: 0.12
Nodes (8): main, container, db, fullBody, main, namesOf, planned, start

### Community 168 - "notesDaoProvider"
Cohesion: 0.13
Nodes (16): _deleteEmpty, noteByIdProvider, notesDaoProvider, _addBlock, _addDividerBlock, _applyArrangement, _arrangeBody, _arrangeTile (+8 more)

### Community 169 - "HabitsDao"
Cohesion: 0.23
Nodes (5): HabitsDao, HomeBlocksDao, ShiftsDao, TrackersDao, ProgramDao

### Community 170 - "habits_table.dart"
Cohesion: 0.20
Nodes (9): archivedAt, createdAt, deletedAt, Habits, id, name, reminderEnabled, reminderTime (+1 more)

### Community 171 - "Color"
Cohesion: 0.10
Nodes (9): build, color, count, icon, name, NotebookTile, onLongPress, onTap (+1 more)

### Community 172 - "work_shifts_table.dart"
Cohesion: 0.20
Nodes (9): date, endTime, id, rotationColor, rotationLabel, shiftType, startTime, uniqueKeys (+1 more)

### Community 173 - "whats_new_test.dart"
Cohesion: 0.22
Nodes (3): main, main, _t

### Community 174 - "home_block_type.dart"
Cohesion: 0.18
Nodes (7): defaults, done, HomeBlockType, icon, multiInstance, parse, title

### Community 175 - "priority_badge.dart"
Cohesion: 0.33
Nodes (4): TaskPriority, build, priority, PriorityBadge

### Community 176 - "home_blocks_dao.dart"
Cohesion: 0.20
Nodes (7): addBlock, deleteBlock, ensureSeeded, getBlocks, reorderBlocks, updateConfig, watchBlocks

### Community 177 - "note_outline.dart"
Cohesion: 0.22
Nodes (7): blockDepths, depths, indentForInsertAfter, isHeading, kNoteIndentStep, lineStartsRtl, stack

### Community 178 - "weight_steps.dart"
Cohesion: 0.22
Nodes (8): down, _eps, kPlateStep, nextWeightDown, nextWeightUp, parseWeight, steps, tryParse

### Community 179 - "program_sessions_table.dart"
Cohesion: 0.22
Nodes (7): colorValue, id, name, orderIndex, programId, ProgramSessions, weekDays

### Community 182 - "startup_tab.dart"
Cohesion: 0.25
Nodes (6): AppTab, effective, startupLocation, target, visible, wanted

### Community 183 - "bool get"
Cohesion: 0.29
Nodes (5): _, displayName, hasPr, totalSets, WorkoutSessionModel

### Community 184 - "tracker_item_model.dart"
Cohesion: 0.25
Nodes (5): FieldType, fromString, text, TrackerItemModel, value

### Community 185 - "coach_due.dart"
Cohesion: 0.25
Nodes (6): 0, compareVersions, dueTips, isNewSince, x, y

### Community 186 - "note_search_test.dart"
Cohesion: 0.25
Nodes (6): NoteSearchItem, all, empty, main, shopping, untitled

### Community 187 - "static const int"
Cohesion: 0.29
Nodes (4): build, _maxShown, NotesBlock, recentNotebooksProvider

### Community 188 - "shift_date_picker_sheet.dart"
Cohesion: 0.29
Nodes (5): build, _dateStr, initialDate, _ShiftDatePickerSheet, showShiftDatePicker

### Community 190 - "_"
Cohesion: 0.25
Nodes (6): _, isRotating, isWeekly, nextRotatingSession, ProgramModel, todaysSessions

### Community 191 - "archive_search.dart"
Cohesion: 0.33
Nodes (3): matchingLine, searchArchive, ArchivedItem

### Community 192 - "coachControllerProvider"
Cohesion: 0.33
Nodes (6): coachControllerProvider, CoachMarks, _CoachMarksState, initState, build, CodexTopicScreen

### Community 193 - "streak_logic_test.dart"
Cohesion: 0.33
Nodes (3): _c, main, _streak

### Community 194 - "streak_badge.dart"
Cohesion: 0.40
Nodes (3): build, streak, StreakBadge

### Community 195 - "_ArchivedScreenState"
Cohesion: 0.40
Nodes (5): archivedItemsProvider, deletedItemsProvider, ArchivedScreen, _ArchivedScreenState, build

### Community 196 - "_"
Cohesion: 0.33
Nodes (4): _, ExerciseModel, muscleGroup, secondaryMuscleList

### Community 197 - "package:life_tracker/core/database/app_database.dart"
Cohesion: 0.11
Nodes (8): ShiftsRepository, main, main, _b, main, db, main, repo

### Community 198 - "drag_drop_test.dart"
Cohesion: 0.33
Nodes (4): _b, main, _note, _photo

### Community 199 - "widget_payload.dart"
Cohesion: 0.40
Nodes (4): argbToHex, hash, payloadChecksum, toRadixString

## Knowledge Gaps
- **2474 isolated node(s):** `SetMuscleRow`, `watchAllSessions`, `getAllSessions`, `insertSession`, `updateSession` (+2469 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 2966 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **65 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `shift_picker_sheet.dart`, `live_background_callback.dart`, `widget_settings_screen.dart`, `_`, `smart_order_start_test.dart`, `live_notification_settings_screen.dart`, `static const int`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **What connects `SetMuscleRow`, `watchAllSessions`, `getAllSessions` to the rest of the system?**
  _2474 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `workout_providers.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Why does `_` connect `_` to `package:go_router/go_router.dart`, `smart_order.dart`, `note_arrange_view.dart`, `weekly_scoreboard_card.dart`, `habit_list_screen_test.dart`, `workout_actions.dart`, `StatelessWidget`, `rest_timer_bar.dart`, `smart_order_start_test.dart`, `package:flutter/material.dart`, `DateTime?`, `_`, `exercise_accordion_card.dart`, `home_block_config.dart`, `core/settings/settings_provider.dart`, `../../../coach/presentation/coach_controller.dart`, `../../../../core/database/app_database.dart`, `live_notification_settings_screen.dart`, `ConsumerState`, `workoutRepositoryProvider`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Should `note_editor_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._
- **Why does `AppDatabase` connect `AppDatabase` to `recently_deleted_test.dart`, `live_background_callback.dart`, `home_blocks_dao_test.dart`, `program_templates_test.dart`, `package:life_tracker/core/database/app_database.dart`, `smart_order_start_test.dart`, `HabitsDao`, `app_database.dart`, `WorkoutDao`, `lists_repository_test.dart`, `package:life_tracker/core/database/app_database.dart`, `shifts_providers.dart`, `@Riverpod`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Should `notification_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.034482758620689655 - nodes in this community are weakly interconnected._