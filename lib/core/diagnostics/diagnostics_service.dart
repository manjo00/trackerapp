import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../notifications/live_dashboard_service.dart';
import '../notifications/notification_service.dart';

/// One health check shown as a ✓/✗ row on the diagnostics screen.
class DiagnosticCheck {
  const DiagnosticCheck({
    required this.title,
    required this.ok,
    required this.okText,
    required this.failText,
  });

  final String title;
  final bool ok;
  final String okText;
  final String failText;

  String get subtitle => ok ? okText : failText;
}

/// Snapshot of everything a tester's screenshot needs to tell us:
/// permission states + device identity + app version.
class DiagnosticsReport {
  const DiagnosticsReport({
    required this.notificationsEnabled,
    required this.exactAlarms,
    required this.batteryExempt,
    required this.liveUpdates,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });

  final bool notificationsEnabled;
  final bool exactAlarms;
  final bool batteryExempt;
  final bool liveUpdates;
  final String deviceModel;
  final String osVersion;
  final String appVersion;

  List<DiagnosticCheck> get checks => [
        DiagnosticCheck(
          title: 'Notifications allowed',
          ok: notificationsEnabled,
          okText: 'Uplan can post notifications',
          failText: 'Blocked — reminders and the dashboard can\'t appear',
        ),
        DiagnosticCheck(
          title: 'Exact alarms',
          ok: exactAlarms,
          okText: 'Timed reminders fire at the exact minute',
          failText: 'Blocked — reminders may arrive late or never',
        ),
        DiagnosticCheck(
          title: 'Battery unrestricted',
          ok: batteryExempt,
          okText: 'The system won\'t kill Uplan in the background',
          failText: 'Restricted — the phone may silently kill reminders '
              'and the live notification',
        ),
        DiagnosticCheck(
          title: 'Live updates (Now Bar)',
          ok: liveUpdates,
          okText: 'Rest timer can appear on the Now Bar / lock screen',
          failText: 'Not granted by this phone\'s firmware — rest timer '
              'shows as a normal notification instead (not a bug)',
        ),
      ];

  /// Plain-text block for the shareable diagnostics file.
  String toReportText() => '''
== Uplan diagnostics ==
App version:   $appVersion
Device:        $deviceModel
Android:       $osVersion
Notifications: ${notificationsEnabled ? 'OK' : 'BLOCKED'}
Exact alarms:  ${exactAlarms ? 'OK' : 'BLOCKED'}
Battery:       ${batteryExempt ? 'unrestricted' : 'RESTRICTED'}
Live updates:  ${liveUpdates ? 'granted' : 'not granted'}
''';
}

/// Collects permission/health state for the diagnostics screen. Read-only —
/// the per-row Fix buttons call the existing request methods directly.
class DiagnosticsService {
  const DiagnosticsService._();

  /// Same channel MainActivity serves (battery methods live beside the
  /// live-dashboard handlers to avoid a second channel).
  static const MethodChannel _channel = MethodChannel('uplan/live');

  static Future<DiagnosticsReport> collect() async {
    final bool notifications =
        await NotificationService.instance.areNotificationsEnabled();
    // Read-only — must never pop a permission dialog during a passive check.
    final bool exact = await NotificationService.instance.checkExactAlarms();
    final bool battery = await isBatteryExempt();
    final bool live = await LiveDashboardService.canPromote();

    String model = 'unknown';
    String os = 'unknown';
    try {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      model = '${info.manufacturer} ${info.model}';
      os = 'Android ${info.version.release} (API ${info.version.sdkInt})';
    } catch (_) {
      // Non-Android or plugin failure — report stays "unknown".
    }

    String version = 'unknown';
    try {
      final PackageInfo pkg = await PackageInfo.fromPlatform();
      version = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {}

    return DiagnosticsReport(
      notificationsEnabled: notifications,
      exactAlarms: exact,
      batteryExempt: battery,
      liveUpdates: live,
      deviceModel: model,
      osVersion: os,
      appVersion: version,
    );
  }

  /// Whether the app is exempt from battery optimization (Doze whitelisting).
  static Future<bool> isBatteryExempt() async {
    try {
      return await _channel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system "Allow Uplan to run in background?" dialog.
  static Future<void> requestBatteryExemption() async {
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } on MissingPluginException {
      // Non-Android — nothing to request.
    } on PlatformException {
      // Dialog failed to open; the guidance card covers the manual path.
    }
  }
}
