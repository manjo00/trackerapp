import 'package:flutter/material.dart';

import '../../../../core/notifications/live_dashboard_service.dart';

/// Settings for the persistent "Live notification" dashboard.
///
/// v1: a master on/off switch. Later phases add card selection, snooze
/// behaviour, and slideshow options — same incremental pattern as the
/// widget-appearance screen.
class LiveNotificationSettingsScreen extends StatefulWidget {
  const LiveNotificationSettingsScreen({super.key});

  @override
  State<LiveNotificationSettingsScreen> createState() =>
      _LiveNotificationSettingsScreenState();
}

class _LiveNotificationSettingsScreenState
    extends State<LiveNotificationSettingsScreen> {
  bool _enabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool enabled = await LiveDashboardService.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await LiveDashboardService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Live notification')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  secondary: Icon(
                    _enabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: _enabled
                        ? cs.primary
                        : cs.onSurface.withAlpha(100),
                  ),
                  title: const Text('Show live dashboard'),
                  subtitle: const Text(
                    'Persistent notification with your day at a glance',
                  ),
                  value: _enabled,
                  onChanged: _toggle,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'A silent, always-there notification showing today\'s '
                    'habits, tasks and shift. It can\'t be swiped away — '
                    'turn it off here instead. More cards (task slideshow, '
                    'workout timer) arrive in the next updates.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(140),
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
