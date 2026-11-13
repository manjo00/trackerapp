import 'package:flutter/services.dart';

/// What the du'a counter feels like in the hand: a light tick on each tap,
/// and a strong double buzz when a du'a's count is reached, so Ahmed can
/// count without looking at the screen (2026-11-13).
class AdhkarHaptics {
  const AdhkarHaptics();

  /// Uplan's own channel to the phone's vibrator (UplanHaptics.kt).
  static const MethodChannel _channel = MethodChannel('uplan/haptics');

  /// Buzz, pause, buzz: on and off times in milliseconds.
  static const List<int> finishedPattern = [0, 350, 150, 350];

  /// A light tick for each tap. It follows the phone's touch-feedback
  /// setting, so it is quiet when he has that switched off.
  Future<void> tick() => HapticFeedback.lightImpact();

  /// The strong buzz when a du'a is finished. The vibrator itself, not the
  /// short touch feedback, so it comes through whatever that setting is;
  /// falls back to the strongest touch feedback if the channel is missing.
  Future<void> finished() async {
    try {
      await _channel.invokeMethod<void>(
          'buzz', <String, Object>{'timings': finishedPattern});
    } on MissingPluginException {
      await HapticFeedback.heavyImpact();
    } on PlatformException {
      await HapticFeedback.heavyImpact();
    }
  }
}
