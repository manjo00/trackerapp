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
  });
}
