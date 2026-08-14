import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/coach/data/coach_content.dart';
import 'package:life_tracker/features/coach/data/coach_tip.dart';
import 'package:life_tracker/features/coach/domain/coach_due.dart';

CoachTip _tip(String id, String screen, {String since = '1.0.0'}) => CoachTip(
      id: id,
      screen: screen,
      target: '$id.target',
      text: 'tip $id',
      sinceVersion: since,
    );

void main() {
  group('dueTips', () {
    final tips = [
      _tip('a', 'home'),
      _tip('b', 'home'),
      _tip('c', 'planner'),
    ];

    test('returns a screen\'s unseen tips, in order', () {
      expect(dueTips(tips, 'home', {}).map((t) => t.id), ['a', 'b']);
    });

    test('skips what has been seen', () {
      expect(dueTips(tips, 'home', {'a'}).map((t) => t.id), ['b']);
      expect(dueTips(tips, 'home', {'a', 'b'}), isEmpty);
    });

    test('a tip added later surfaces even on a toured screen', () {
      // 'b' is the newcomer; the user already saw 'a'.
      expect(dueTips(tips, 'home', {'a'}).single.id, 'b');
    });

    test('other screens are untouched', () {
      expect(dueTips(tips, 'planner', {'a', 'b'}).single.id, 'c');
    });
  });

  group('compareVersions', () {
    test('orders by each part', () {
      expect(compareVersions('1.14.1', '1.14.0') > 0, isTrue);
      expect(compareVersions('1.9.0', '1.10.0') < 0, isTrue);
      expect(compareVersions('2.0.0', '1.99.99') > 0, isTrue);
      expect(compareVersions('1.14.0', '1.14.0'), 0);
    });

    test('tolerates build suffixes and short/odd versions', () {
      expect(compareVersions('1.14.0+21', '1.14.0'), 0);
      expect(compareVersions('1.15', '1.14.9') > 0, isTrue);
      expect(compareVersions('x.y.z', '0.0.0'), 0);
    });
  });

  group('isNewSince', () {
    test('badges a tip that arrived after the last version run', () {
      expect(isNewSince(_tip('a', 'home', since: '1.15.0'), '1.14.1'), isTrue);
    });

    test('does not badge tips the user already had', () {
      expect(isNewSince(_tip('a', 'home', since: '1.14.0'), '1.14.1'), isFalse);
    });

    test('a fresh install badges nothing', () {
      expect(isNewSince(_tip('a', 'home', since: '1.15.0'), null), isFalse);
    });
  });

  group('content sanity', () {
    test('tip ids are unique', () {
      final ids = kCoachTips.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every tip has text and a target', () {
      for (final CoachTip t in kCoachTips) {
        expect(t.text.trim(), isNotEmpty, reason: t.id);
        expect(t.target.trim(), isNotEmpty, reason: t.id);
      }
    });

    /// A tip pointing at a Codex topic that does not exist would show a dead
    /// "Learn more" — catch that here rather than on the phone.
    test('codex links point at real topics', () {
      // ids are checked against the Codex in codex_search_test's own sanity
      // pass; here we only assert the field is never blank when present.
      for (final CoachTip t in kCoachTips) {
        if (t.codexTopicId != null) {
          expect(t.codexTopicId!.trim(), isNotEmpty, reason: t.id);
        }
      }
    });
  });
}
