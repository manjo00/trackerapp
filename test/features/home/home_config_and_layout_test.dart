import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/home/data/home_block_config.dart';
import 'package:life_tracker/features/home/data/home_layout.dart';

void main() {
  group('mergeConfig', () {
    test('adds keys to empty/null config', () {
      final String json = mergeConfig(null, {'limit': 5});
      expect(limitFromConfig(json), 5);
    });

    test('updates without clobbering other keys', () {
      String json = listConfig(3);
      json = mergeConfig(json, {'limit': 5, 'hideWhenEmpty': true});
      json = mergeConfig(json, {'limit': 10});
      expect(listIdFromConfig(json), 3);
      expect(limitFromConfig(json), 10);
      expect(hideWhenEmptyFromConfig(json), isTrue);
    });

    test('a null value removes its key (back to default)', () {
      String json = mergeConfig(null, {'limit': 5});
      json = mergeConfig(json, {'limit': null});
      expect(limitFromConfig(json), isNull);
    });

    test('survives malformed input', () {
      final String json = mergeConfig('not json', {'days': 3});
      expect(daysFromConfig(json), 3);
    });
  });

  group('typed readers', () {
    test('list/label ids read back; wrong types → null', () {
      expect(listIdFromConfig(listConfig(7)), 7);
      expect(labelIdFromConfig(labelConfig(2)), 2);
      expect(listIdFromConfig('{"listId":"x"}'), isNull);
      expect(collapsedFromConfig(mergeConfig(null, {'collapsed': true})),
          isTrue);
      expect(collapsedFromConfig(null), isFalse);
    });
  });

  group('distributeRoundRobin', () {
    test('round-robins in order across columns', () {
      expect(distributeRoundRobin([1, 2, 3, 4, 5], 2), [
        [1, 3, 5],
        [2, 4],
      ]);
      expect(distributeRoundRobin([1, 2, 3, 4, 5, 6, 7], 3), [
        [1, 4, 7],
        [2, 5],
        [3, 6],
      ]);
    });

    test('one column (or fewer) passes through', () {
      expect(distributeRoundRobin([1, 2, 3], 1), [
        [1, 2, 3]
      ]);
      expect(distributeRoundRobin([1, 2, 3], 0), [
        [1, 2, 3]
      ]);
    });

    test('empty input yields empty columns', () {
      expect(distributeRoundRobin(<int>[], 2), [<int>[], <int>[]]);
    });
  });
}
