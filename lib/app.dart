import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/habits/presentation/providers/habits_providers.dart';
import 'features/tasks/presentation/providers/tasks_providers.dart';
import 'features/trackers/presentation/providers/trackers_providers.dart';
import 'features/workout/presentation/providers/program_providers.dart';

/// Root widget of the app.
///
/// Uses [ConsumerStatefulWidget] to:
///   1. Watch [settingsProvider] for theme changes.
///   2. Run [rescheduleAll] once after startup so any notifications that
///      the OS cleared (e.g. after a device reboot) are re-registered.
class LifeTrackerApp extends ConsumerStatefulWidget {
  const LifeTrackerApp({super.key});

  @override
  ConsumerState<LifeTrackerApp> createState() => _LifeTrackerAppState();
}

class _LifeTrackerAppState extends ConsumerState<LifeTrackerApp>
    with WidgetsBindingObserver {
  /// The calendar day the date-sensitive data was last built for. Used to
  /// detect "the app was resumed on a new day" so Today/streaks don't get
  /// stuck showing yesterday.
  DateTime _lastActiveDay = _dayOf(DateTime.now());

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Run rescheduleAll after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final DateTime today = _dayOf(DateTime.now());
    if (today != _lastActiveDay) {
      // Resumed on a new day — rebuild everything that depends on "today".
      _lastActiveDay = today;
      _refreshDateSensitiveProviders();
    }
  }

  /// Invalidates providers whose results are anchored to the current date, so
  /// they recompute against the new day. Cheap — only fires on a day change.
  void _refreshDateSensitiveProviders() {
    ref.invalidate(habitsWithStatusProvider);
    ref.invalidate(tasksDueTodayProvider);
    ref.invalidate(overdueTasksProvider);
    ref.invalidate(checklistTrackersForTodayProvider);
    ref.invalidate(trackersWithProgressProvider);
    ref.invalidate(todaysSuggestedSessionProvider);
  }

  Future<void> _reschedule() async {
    // Fetch current data from each repository.  We use .read (not .watch)
    // because this is a one-shot call, not a reactive subscription.
    final habitsRepo = ref.read(habitsRepositoryProvider);
    final tasksRepo = ref.read(tasksRepositoryProvider);
    final trackersRepo = ref.read(trackersRepositoryProvider);

    final habits = await habitsRepo.getAllHabits();
    final tasks = await tasksRepo.getAllTasks();
    final trackers = await trackersRepo.getAllTrackers();

    await NotificationService.instance.rescheduleAll(
      habits: habits,
      tasks: tasks,
      trackers: trackers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(settingsProvider).themeMode;

    return MaterialApp.router(
      title: 'Life Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
