# Graph Report - trackerapp  (2026-10-27)

## Corpus Check
- 281 files · ~141,818 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 5 file(s) not represented in the graph (top: (none) 4, .pro 1)

## Summary
- 4086 nodes · 6083 edges · 250 communities (188 shown, 62 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `05d0b2af`
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
- package:flutter_riverpod/flutter_riverpod.dart
- when_parser.dart
- note_arrange_view.dart
- package:flutter_test/flutter_test.dart
- archived_screen.dart
- add_tracker_screen.dart
- day_detail_view.dart
- _
- app_database.dart
- notebook_detail_screen.dart
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
- AppDatabase
- DateTime
- app_settings.dart
- coach_controller.dart
- ../../../../core/database/app_database.dart
- archive_providers.dart
- _
- tracker_detail_screen.dart
- @Riverpod
- trackers_repository.dart
- program_providers.dart
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
- diagnostics_screen.dart
- habits_repository.dart
- lists_repository.dart
- lists_providers.dart
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
- note_task_linker_test.dart
- VoidCallback
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
- ../../../coach/data/coach_tip.dart
- task_priority.dart
- note_task_linker.dart
- package:go_router/go_router.dart
- live_background_callback.dart
- widget_settings_screen.dart
- task_lists_table.dart
- task_tile.dart
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
- HabitsDao
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
- archive_schema_test.dart
- MainActivity
- rest_timer_bar.dart
- codex_search.dart
- home_blocks_dao.dart
- home_block_type.dart
- app_colors.dart
- habits_table.dart
- notebook_tile.dart
- work_shifts_table.dart
- whats_new_test.dart
- backup_service.dart
- codex_topic_screen.dart
- Map
- note_outline.dart
- weight_steps.dart
- program_sessions_table.dart
- note_arrange_view_test.dart
- LiveActionReceiver.kt
- startup_tab.dart
- bool get
- tracker_item_model.dart
- coach_due.dart
- static const List
- static const int
- Set
- weeklyScoreboard
- _
- .onGetViewFactory
- .onReceive
- app_theme.dart
- package:riverpod_annotation/riverpod_annotation.dart
- _ArchivedScreenState
- _
- _
- drag_drop_test.dart
- widget_payload.dart
- filteredExercises
- @pragma
- app_strings.dart
- image_filename.dart
- SettingsNotifier
- note_text_style.dart
- WorkoutDao
- widget_test.dart

## God Nodes (most connected - your core abstractions)
1. `_` - 58 edges
2. `_` - 32 edges
3. `_` - 31 edges
4. `_` - 30 edges
5. `settingsProvider` - 30 edges
6. `notesDaoProvider` - 30 edges
7. `AppDatabase` - 29 edges
8. `archiveServiceProvider` - 26 edges
9. `_` - 24 edges
10. `taskListsProvider` - 19 edges

## Surprising Connections (you probably didn't know these)
- `_RecordingToggle` --inherits--> `ToggleTask`  [EXTRACTED]
  test/features/tasks/task_detail_sheet_test.dart → lib/features/tasks/presentation/providers/tasks_providers.dart
- `build` --references--> `settingsProvider`  [EXTRACTED]
  lib/core/router/shell_scaffold.dart → lib/core/settings/settings_provider.dart
- `build` --references--> `settingsProvider`  [EXTRACTED]
  lib/features/notes/presentation/screens/notes_overview_screen.dart → lib/core/settings/settings_provider.dart
- `onTap` --references--> `settingsProvider`  [EXTRACTED]
  lib/features/settings/presentation/widgets/app_drawer.dart → lib/core/settings/settings_provider.dart
- `_archive` --references--> `archiveServiceProvider`  [EXTRACTED]
  lib/features/trackers/presentation/screens/trackers_screen.dart → lib/features/archive/presentation/archive_providers.dart

## Import Cycles
- None detected.

## Communities (250 total, 62 thin omitted)

### Community 0 - "workout_providers.dart"
Cohesion: 0.03
Nodes (71): active, ActiveWorkoutState, _adaptScore, addSeconds, addSet, build, cancel, comp (+63 more)

### Community 1 - "note_editor_screen.dart"
Cohesion: 0.04
Nodes (55): noteByIdProvider, notesDaoProvider, notesRepositoryProvider, _addBlock, _addDividerBlock, _addPhoto, _AddRow, _applyArrangement (+47 more)

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

### Community 7 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.05
Nodes (23): watch, HomeBlockType, _BlockHeader, _coachWrap, collapsed, color, _dayRow, days (+15 more)

### Community 8 - "when_parser.dart"
Cohesion: 0.04
Nodes (44): _adjacent, date, _dateAtStart, _dayMonthRe, _dayMonthTightRe, _dayOrdinalRe, end, _findDate (+36 more)

### Community 9 - "note_arrange_view.dart"
Cohesion: 0.05
Nodes (33): _autoDelta, _autoTimer, block, blocks, bottom, build, center, createState (+25 more)

### Community 10 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.05
Nodes (15): main, main, main, main, main, _tip, _c, main (+7 more)

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
Nodes (32): _, ActiveWorkoutScreen, _ActiveWorkoutScreenState, _addExercise, build, _buildItems, _buildSummary, _byMuscle (+24 more)

### Community 15 - "app_database.dart"
Cohesion: 0.05
Nodes (9): migration, _newRotationColor, _oldRotationColor, _openConnection, _retagArmExercises, schemaVersion, _seedExerciseLibrary, _seedMuscleTargets (+1 more)

### Community 16 - "notebook_detail_screen.dart"
Cohesion: 0.07
Nodes (25): _reschedule, archiveServiceProvider, _confirmDelete, _archive, build, HabitTile, item, _toggle (+17 more)

### Community 17 - "notes_providers.dart"
Cohesion: 0.07
Nodes (27): allNotesProvider, db, lastEdit, lastNoteEditByNotebookProvider, names, nbs, notebooks, notebooksProvider (+19 more)

### Community 18 - "shell_scaffold.dart"
Cohesion: 0.06
Nodes (24): build, _buildTitle, createState, _formattedDate, HomeShell, _HomeShellState, _labelForBranch, navigationShell (+16 more)

### Community 19 - "tasks_providers.dart"
Cohesion: 0.08
Nodes (29): deleteTaskProvider, _rescheduleReminders, listsDaoProvider, add, AddTask, allTasks, build, capturedTasks (+21 more)

### Community 20 - "program_repository.dart"
Cohesion: 0.06
Nodes (29): addExercise, addSession, _copySessionsInto, createFromTemplate, createFromUserTemplate, createProgram, deleteExercise, deleteProgram (+21 more)

### Community 21 - "workout_repository.dart"
Cohesion: 0.06
Nodes (30): addCustomExercise, addSet, createSession, _dao, _dateFmt, deleteSession, deleteSet, _exerciseFromRow (+22 more)

### Community 22 - "package:life_tracker/core/database/app_database.dart"
Cohesion: 0.08
Nodes (21): NotesDao, main, main, dao, db, main, makeBlock, now (+13 more)

### Community 23 - "task_detail_sheet_test.dart"
Cohesion: 0.07
Nodes (17): main, task, main, task, main, _task, build, calls (+9 more)

### Community 24 - "set_row.dart"
Cohesion: 0.06
Nodes (31): _apply, build, controller, _copyPrev, createState, didUpdateWidget, dispose, _flush (+23 more)

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
Cohesion: 0.08
Nodes (28): _buildChips, color, _createMyWorkout, _deleteMyWorkout, isHighlighted, label, _MiniChip, _ModeToggle (+20 more)

### Community 30 - "trackers_providers.dart"
Cohesion: 0.08
Nodes (25): deleteLogProvider, deleteTrackerProvider, add, AddTracker, build, dao, addTrackerProvider, logChecklistProvider (+17 more)

### Community 31 - "program_session_editor_screen.dart"
Cohesion: 0.07
Nodes (30): _addExercise, build, color, createState, _deleteExercise, _editExercise, exercise, _ExerciseEditDialog (+22 more)

### Community 32 - "ConsumerWidget"
Cohesion: 0.08
Nodes (28): build, githubFeedbackConfigProvider, githubFeedbackServiceProvider, settingsProvider, WorkoutBlock, tasksForDateProvider, build, _HabitItem (+20 more)

### Community 33 - "recently_deleted_test.dart"
Cohesion: 0.07
Nodes (24): ArchiveService, NotesRepository, addHabit, addTask, archive, db, habits, ids (+16 more)

### Community 34 - "_"
Cohesion: 0.09
Nodes (24): deleteHabitProvider, add, AddHabit, build, dao, addHabitProvider, habitsWithStatusProvider, updateHabitProvider (+16 more)

### Community 35 - "pinned_note_block.dart"
Cohesion: 0.07
Nodes (19): _append, build, createState, _deleteEmpty, _focusRequestId, _indentStep, kPinnedNoteMaxHeight, _line (+11 more)

### Community 36 - "day_column.dart"
Cohesion: 0.08
Nodes (23): isEmpty, _key, ShiftBlock, dayDotSummaryProvider, build, color, date, DayColumn (+15 more)

### Community 37 - "app.dart"
Cohesion: 0.08
Nodes (16): createState, didChangeAppLifecycleState, dispose, initState, LifeTrackerApp, _LifeTrackerAppState, _liveChannel, _maybeOfferUpdate (+8 more)

### Community 38 - "shift_month_calendar.dart"
Cohesion: 0.07
Nodes (25): color, _CountTile, createState, dateStr, day, initialMonth, initState, isSelected (+17 more)

### Community 39 - "home_blocks_providers.dart"
Cohesion: 0.13
Nodes (22): allNotesProvider, dao, ensureSeeded, homeBlockRowsProvider, homeBlocksDaoProvider, shiftGlanceEmptyProvider, watch, watchNoteProvider (+14 more)

### Community 40 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (17): build, EmptyHabitsPlaceholder, build, streak, StreakBadge, build, DividerBlockView, NotebookChoice (+9 more)

### Community 41 - "coach_overlay.dart"
Cohesion: 0.08
Nodes (24): CoachOverlay, _CoachOverlayState, CoachStep, createState, hole, _i, index, initState (+16 more)

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
Cohesion: 0.08
Nodes (24): _addSession, build, createState, _deleteProgram, _deleteSession, exercise, _ExerciseRow, _labels (+16 more)

### Community 47 - "exercise_picker_screen.dart"
Cohesion: 0.08
Nodes (24): build, createState, dispose, _equipment, _equipments, exercise, _ExerciseTile, _formKey (+16 more)

### Community 48 - "workout_dao.dart"
Cohesion: 0.08
Nodes (21): deleteSession, deleteSet, getAllExercises, getAllSessions, getBestWeightForExercise, getExercisesByMuscle, getLastSessionSets, getMuscleTargets (+13 more)

### Community 49 - "AppDatabase"
Cohesion: 0.09
Nodes (16): AppDatabase, ShiftsRepository, ListsDao, TasksDao, ListsRepository, db, main, repo (+8 more)

### Community 50 - "DateTime"
Cohesion: 0.08
Nodes (16): blanks, day, monthLeadingBlanks, startOfWeek, subtract, weekdayHeaderLetters, main, now (+8 more)

### Community 51 - "app_settings.dart"
Cohesion: 0.08
Nodes (20): copyWith, defaults, devMode, experimentalTargets, homeBlocks, icon, label, notebooksSort (+12 more)

### Community 52 - "coach_controller.dart"
Cohesion: 0.09
Nodes (19): build, _busy, child, CoachController, CoachMarks, _CoachMarksState, createState, hasSeenAnything (+11 more)

### Community 53 - "../../../../core/database/app_database.dart"
Cohesion: 0.09
Nodes (18): blockLabel, chosenCover, firstPhoto, firstPhotoFilename, NotePreview, photoCount, snippet, accentColorValue (+10 more)

### Community 54 - "archive_providers.dart"
Cohesion: 0.08
Nodes (19): archivedHabitsProvider, archivedListsProvider, archivedNotebooksProvider, archivedNotesProvider, archivedNoteTextProvider, archivedTasksProvider, archivedTrackersProvider, deletedHabitsProvider (+11 more)

### Community 55 - "_"
Cohesion: 0.08
Nodes (21): _, appVersion, batteryExempt, _channel, checks, collect, deviceModel, DiagnosticsReport (+13 more)

### Community 56 - "tracker_detail_screen.dart"
Cohesion: 0.08
Nodes (22): build, _confirmDelete, _confirmDeleteTracker, date, _DateGroup, _EmptyHistory, fieldType, _formatDate (+14 more)

### Community 57 - "@Riverpod"
Cohesion: 0.11
Nodes (18): addRotation, assign, build, clear, rotationsProvider, shiftEditorProvider, deleteRotation, rotations (+10 more)

### Community 58 - "trackers_repository.dart"
Cohesion: 0.09
Nodes (17): addTracker, _dao, _dateFmt, deleteLog, deleteTracker, getAllTrackers, _itemFromRow, logChecklist (+9 more)

### Community 59 - "program_providers.dart"
Cohesion: 0.09
Nodes (17): activeProgram, allPrograms, activeProgramProvider, allProgramsProvider, myWorkoutsProvider, programByIdProvider, programRepositoryProvider, programTemplatesProvider (+9 more)

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
Cohesion: 0.09
Nodes (18): onChanged, selected, _btn, build, frequency, _Header, label, _maxFreq (+10 more)

### Community 70 - "log_entry_screen.dart"
Cohesion: 0.10
Nodes (21): build, _buildChecklistItems, _buildSessionFields, _checked, _controllers, createState, dispose, initState (+13 more)

### Community 71 - "CombinedTasksRemoteViewsFactory"
Cohesion: 0.12
Nodes (4): CombinedTasksRemoteViewsFactory, Item, Task, CombinedTasksRemoteViewsService

### Community 72 - "create_program_screen.dart"
Cohesion: 0.10
Nodes (18): build, _createCustom, createState, _deleteMyTemplate, dispose, icon, _loading, _nameCtrl (+10 more)

### Community 73 - "@freezed"
Cohesion: 0.14
Nodes (10): HabitCompletionModel, HabitModel, HabitWithStatus, TrackerLogModel, TrackerLogValueModel, TrackerWithProgress, _, ProgramExerciseModel (+2 more)

### Community 74 - "diagnostics_screen.dart"
Cohesion: 0.10
Nodes (16): DiagnosticCheck, build, check, _CheckTile, createState, didChangeAppLifecycleState, dispose, _fixBattery (+8 more)

### Community 75 - "habits_repository.dart"
Cohesion: 0.10
Nodes (14): addHabit, calculateStreak, _completionFromRow, _dao, _dateFmt, _dateStr, deleteHabit, getAllHabits (+6 more)

### Community 76 - "lists_repository.dart"
Cohesion: 0.10
Nodes (17): addLabel, addList, addSection, _dao, deleteLabel, deleteList, deleteSection, moveTaskToList (+9 more)

### Community 77 - "lists_providers.dart"
Cohesion: 0.11
Nodes (16): _pickListFilter, byId, _dateFmt, _dateStr, listTaskCountsProvider, merged, now, overdue (+8 more)

### Community 78 - "task_detail_sheet.dart"
Cohesion: 0.11
Nodes (13): _CompletedHeader, count, _sectionHeader, _SectionHeaderSentinel, TaskListScreen, block, dao, _dueText (+5 more)

### Community 79 - "exercise_accordion_card.dart"
Cohesion: 0.10
Nodes (17): _addSet, build, _completedCount, completedSetIds, exerciseName, expanded, _fmt, muscle (+9 more)

### Community 80 - "day_time_grid.dart"
Cohesion: 0.11
Nodes (15): build, dateStr, DayTimeGrid, _gutter, _hourHeight, item, shift, _shiftBands (+7 more)

### Community 81 - "program_exercises_table.dart"
Cohesion: 0.10
Nodes (16): exerciseId, exerciseName, id, orderIndex, ProgramExercises, programSessionId, restSeconds, targetReps (+8 more)

### Community 82 - "habits_dao.dart"
Cohesion: 0.10
Nodes (17): deleteCompletion, deleteHabit, getAllHabits, getCompletionsForHabit, getHabit, insertCompletion, insertHabit, isCompletedOn (+9 more)

### Community 84 - "MonthRemoteViewsFactory"
Cohesion: 0.13
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
Cohesion: 0.11
Nodes (17): _boolOf, collapsedFromConfig, daysFromConfig, _decode, hideWhenEmptyFromConfig, _intOf, jsonEncode, labelConfig (+9 more)

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
Nodes (14): _photo, imageStorageServiceProvider, _arrangePhoto, block, build, _circleButton, isCover, kNotePhotoMaxHeight (+6 more)

### Community 96 - "IntColumn get"
Cohesion: 0.12
Nodes (12): date, habitId, id, configJson, id, orderIndex, type, colorValue (+4 more)

### Community 99 - "day_grid_layout.dart"
Cohesion: 0.12
Nodes (14): column, columns, DayGridItem, durationMin, i, layoutDayItems, result, splitTimed (+6 more)

### Community 100 - "int?"
Cohesion: 0.12
Nodes (13): id, notebookId, notebookName, noteMatchLine, NoteSearchItem, searchNotes, text, title (+5 more)

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
Cohesion: 0.13
Nodes (7): build, createState, _dateStr, initState, _monthView, _selectedDate, ShiftScheduleScreen

### Community 108 - "tracker_logs_table.dart"
Cohesion: 0.12
Nodes (12): fieldType, id, name, sortOrder, trackerId, TrackerItems, createdAt, id (+4 more)

### Community 109 - "notes_repository.dart"
Cohesion: 0.12
Nodes (11): addPhotoBlock, _copyCompanions, cropPhotoBlock, _dao, deleteNoteWithPhotos, duplicateNote, _images, insertTemplateInto (+3 more)

### Community 110 - "exercise_history_sheet.dart"
Cohesion: 0.13
Nodes (14): ExerciseHistoryEntry, build, createState, entry, ExerciseHistorySheet, _ExerciseHistorySheetState, exerciseName, _HistoryTile (+6 more)

### Community 111 - "week_strip.dart"
Cohesion: 0.13
Nodes (14): createState, initState, _isCurrentWeek, _jumpToToday, _monthLabel, _nextWeek, onDateSelected, _prevWeek (+6 more)

### Community 112 - "image_storage_service.dart"
Cohesion: 0.12
Nodes (10): cropExisting, delete, _dir, duplicate, exists, ImageStorageService, pickAndStore, _picker (+2 more)

### Community 113 - "Table"
Cohesion: 0.13
Nodes (13): HabitCompletions, HomeBlocks, colorValue, id, labelId, Labels, name, orderIndex (+5 more)

### Community 114 - "note_task_linker_test.dart"
Cohesion: 0.12
Nodes (12): NoteTaskLinker, db, linker, listsDao, main, notesDao, now, tasksDao (+4 more)

### Community 115 - "VoidCallback"
Cohesion: 0.12
Nodes (10): build, isCover, onUseAsCover, path, PhotoViewScreen, _archive, build, _EmptyTrackersPlaceholder (+2 more)

### Community 116 - "archive_search_test.dart"
Cohesion: 0.13
Nodes (8): matchingLine, searchArchive, ArchivedItem, all, gymHabit, main, shoppingList, weekendNote

### Community 117 - "live_notification_settings_screen.dart"
Cohesion: 0.14
Nodes (12): build, _canPromote, createState, _enabled, initState, LiveNotificationSettingsScreen, _LiveNotificationSettingsScreenState, _load (+4 more)

### Community 118 - "codex_screen.dart"
Cohesion: 0.14
Nodes (9): build, _byCategory, CodexScreen, _CodexScreenState, createState, dispose, _gemsOnly, _search (+1 more)

### Community 119 - "ConsumerState"
Cohesion: 0.18
Nodes (12): DiagnosticsScreen, _DiagnosticsScreenState, AddTaskScreen, _AddTaskScreenState, _TrackerInlineCard, _TrackerInlineCardState, CreateProgramScreen, _CreateProgramScreenState (+4 more)

### Community 120 - "app_drawer.dart"
Cohesion: 0.14
Nodes (11): createState, _DrawerTile, enabled, icon, label, _lastTap, onTap, subtitle (+3 more)

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
Cohesion: 0.14
Nodes (14): ActiveWorkout, allWorkoutSessions, activeWorkoutProvider, allWorkoutSessionsProvider, lastSessionHintsProvider, deleteSet, discard, lastSessionHints (+6 more)

### Community 126 - "../../../coach/data/coach_tip.dart"
Cohesion: 0.14
Nodes (5): CoachTip, coachTipForTopic, fallback, build, HabitListScreen

### Community 127 - "task_priority.dart"
Cohesion: 0.14
Nodes (9): color, fromInt, high, label, TaskPriority, toInt, build, priority (+1 more)

### Community 128 - "note_task_linker.dart"
Cohesion: 0.14
Nodes (8): _dateFmt, _ensureNoteList, _listsDao, mirrorTaskCompletionToBlock, _notesDao, onBlockCheckedChanged, reconcileBlock, _tasksDao

### Community 129 - "package:go_router/go_router.dart"
Cohesion: 0.14
Nodes (3): kPatchNotesSeenKey, seen, setString

### Community 130 - "live_background_callback.dart"
Cohesion: 0.14
Nodes (10): action, _dateKey, db, _decodeMap, id, mode, _snooze, snoozes (+2 more)

### Community 131 - "widget_settings_screen.dart"
Cohesion: 0.14
Nodes (12): _apply, _bgColor, _bgPresets, build, createState, _defaultBg, _Header, initState (+4 more)

### Community 132 - "task_lists_table.dart"
Cohesion: 0.14
Nodes (12): archivedAt, autoArchiveCompleted, colorValue, createdAt, deletedAt, id, listId, ListSections (+4 more)

### Community 133 - "task_tile.dart"
Cohesion: 0.14
Nodes (12): done, dueDate, _DueDateChip, dueTime, durationMinutes, _formatDate, _isOverdue, listId (+4 more)

### Community 134 - "custom_trackers_table.dart"
Cohesion: 0.14
Nodes (13): archivedAt, colorValue, createdAt, CustomTrackers, deletedAt, description, icon, id (+5 more)

### Community 135 - ".build"
Cohesion: 0.31
Nodes (3): Card, Item, LiveCards

### Community 136 - "week_attendance_strip.dart"
Cohesion: 0.15
Nodes (10): _AttendanceChip, build, ids, logged, loggedIds, loggedThisWeek, program, session (+2 more)

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
Cohesion: 0.15
Nodes (8): divider, NoteBlockType, parse, storageKey, fromString, glutes, label, MuscleGroup

### Community 142 - "_"
Cohesion: 0.15
Nodes (12): _, _append, clear, CrashLog, _file, _fileName, _maxBytes, note (+4 more)

### Community 143 - "time_block_utils.dart"
Cohesion: 0.15
Nodes (12): durationBetween, e, end, endTimeOf, formatRange, h, _hhmm, m (+4 more)

### Community 144 - "build"
Cohesion: 0.15
Nodes (4): build, maybeShowPatchNotes, build, build

### Community 145 - "notes_table.dart"
Cohesion: 0.15
Nodes (11): archivedAt, coverBlockId, createdAt, deletedAt, id, isFavorite, isTemplate, notebookId (+3 more)

### Community 146 - "shifts_dao.dart"
Cohesion: 0.15
Nodes (10): deleteRotation, deleteShiftForDate, getAllShifts, getRotations, getShiftForDate, insertRotation, insertShift, updateRotation (+2 more)

### Community 147 - "HabitsDao"
Cohesion: 0.23
Nodes (5): HabitsDao, HomeBlocksDao, ShiftsDao, TrackersDao, ProgramDao

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
Cohesion: 0.17
Nodes (12): _, dayFill, dayForeground, dayIconColor, fill, foreground, icon, iconColor (+4 more)

### Community 152 - "habit_list_screen_test.dart"
Cohesion: 0.17
Nodes (5): _habit, _item, main, router, _wrap

### Community 153 - "home_blocks_dao_test.dart"
Cohesion: 0.17
Nodes (5): main, dao, db, main, main

### Community 154 - "workout_actions.dart"
Cohesion: 0.18
Nodes (7): active, byName, library, order, planned, read, startProgramSession

### Community 155 - "State"
Cohesion: 0.22
Nodes (8): PlannerScreen, _PlannerScreenState, WidgetSettingsScreen, _WidgetSettingsScreenState, _ItemRow, _ItemRowState, SetRow, _SetRowState

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
Cohesion: 0.20
Nodes (9): _assign, build, createState, date, initState, _ShiftPickerSheet, _ShiftPickerSheetState, showShiftPicker (+1 more)

### Community 162 - "program_templates_test.dart"
Cohesion: 0.18
Nodes (5): ProgramRepository, buildProgram, db, main, repo

### Community 163 - "archive_schema_test.dart"
Cohesion: 0.18
Nodes (8): addTask, db, habitsDao, listsDao, main, now, tasksDao, trackersDao

### Community 165 - "rest_timer_bar.dart"
Cohesion: 0.20
Nodes (7): build, cs, _fmt, label, onTap, _PillBtn, RestTimerBar

### Community 166 - "codex_search.dart"
Cohesion: 0.20
Nodes (7): hiddenGems, inBody, inTitle, q, searchCodex, browsableTopics, whatsNewTopics

### Community 167 - "home_blocks_dao.dart"
Cohesion: 0.20
Nodes (7): addBlock, deleteBlock, ensureSeeded, getBlocks, reorderBlocks, updateConfig, watchBlocks

### Community 168 - "home_block_type.dart"
Cohesion: 0.20
Nodes (6): defaults, done, icon, multiInstance, parse, title

### Community 169 - "app_colors.dart"
Cohesion: 0.20
Nodes (8): AppColors, darkBackground, darkElevated, darkSurface, lightBackground, lightSurface, seed, streakAmber

### Community 170 - "habits_table.dart"
Cohesion: 0.20
Nodes (9): archivedAt, createdAt, deletedAt, Habits, id, name, reminderEnabled, reminderTime (+1 more)

### Community 171 - "notebook_tile.dart"
Cohesion: 0.20
Nodes (9): build, color, count, icon, name, NotebookTile, onLongPress, onTap (+1 more)

### Community 172 - "work_shifts_table.dart"
Cohesion: 0.20
Nodes (9): date, endTime, id, rotationColor, rotationLabel, shiftType, startTime, uniqueKeys (+1 more)

### Community 173 - "whats_new_test.dart"
Cohesion: 0.22
Nodes (3): main, main, _t

### Community 174 - "backup_service.dart"
Cohesion: 0.22
Nodes (6): BackupService, _db, _deleteOrder, exportToJson, _formatVersion, importFromJson

### Community 175 - "codex_topic_screen.dart"
Cohesion: 0.25
Nodes (7): coachControllerProvider, initState, CodexTopic, _block, build, CodexTopicScreen, topic

### Community 176 - "Map"
Cohesion: 0.22
Nodes (6): computeSectionFold, counts, hidden, hiddenCountByHeadingId, hiddenIds, SectionFold

### Community 177 - "note_outline.dart"
Cohesion: 0.22
Nodes (7): blockDepths, depths, indentForInsertAfter, isHeading, kNoteIndentStep, lineStartsRtl, stack

### Community 178 - "weight_steps.dart"
Cohesion: 0.22
Nodes (8): down, _eps, kPlateStep, nextWeightDown, nextWeightUp, parseWeight, steps, tryParse

### Community 179 - "program_sessions_table.dart"
Cohesion: 0.22
Nodes (7): colorValue, id, name, orderIndex, programId, ProgramSessions, weekDays

### Community 180 - "note_arrange_view_test.dart"
Cohesion: 0.22
Nodes (7): _b, dragRow, indents, main, _note, order, pumpView

### Community 182 - "startup_tab.dart"
Cohesion: 0.25
Nodes (6): AppTab, effective, startupLocation, target, visible, wanted

### Community 183 - "bool get"
Cohesion: 0.25
Nodes (5): _, displayName, hasPr, totalSets, WorkoutSessionModel

### Community 184 - "tracker_item_model.dart"
Cohesion: 0.25
Nodes (5): FieldType, fromString, text, TrackerItemModel, value

### Community 185 - "coach_due.dart"
Cohesion: 0.25
Nodes (6): 0, compareVersions, dueTips, isNewSince, x, y

### Community 186 - "static const List"
Cohesion: 0.25
Nodes (4): build, _editDialog, _palette, RotationsEditorScreen

### Community 187 - "static const int"
Cohesion: 0.29
Nodes (4): build, _maxShown, NotesBlock, recentNotebooksProvider

### Community 188 - "Set"
Cohesion: 0.25
Nodes (6): checkedItemIds, colorValue, icon, name, trackerId, TrackerTodayStatus

### Community 189 - "weeklyScoreboard"
Cohesion: 0.25
Nodes (8): weekFreeDaysProvider, weeklyScoreboardProvider, weeklyTargetsProvider, weekFreeDays, weeklyScoreboard, weeklyTargets, weekSets, weekSetsProvider

### Community 190 - "_"
Cohesion: 0.29
Nodes (6): _, isRotating, isWeekly, nextRotatingSession, ProgramModel, todaysSessions

### Community 193 - "app_theme.dart"
Cohesion: 0.33
Nodes (4): AppTheme, _base, dark, light

### Community 194 - "package:riverpod_annotation/riverpod_annotation.dart"
Cohesion: 0.33
Nodes (3): appDatabase, appDatabaseProvider, db

### Community 195 - "_ArchivedScreenState"
Cohesion: 0.40
Nodes (5): archivedItemsProvider, deletedItemsProvider, ArchivedScreen, _ArchivedScreenState, build

### Community 196 - "_"
Cohesion: 0.33
Nodes (4): _, ExerciseModel, muscleGroup, secondaryMuscleList

### Community 197 - "_"
Cohesion: 0.33
Nodes (5): _, color, _dayLabels, isOnWeekday, ProgramSessionModel

### Community 198 - "drag_drop_test.dart"
Cohesion: 0.33
Nodes (4): _b, main, _note, _photo

### Community 199 - "widget_payload.dart"
Cohesion: 0.40
Nodes (4): argbToHex, hash, payloadChecksum, toRadixString

### Community 200 - "filteredExercises"
Cohesion: 0.50
Nodes (4): exerciseFilterProvider, filteredExercisesProvider, ExerciseFilter, filteredExercises

## Knowledge Gaps
- **2421 isolated node(s):** `_widgetChannel`, `_liveChannel`, `createState`, `initState`, `dispose` (+2416 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 2904 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **62 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `_`, `diagnostics_screen.dart`, `String get`, `text_block_view.dart`, `_`, `List`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **What connects `_widgetChannel`, `_liveChannel`, `createState` to the rest of the system?**
  _2421 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `workout_providers.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Why does `_` connect `_` to `package:flutter/material.dart`, `app_colors.dart`, `static const List`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Should `note_editor_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.041474654377880185 - nodes in this community are weakly interconnected._
- **Why does `AppDatabase` connect `AppDatabase` to `recently_deleted_test.dart`, `package:riverpod_annotation/riverpod_annotation.dart`, `_`, `live_background_callback.dart`, `archive_schema_test.dart`, `program_templates_test.dart`, `backup_service.dart`, `app_database.dart`, `WorkoutDao`, `note_task_linker_test.dart`, `HabitsDao`, `package:life_tracker/core/database/app_database.dart`, `home_blocks_dao_test.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Should `notification_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._