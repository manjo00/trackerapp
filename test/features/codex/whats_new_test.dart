import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/codex/data/codex_content.dart';
import 'package:life_tracker/features/codex/data/codex_topic.dart';
import 'package:life_tracker/features/codex/data/release_notes.dart';
import 'package:life_tracker/features/codex/domain/whats_new.dart';

CodexTopic _t(String id, {String? since}) => CodexTopic(
      id: id,
      title: id,
      category: CodexCategory.basics,
      summary: 's',
      body: const [CodexBlock.p('b')],
      sinceVersion: since,
    );

void main() {
  group('whats new shelf', () {
    final topics = [
      _t('old'),
      _t('new1', since: '2.0.0'),
      _t('older', since: '1.0.0'),
    ];

    test('collects only topics from the given release', () {
      expect(whatsNewTopics(topics, '2.0.0').map((t) => t.id), ['new1']);
    });

    test('browsing excludes what is currently new', () {
      expect(browsableTopics(topics, '2.0.0').map((t) => t.id),
          ['old', 'older']);
    });

    test('when the release moves on, new topics rejoin their area', () {
      // Same data, a later release: nothing is "new", everything browsable.
      expect(whatsNewTopics(topics, '3.0.0'), isEmpty);
      expect(browsableTopics(topics, '3.0.0').length, topics.length);
    });
  });

  group('this release', () {
    test('has highlights for the popup', () {
      expect(kReleaseHighlights, isNotEmpty);
      for (final String h in kReleaseHighlights) {
        expect(h.trim(), isNotEmpty);
      }
    });

    test('tags at least one Codex topic, so the shelf is not empty', () {
      expect(whatsNewTopics(kCodexTopics, kCurrentRelease), isNotEmpty,
          reason: 'tag new/changed topics with sinceVersion: kCurrentRelease');
    });

    test('every tagged topic still lives in a real category', () {
      for (final CodexTopic t in whatsNewTopics(kCodexTopics, kCurrentRelease)) {
        expect(CodexCategory.values, contains(t.category), reason: t.id);
      }
    });
  });
}
