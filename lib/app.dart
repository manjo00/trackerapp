import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_provider.dart';
import 'core/notifications/live_dashboard_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/update/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widget/home_widget_service.dart';
import 'features/habits/presentation/providers/habits_providers.dart';
import 'features/tasks/presentation/providers/tasks_providers.dart';
import 'features/trackers/presentation/providers/trackers_providers.dart';
import 'features/workout/presentation/providers/program_providers.dart';
import 'features/workout/presentation/providers/workout_providers.dart';

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
  /// Channel MainActivity uses to tell us a widget "+" was tapped while the
  /// app was already running (cold starts are handled by getInitialRoute).
  static const MethodChannel _widgetChannel = MethodChannel('uplan/widget');

  /// Same channel LiveDashboardService commands the native side on — here we
  /// handle the reverse direction: rest-timer buttons tapped on the Live
  /// Update notification (Now Bar) calling back into the Dart RestTimer.
  static const MethodChannel _liveChannel = MethodChannel('uplan/live');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Run rescheduleAll after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reschedule());
    _widgetChannel.setMethodCallHandler(_onWidgetMethod);
    _liveChannel.setMethodCallHandler(_onLiveMethod);
  }

  @override
  void dispose() {
    _widgetChannel.setMethodCallHandler(null);
    _liveChannel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _onWidgetMethod(MethodCall call) async {
    if (call.method == 'openQuickAdd') {
      // Replace (not push) so no opaque app screen sits behind the sheet —
      // the translucent window then shows the home screen through the scrim.
      appRouter.go('/quick-add');
    }
  }

  Future<void> _onLiveMethod(MethodCall call) async {
    switch (call.method) {
      case 'restAdd15':
        ref.read(restTimerProvider.notifier).addSeconds(15);
      case 'restSkip':
        ref.read(restTimerProvider.notifier).cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Always refresh on resume (this also covers resuming on a new day):
      // the live
      // notification's ✓/snooze buttons write through a separate background
      // DB connection, so this app's stream queries never hear about those
      // writes — re-subscribing picks them up. Cheap one-shot rebuilds.
      _refreshDateSensitiveProviders();
      _syncWidget();
    } else if (state == AppLifecycleState.paused) {
      // Backgrounded — refresh the home-screen widget with the latest state.
      _syncWidget();
    }
  }

  /// Pushes the current Today snapshot to the native home-screen widget,
  /// then re-renders the live dashboard notification from the same data.
  Future<void> _syncWidget() async {
    final db = ref.read(appDatabaseProvider);
    await HomeWidgetService.sync(db);
    await LiveDashboardService.syncCards(db);
  }

  /// Invalidates providers whose results are anchored to the current date or
  /// can change behind our back (live-notification background writes), so
  /// they re-subscribe with fresh queries.
  void _refreshDateSensitiveProviders() {
    ref.invalidate(habitsWithStatusProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(tasksDueTodayProvider);
    ref.invalidate(overdueTasksProvider);
    ref.invalidate(capturedTasksProvider);
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

    // Seed the home-screen widget with today's snapshot on launch, and
    // bring up the live dashboard notification if the user enabled it.
    final db = ref.read(appDatabaseProvider);
    await HomeWidgetService.sync(db);
    await LiveDashboardService.syncCards(db);

    // Quiet daily check for a newer APK on the releases repo.
    await _maybeOfferUpdate();
  }

  /// Auto update check (throttled to once/day inside the service). Shows a
  /// dialog only when a newer release exists; silent otherwise.
  Future<void> _maybeOfferUpdate() async {
    final UpdateInfo? update =
        await UpdateService.autoCheck(ref.read(sharedPreferencesProvider));
    if (update == null) return;

    // The dialog needs a context below the Navigator — use the router's.
    final BuildContext? context =
        appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update available — v${update.version}'),
        content: Text(
          '${(update.notes?.trim().isNotEmpty ?? false) ? '${update.notes!.trim()}\n\n' : ''}'
          'Downloads in your browser — open the file when done and Android '
          'will offer to install it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              UpdateService.download(update);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = ref.watch(settingsProvider).themeMode;

    return MaterialApp.router(
      title: 'Uplan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
