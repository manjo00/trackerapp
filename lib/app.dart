import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the app.
///
/// Changed from [StatelessWidget] to [ConsumerWidget] so it can watch
/// [settingsProvider] and rebuild when the user changes the theme.
class LifeTrackerApp extends ConsumerWidget {
  const LifeTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds only when themeMode changes — very cheap.
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
