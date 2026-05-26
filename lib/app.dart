import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the app.
///
/// [MaterialApp.router] delegates all navigation to [appRouter] (go_router).
/// The router decides which screen to show based on the current URL-like path.
class LifeTrackerApp extends StatelessWidget {
  const LifeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Life Tracker',
      debugShowCheckedModeBanner: false,

      // System-following dark / light theme.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // Hand all routing to go_router.
      routerConfig: appRouter,
    );
  }
}
