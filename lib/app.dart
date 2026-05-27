import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/habits/presentation/providers/habits_providers.dart';
import 'features/tasks/presentation/providers/tasks_providers.dart';
import 'features/trackers/presentation/providers/trackers_providers.dart';

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

class _LifeTrackerAppState extends ConsumerState<LifeTrackerApp> {
  @override
  void initState() {
    super.initState();
    // Run rescheduleAll after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());
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
