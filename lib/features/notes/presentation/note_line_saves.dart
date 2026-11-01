import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The note lines currently on screen, each with a way to save its latest
/// text.
///
/// A line writes itself to the database only when it loses focus (or on
/// Enter). Code that is about to read a note back — leaving the editor, which
/// prunes lines that look empty — calls [flushAll] first, so a line that was
/// typed but never left counts with what it shows, not with what was saved.
/// The provider also flushes whenever the app stops being in front, because
/// Android may close a backgrounded app without the line ever losing focus.
class NoteLineSaves {
  final Set<Future<void> Function()> _savers = {};

  void add(Future<void> Function() save) => _savers.add(save);

  void remove(Future<void> Function() save) => _savers.remove(save);

  /// Saves every registered line that has unsaved text. Each save starts
  /// right away (they read their text synchronously), then all are awaited.
  Future<void> flushAll() =>
      Future.wait([for (final save in List.of(_savers)) save()]);
}

final noteLineSavesProvider = Provider<NoteLineSaves>((ref) {
  final NoteLineSaves saves = NoteLineSaves();
  final AppLifecycleListener listener =
      AppLifecycleListener(onInactive: saves.flushAll);
  ref.onDispose(listener.dispose);
  return saves;
});
