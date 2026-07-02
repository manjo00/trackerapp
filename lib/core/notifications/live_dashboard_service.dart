import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Flutter-side remote control for the persistent "Live dashboard"
/// notification (native LiveDashboardService.kt).
///
/// The native side owns the notification; this class only (a) commands it
/// over the `uplan/live` MethodChannel and (b) stores the user's on/off
/// preference in the same store the native side reads
/// (HomeWidgetPreferences, via the home_widget plugin).
class LiveDashboardService {
  const LiveDashboardService._();

  static const MethodChannel _channel = MethodChannel('uplan/live');

  /// Prefs key — read by the settings screen and the launch/resume hooks.
  static const String _enabledKey = 'live_enabled';

  /// Whether the user has turned the live notification on.
  static Future<bool> isEnabled() async =>
      await HomeWidget.getWidgetData<bool>(_enabledKey) ?? false;

  /// Persists the toggle and starts/stops the native service to match.
  static Future<void> setEnabled(bool enabled) async {
    await HomeWidget.saveWidgetData<bool>(_enabledKey, enabled);
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  /// Starts (or re-shows) the dashboard notification.
  static Future<void> start() => _invoke('startDashboard');

  /// Removes the dashboard notification and stops the service.
  static Future<void> stop() => _invoke('stopDashboard');

  /// Asks the service to re-read prefs and re-render the card.
  static Future<void> refresh() => _invoke('refreshDashboard');

  /// Convenience for launch/resume hooks: start only if the user opted in.
  static Future<void> startIfEnabled() async {
    if (await isEnabled()) await start();
  }

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Non-Android platform or channel not registered (e.g. tests) — the
      // dashboard simply doesn't exist there.
    } on PlatformException {
      // Native failure shouldn't break app flows (saves, navigation, ...).
    }
  }
}
