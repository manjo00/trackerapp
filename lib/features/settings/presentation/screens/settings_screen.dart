import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/backup/backup_service.dart';
import '../../../../../core/database/database_provider.dart';
import '../../../../../core/notifications/notification_service.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/settings/settings_provider.dart';
import '../../../habits/presentation/providers/habits_providers.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../trackers/presentation/providers/trackers_providers.dart';
import 'live_notification_settings_screen.dart';
import 'widget_settings_screen.dart';

/// App settings screen.
///
/// Sections:
///   1. Appearance — Light / System / Dark theme.
///   2. Notifications — daily reminder toggle + time picker.
///   3. Navigation tabs — toggle which tabs appear in the bottom bar.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          const _SectionHeader(label: 'Appearance'),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withAlpha(160),
                      ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    notifier.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Notifications ──────────────────────────────────────────────
          const _SectionHeader(label: 'Notifications'),

          SwitchListTile(
            secondary: Icon(
              Icons.notifications_rounded,
              color: settings.notificationsEnabled
                  ? cs.primary
                  : cs.onSurface.withAlpha(100),
            ),
            title: const Text('Daily reminder'),
            subtitle: const Text('A nudge to check your habits and tasks'),
            value: settings.notificationsEnabled,
            onChanged: (bool value) =>
                notifier.setNotificationsEnabled(value),
          ),

          // Time picker row — only shown when notifications are enabled.
          if (settings.notificationsEnabled)
            _ReminderTimeTile(
              time: settings.reminderTime,
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: settings.reminderTime,
                );
                if (picked != null) {
                  notifier.setReminderTime(picked);
                }
              },
            ),

          // Test button — fires a notification immediately so the user can
          // verify that permission is granted and the channel is working.
          ListTile(
            leading: Icon(
              Icons.send_rounded,
              color: cs.primary,
            ),
            title: const Text('Send test notification'),
            subtitle: const Text(
                'Fires right now — use this to confirm notifications work'),
            onTap: () async {
              await NotificationService.instance.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent — check your status bar!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),

          // Scheduled-notification self-test (uses the same path as task
          // reminders) so the user can confirm timed reminders fire.
          ListTile(
            leading: Icon(Icons.timer_outlined, color: cs.primary),
            title: const Text('Test scheduled reminder (1 min)'),
            subtitle: const Text(
                'Fires in 1 minute — lock your phone and wait to confirm'),
            onTap: () async {
              final ScaffoldMessengerState m = ScaffoldMessenger.of(context);
              await NotificationService.instance
                  .scheduleTestIn(const Duration(minutes: 1));
              m.showSnackBar(const SnackBar(
                content: Text('Scheduled — you can lock the phone now ⏰'),
              ));
            },
          ),

          // Exact-alarm fix — task/time reminders need exact alarms on
          // Android 13+; without them they fall back to inexact alarms that
          // Samsung/aggressive battery managers drop.
          ListTile(
            leading: Icon(Icons.alarm_on_rounded, color: cs.primary),
            title: const Text('Fix task reminders'),
            subtitle: const Text(
                'If timed task reminders don\'t arrive, tap to allow exact '
                'alarms and re-schedule'),
            onTap: () => _fixReminders(context, ref),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Data / backup ──────────────────────────────────────────────
          const _SectionHeader(label: 'Data'),

          ListTile(
            leading: Icon(Icons.upload_file_rounded, color: cs.primary),
            title: const Text('Export data'),
            subtitle: const Text(
                'Save a backup file (share to Drive, email, etc.)'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.download_rounded, color: cs.primary),
            title: const Text('Import data'),
            subtitle: const Text('Restore from a backup file — replaces all data'),
            onTap: () => _importData(context, ref),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Home-screen widget ─────────────────────────────────────────
          const _SectionHeader(label: 'Home-screen widget'),

          ListTile(
            leading: Icon(Icons.widgets_rounded, color: cs.primary),
            title: const Text('Widget appearance'),
            subtitle:
                const Text('Background colour and transparency'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WidgetSettingsScreen(),
              ),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Live notification ──────────────────────────────────────────
          const _SectionHeader(label: 'Live notification'),

          ListTile(
            leading: Icon(Icons.notifications_paused_rounded,
                color: cs.primary),
            title: const Text('Live notification'),
            subtitle: const Text(
                'Persistent dashboard in the notification shade'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LiveNotificationSettingsScreen(),
              ),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Navigation tabs ────────────────────────────────────────────
          const _SectionHeader(label: 'Navigation tabs'),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Choose which tabs appear in the bottom bar. '
              'At least one must stay on.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(140),
                    height: 1.5,
                  ),
            ),
          ),

          for (final AppTab tab in AppTab.values)
            _TabToggleTile(
              tab: tab,
              isVisible: settings.visibleTabs.contains(tab),
              isLastVisible: settings.visibleTabs.length == 1 &&
                  settings.visibleTabs.contains(tab),
              onChanged: (bool value) =>
                  notifier.setTabVisible(tab, visible: value),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Reminder fix ──────────────────────────────────────────────────────────

  /// Requests the exact-alarm permission, then re-schedules every reminder so
  /// existing ones switch from inexact to exact alarms.
  Future<void> _fixReminders(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool ok = await NotificationService.instance.requestExactAlarms();

    final habits = await ref.read(habitsRepositoryProvider).getAllHabits();
    final tasks = await ref.read(tasksRepositoryProvider).getAllTasks();
    final trackers =
        await ref.read(trackersRepositoryProvider).getAllTrackers();
    await NotificationService.instance.rescheduleAll(
      habits: habits,
      tasks: tasks,
      trackers: trackers,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Exact alarms enabled — reminders re-scheduled ✅'
            : 'Still blocked. Enable "Alarms & reminders" for Uplan in '
                'Android Settings → Apps → Special access.'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Backup handlers ───────────────────────────────────────────────────────

  /// Serialises the database to JSON, writes a temp file, and opens the share
  /// sheet so the user can save it anywhere (Google Drive, email, etc.).
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String json =
          await BackupService(ref.read(appDatabaseProvider)).exportToJson();
      final Directory dir = await getTemporaryDirectory();
      final String stamp = DateTime.now()
          .toIso8601String()
          .split('.')
          .first
          .replaceAll(':', '-');
      final File file =
          File('${dir.path}/life_tracker_backup_$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Life Tracker backup',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  /// Confirms, lets the user pick a backup file, then replaces all data.
  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // Capture before any await so we don't use context across an async gap.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This replaces ALL current habits, tasks, trackers, workouts and '
          'shifts with the contents of the backup file. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Backup (JSON)',
      extensions: ['json'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    try {
      final String content = await file.readAsString();
      await BackupService(ref.read(appDatabaseProvider))
          .importFromJson(content);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Backup restored. Restart the app if anything looks off.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }
}

// ── Reminder time tile ────────────────────────────────────────────────────────

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  String _formatTime(TimeOfDay t) {
    final int hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final String minute = t.minute.toString().padLeft(2, '0');
    final String period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time_rounded),
      title: const Text('Reminder time'),
      trailing: Text(
        _formatTime(time),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
      onTap: onTap,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

// ── Tab toggle tile ───────────────────────────────────────────────────────────

class _TabToggleTile extends StatelessWidget {
  const _TabToggleTile({
    required this.tab,
    required this.isVisible,
    required this.isLastVisible,
    required this.onChanged,
  });

  final AppTab tab;
  final bool isVisible;
  final bool isLastVisible;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Icon(
        isVisible ? tab.selectedIcon : tab.icon,
        color: isVisible ? cs.primary : cs.onSurface.withAlpha(100),
      ),
      title: Text(tab.label),
      subtitle: isLastVisible
          ? Text(
              'Cannot hide the last tab',
              style: TextStyle(
                fontSize: 12,
                color: cs.error.withAlpha(180),
              ),
            )
          : null,
      value: isVisible,
      onChanged: isLastVisible ? null : onChanged,
    );
  }
}
