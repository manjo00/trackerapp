import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/settings_provider.dart';

/// App entry point.
///
/// We need to `await` several async platform APIs before [runApp]:
///   1. [SharedPreferences.getInstance()] — so [settingsProvider] has
///      access to persisted preferences on the very first frame.
///   2. [NotificationService.instance.init()] — registers the Android
///      notification channel and requests POST_NOTIFICATIONS permission.
///
/// [WidgetsFlutterBinding.ensureInitialized()] is required whenever you
/// call an async platform API before [runApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run both async inits in parallel — neither depends on the other.
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    NotificationService.instance.init(),
  ]);

  final SharedPreferences prefs = results[0] as SharedPreferences;

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
}
