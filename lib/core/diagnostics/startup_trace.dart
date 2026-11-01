/// Start-up timing marks for speed checks.
///
/// Off unless the build passes `--dart-define=UPLAN_TRACE=true`; then each
/// [mark] prints one line to logcat (tag "flutter"):
/// `UPLAN_TRACE <label> <ms since the first mark>`.
/// The first mark is made at the top of `main()`, so the numbers read as
/// "milliseconds since Dart started".
class StartupTrace {
  StartupTrace._();

  static const bool enabled = bool.fromEnvironment('UPLAN_TRACE');

  // Lazily created on the first mark, which is the top of main().
  static final Stopwatch _clock = Stopwatch()..start();

  static void mark(String label) {
    if (!enabled) return;
    // ignore: avoid_print
    print('UPLAN_TRACE $label ${_clock.elapsedMilliseconds}');
  }
}
