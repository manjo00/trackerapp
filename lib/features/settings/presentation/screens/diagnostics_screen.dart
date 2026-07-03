import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/diagnostics/crash_log.dart';
import '../../../../core/diagnostics/diagnostics_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../habits/presentation/providers/habits_providers.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../trackers/presentation/providers/trackers_providers.dart';

/// Self-service health screen for field testers: every background-work
/// permission as a ✓/✗ row with a Fix button, plus the notification test
/// tools. Designed so a single screenshot tells us what's wrong on a phone
/// we can't plug into.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with WidgetsBindingObserver {
  DiagnosticsReport? _report;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Fix buttons open system dialogs/settings — re-check when we come back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<void> _reload() async {
    final DiagnosticsReport report = await DiagnosticsService.collect();
    if (!mounted) return;
    setState(() => _report = report);
  }

  // ── Fix actions ───────────────────────────────────────────────────────────

  Future<void> _fixNotifications() async {
    await NotificationService.instance.requestNotifications();
    await _reload();
  }

  Future<void> _fixExactAlarms() async {
    await NotificationService.instance.requestExactAlarms();
    await _reload();
  }

  Future<void> _fixBattery() async {
    await DiagnosticsService.requestBatteryExemption();
    // Reload happens on resume (the request opens a system dialog).
  }

  /// Bundles the health report + captured error log into a text file and
  /// opens the share sheet — how a tester sends us what went wrong
  /// without a cable. Same temp-file + shareXFiles pattern as the backup
  /// export.
  Future<void> _shareDiagnostics() async {
    final DiagnosticsReport report =
        _report ?? await DiagnosticsService.collect();
    final String log = await CrashLog.read();

    final StringBuffer buffer = StringBuffer()
      ..writeln(report.toReportText())
      ..writeln('== Captured errors (newest last) ==')
      ..writeln(log.isEmpty ? '(none recorded)' : log);

    final Directory dir = await getTemporaryDirectory();
    final String stamp =
        DateTime.now().toIso8601String().replaceAll(':', '-');
    final File file = File('${dir.path}/uplan_diagnostics_$stamp.txt');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Uplan diagnostics',
    );
  }

  /// Re-requests exact alarms AND re-schedules every reminder — the big
  /// hammer when timed reminders stopped arriving.
  Future<void> _fixReminders() async {
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
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DiagnosticsReport? report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run checks',
            onPressed: _reload,
          ),
        ],
      ),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _Header(label: 'Health checks'),
                _CheckTile(
                  check: report.checks[0],
                  onFix: _fixNotifications,
                ),
                _CheckTile(
                  check: report.checks[1],
                  onFix: _fixExactAlarms,
                ),
                _CheckTile(
                  check: report.checks[2],
                  onFix: _fixBattery,
                ),
                // Live updates has no in-app fix — firmware-gated (see
                // subtitle) — so no Fix button.
                _CheckTile(check: report.checks[3]),

                const Divider(indent: 16, endIndent: 16, height: 32),

                // ── OEM guidance ─────────────────────────────────────────
                const _Header(label: 'If reminders still die'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Some phones kill background apps even with the checks '
                    'above green:\n'
                    '• Samsung (One UI): Settings → Battery → Background '
                    'usage limits → add Uplan to "Never sleeping apps".\n'
                    '• OnePlus (OxygenOS): Settings → Battery → Battery '
                    'optimization → Uplan → "Don\'t optimize", AND App '
                    'management → Uplan → allow Auto-launch.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(160),
                          height: 1.6,
                        ),
                  ),
                ),

                const Divider(indent: 16, endIndent: 16, height: 32),

                // ── Test tools (relocated from Settings) ─────────────────
                const _Header(label: 'Test tools'),
                ListTile(
                  leading: Icon(Icons.send_rounded, color: cs.primary),
                  title: const Text('Send test notification'),
                  subtitle: const Text('Fires right now'),
                  onTap: () async {
                    final ScaffoldMessengerState m =
                        ScaffoldMessenger.of(context);
                    await NotificationService.instance.showTestNotification();
                    m.showSnackBar(const SnackBar(
                      content: Text('Sent — check your status bar!'),
                      duration: Duration(seconds: 3),
                    ));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.timer_outlined, color: cs.primary),
                  title: const Text('Test scheduled reminder (1 min)'),
                  subtitle: const Text(
                      'Lock your phone and wait — confirms timed reminders'),
                  onTap: () async {
                    final ScaffoldMessengerState m =
                        ScaffoldMessenger.of(context);
                    await NotificationService.instance
                        .scheduleTestIn(const Duration(minutes: 1));
                    m.showSnackBar(const SnackBar(
                      content: Text('Scheduled — you can lock the phone ⏰'),
                    ));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.alarm_on_rounded, color: cs.primary),
                  title: const Text('Fix task reminders'),
                  subtitle: const Text(
                      'Allow exact alarms and re-schedule everything'),
                  onTap: _fixReminders,
                ),

                const Divider(indent: 16, endIndent: 16, height: 32),

                // ── Share with the developer ─────────────────────────────
                const _Header(label: 'Report a problem'),
                ListTile(
                  leading: Icon(Icons.ios_share_rounded, color: cs.primary),
                  title: const Text('Share diagnostics'),
                  subtitle: const Text(
                      'Sends this health report + any captured errors as a '
                      'file — WhatsApp it to the developer'),
                  onTap: _shareDiagnostics,
                ),

                const Divider(indent: 16, endIndent: 16, height: 32),

                // ── Device block ─────────────────────────────────────────
                const _Header(label: 'Device'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    'Uplan ${report.appVersion}\n'
                    '${report.deviceModel}\n${report.osVersion}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withAlpha(160),
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One ✓/✗ health row; shows a Fix button only when failing and fixable.
class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.check, this.onFix});

  final DiagnosticCheck check;
  final Future<void> Function()? onFix;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        check.ok ? Icons.check_circle_rounded : Icons.error_rounded,
        color: check.ok ? Colors.green : cs.error,
      ),
      title: Text(check.title),
      subtitle: Text(check.subtitle),
      trailing: (!check.ok && onFix != null)
          ? TextButton(onPressed: () => onFix!(), child: const Text('Fix'))
          : null,
      isThreeLine: !check.ok,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
