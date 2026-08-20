import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/codex/data/codex_content.dart';
import 'package:life_tracker/features/codex/data/codex_topic.dart';
import 'package:life_tracker/features/codex/domain/codex_search.dart';

void main() {
  group('searchCodex', () {
    test('an empty query returns everything', () {
      expect(searchCodex(kCodexTopics, '   ').length, kCodexTopics.length);
    });

    test('finds a topic by its title, ignoring case', () {
      final hits = searchCodex(kCodexTopics, 'REST TIMER');
      expect(hits.first.id, 'workout-rest');
    });

    test('finds a topic by body text', () {
      final hits = searchCodex(kCodexTopics, 'take bloods');
      expect(hits.map((t) => t.id), contains('notes-time-tasks'));
    });

    test('keywords catch words that never appear in the text', () {
      // "auto time placing" is how the user describes the @time feature.
      final hits = searchCodex(kCodexTopics, 'auto time placing');
      expect(hits.first.id, 'notes-time-tasks');
    });

    test('title matches rank above body-only matches', () {
      final hits = searchCodex(kCodexTopics, 'template');
      expect(hits.first.title.toLowerCase(), contains('template'));
    });

    test('an unmatched query returns nothing', () {
      expect(searchCodex(kCodexTopics, 'zzzz nonexistent'), isEmpty);
    });
  });

  group('content sanity', () {
    test('ids are unique', () {
      final ids = kCodexTopics.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every topic has a summary and a body', () {
      for (final CodexTopic t in kCodexTopics) {
        expect(t.summary.trim(), isNotEmpty, reason: t.id);
        expect(t.body, isNotEmpty, reason: t.id);
      }
    });

    test('every category has at least one topic', () {
      for (final CodexCategory c in CodexCategory.values) {
        expect(kCodexTopics.where((t) => t.category == c), isNotEmpty,
            reason: c.name);
      }
    });

    test('the hidden gems shelf is populated', () {
      expect(hiddenGems(kCodexTopics).length, greaterThanOrEqualTo(8));
    });

    /// The whole point of the Codex is the non-obvious stuff. Every gesture
    /// the app implements should be findable by searching for it — if a new
    /// gesture is added without a Codex line, this fails.
    test('every gesture in the app is documented somewhere', () {
      const Map<String, String> gestures = {
        'hold any line to lift it': 'notes: drag in arrange mode',
        'backspace on an empty line': 'notes: delete a line',
        'swipe left': 'tasks/habits: archive or delete',
        'long-press': 'tiles: edit / delete / drag',
        'hold it over that heading': 'notes: nest while dragging',
        'holding one opens the task editor': 'calendars: add a task on a day',
        'tap the "previous" hint': 'workout: copy last session',
        'long-press a set row': 'workout: delete a set',
        'seven times': 'drawer: developer mode',
        'chevron': 'home: fold a block',
        'pinched to zoom': 'photos: full-screen zoom',
        'drag the handle': 'workout: reorder exercises',
        'tap a day on the widget': 'home-screen widget: open that date',
        'swipe a tracker card': 'trackers: delete',
        'swipe left — delete the habit': 'habits: delete',
        'long-press — open it for editing': 'habits: edit',
      };
      final String all = kCodexTopics
          .expand((t) => t.body.map((b) => b.text))
          .join(' ')
          .toLowerCase();
      for (final MapEntry<String, String> g in gestures.entries) {
        expect(all, contains(g.key.toLowerCase()), reason: g.value);
      }
    });
  });
}
