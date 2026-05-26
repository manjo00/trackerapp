import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the app.
///
/// Right now it uses a temporary [home] placeholder so we can verify the
/// theme compiles and looks right before wiring up the real router.
/// We'll replace [MaterialApp] with [MaterialApp.router] in Step 8.
class LifeTrackerApp extends StatelessWidget {
  const LifeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Tracker',
      debugShowCheckedModeBanner: false,

      // Light and dark themes — Flutter picks the right one based on the
      // system setting (Settings → Display → Dark mode).
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system, // follows the device's dark/light toggle

      // Temporary home — will be replaced by MaterialApp.router in Step 8.
      home: const _ThemePreview(),
    );
  }
}

/// Temporary screen so we can visually verify the theme before building
/// the real screens.  Deleted in Step 8.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Life Tracker — theme preview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: cs.primary),
                    const SizedBox(width: 12),
                    const Text('Habit card preview'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {},
              child: const Text('Primary button'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
