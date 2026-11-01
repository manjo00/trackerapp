import 'dart:async';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/diagnostics/crash_log.dart';
import 'core/diagnostics/startup_trace.dart';
import 'core/notifications/live_background_callback.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/settings/startup_tab.dart';

/// App entry point.
///
/// We need to `await` several async platform APIs before [runApp]:
///   1. [SharedPreferences.getInstance()] — so [settingsProvider] has
///      access to persisted preferences on the very first frame.
///   2. [NotificationService.instance.init()] — registers the Android
///      notification channel and requests POST_NOTIFICATIONS permission.
///
/// The whole boot runs inside [runZonedGuarded] with error hooks feeding
/// [CrashLog], so crashes on testers' phones end up in a file they can
/// share from Settings → Diagnostics (we can't adb into their devices).
void main() {
  runZonedGuarded<Future<void>>(() async {
    StartupTrace.mark('main');
    // Must be inside the same zone as runApp.
    WidgetsFlutterBinding.ensureInitialized();

    // Widget-layer errors (build/layout/paint). Keep the default red-box
    // behaviour in debug; just also write it to the log.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      CrashLog.record(details.exception, details.stack, source: 'flutter');
    };

    // Uncaught async platform errors that never reach the zone below.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      CrashLog.record(error, stack, source: 'platform');
      return true;
    };

    // Background alarm scheduler — runs alarmNotificationCallback at the
    // exact scheduled time (even when the app is killed) to fire reminders
    // reliably. Measured 2026-11-01: moving this after the first frame gained
    // nothing (the next platform call waits for Android's busy main thread
    // instead) and turned its ~0.65 s of main-thread work into a visible freeze
    // after the first frame, so it stays here, before runApp.
    await AndroidAlarmManager.initialize();
    StartupTrace.mark('alarm_init');

    // Live-notification action buttons (✓/snooze) run liveBackgroundCallback
    // in a headless engine — registered here so it works with the app closed.
    await HomeWidget.registerInteractivityCallback(liveBackgroundCallback);
    StartupTrace.mark('widget_callback');

    // Run both async inits in parallel — neither depends on the other.
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      NotificationService.instance.init(),
    ]);
    StartupTrace.mark('prefs_and_notifications');

    final SharedPreferences prefs = results[0] as SharedPreferences;

    // Decide the launch tab BEFORE the router global is first touched —
    // GoRouter's initialLocation is fixed at construction time.
    appInitialLocation = startupLocation(
      storedTab: prefs.getString('startup_tab'),
      storedVisibleTabs: prefs.getStringList('visible_tabs'),
    );

    CrashLog.note('app start');

    StartupTrace.mark('run_app');
    WidgetsBinding.instance.waitUntilFirstFrameRasterized
        .then((_) => StartupTrace.mark('first_frame'));
    runApp(
      ProviderScope(
        overrides: [
          // Inject the live SharedPreferences instance so every provider
          // that watches sharedPreferencesProvider gets the real object.
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LifeTrackerApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    // Anything uncaught that escaped both hooks above.
    CrashLog.record(error, stack, source: 'zone');
  });
}
