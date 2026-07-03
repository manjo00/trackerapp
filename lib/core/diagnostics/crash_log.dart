import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Append-only diagnostics log so a tester can send us what went wrong
/// without a cable — errors land here, "Share diagnostics" ships the file.
///
/// Deliberately boring and defensive: every method swallows its own
/// failures (a logger that crashes the app it's diagnosing is worse than
/// no logger), and the file self-trims so it can't grow unbounded.
class CrashLog {
  const CrashLog._();

  static const String _fileName = 'uplan_diagnostics.log';

  /// Trim threshold — roughly a few hundred entries.
  static const int _maxBytes = 200 * 1024;

  /// How much of the stack trace is worth shipping per entry.
  static const int _stackLines = 25;

  static Future<File> _file() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Records a caught error/crash with a trimmed stack trace.
  /// [source] tags where the hook fired: flutter / platform / zone.
  static Future<void> record(
    Object error,
    StackTrace? stack, {
    String source = 'error',
  }) async {
    final String stackText = (stack ?? StackTrace.empty)
        .toString()
        .split('\n')
        .take(_stackLines)
        .join('\n');
    await _append('[$source] $error\n$stackText');
  }

  /// Records a one-line milestone (app start, sync done, ...) — cheap
  /// breadcrumbs that give crashes context.
  static Future<void> note(String message) => _append('[note] $message');

  static Future<void> _append(String entry) async {
    try {
      final File file = await _file();
      await file.writeAsString(
        '${DateTime.now().toIso8601String()} $entry\n\n',
        mode: FileMode.append,
        flush: true,
      );
      await _trimIfNeeded(file);
    } catch (_) {
      // Never let logging break the app.
    }
  }

  /// Halves the file once it outgrows [_maxBytes] (keeps the newest half).
  static Future<void> _trimIfNeeded(File file) async {
    try {
      if (await file.length() <= _maxBytes) return;
      final String content = await file.readAsString();
      await file.writeAsString(content.substring(content.length ~/ 2));
    } catch (_) {}
  }

  /// Full log content for the share sheet ('' when nothing recorded yet).
  static Future<String> read() async {
    try {
      final File file = await _file();
      if (!await file.exists()) return '';
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> clear() async {
    try {
      final File file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
