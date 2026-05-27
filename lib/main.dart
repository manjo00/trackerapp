import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/settings/settings_provider.dart';

/// App entry point.
///
/// We need to `await` [SharedPreferences.getInstance()] before [runApp]
/// so that [settingsProvider] has access to preferences on the very first
/// frame — no loading splash needed.
///
/// [WidgetsFlutterBinding.ensureInitialized()] is required whenever you
/// call an async platform API before [runApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

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
