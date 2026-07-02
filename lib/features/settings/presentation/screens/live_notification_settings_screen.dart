import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

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

  /// What the notification's Snooze button does — read by the background
  /// action callback (live_background_callback.dart).
  String _snoozeMode = 'hide1h';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool enabled = await LiveDashboardService.isEnabled();
    final String mode =
        await HomeWidget.getWidgetData<String>('live_snooze_mode') ?? 'hide1h';
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _snoozeMode = mode;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await LiveDashboardService.setEnabled(value);
  }

  Future<void> _setSnoozeMode(String? mode) async {
    if (mode == null) return;
    setState(() => _snoozeMode = mode);
    await HomeWidget.saveWidgetData<String>('live_snooze_mode', mode);
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
                    'habits, tasks and shift as a pageable slideshow with '
                    '✓/snooze buttons. It comes back if swiped — turn it '
                    'off here instead. During workouts it becomes the '
                    'session timer, and rest timers appear as their own '
                    'live countdown.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(140),
                          height: 1.5,
                        ),
                  ),
                ),

                const Divider(indent: 16, endIndent: 16, height: 32),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'SNOOZE BUTTON',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                  ),
                ),
                RadioGroup<String>(
                  groupValue: _snoozeMode,
                  onChanged: _setSnoozeMode,
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'hide1h',
                        title: Text('Hide for 1 hour'),
                        subtitle: Text(
                            'Card leaves the slideshow and comes back later '
                            '— the task itself is untouched'),
                      ),
                      RadioListTile<String>(
                        value: 'tomorrow',
                        title: Text('Push to tomorrow'),
                        subtitle: Text(
                            'Moves the task\'s due date to tomorrow '
                            '(habits just hide until midnight)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
