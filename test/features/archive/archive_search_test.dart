import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/archive/domain/archive_search.dart';
import 'package:life_tracker/features/archive/domain/archive_service.dart';
import 'package:life_tracker/features/archive/domain/archived_item.dart';

/// Pure tests — no database. These cover the two decisions that make the
/// Archive screen behave: what a search matches, and where a restore puts
/// something back.
void main() {
  const ArchivedItem shoppingList = ArchivedItem(
    kind: ArchivedKind.list,
    id: 1,
    title: 'Shopping',
    body: 'Milk\nBread\nCall the landlord',
  );
  const ArchivedItem weekendNote = ArchivedItem(
    kind: ArchivedKind.note,
    id: 2,
    title: 'Weekend plans',
    body: 'Book the campsite\nBring the shopping bags',
  );
  const ArchivedItem gymHabit =
      ArchivedItem(kind: ArchivedKind.habit, id: 3, title: 'Gym');
  const List<ArchivedItem> all = [shoppingList, weekendNote, gymHabit];

  group('searchArchive', () {
    test('empty query returns everything untouched', () {
      expect(searchArchive(all, '   '), all);
    });

    test('matches inside the contents, not only the title', () {
      // "campsite" appears nowhere in any title.
      expect(searchArchive(all, 'campsite').map((i) => i.id), [2]);
    });

    test('title matches rank above content matches', () {
      // Both items mention "shopping"; the list is *called* Shopping.
      expect(searchArchive(all, 'shopping').map((i) => i.id), [1, 2]);
    });

    test('is case-insensitive', () {
      expect(searchArchive(all, 'GYM').map((i) => i.id), [3]);
    });

    test('no match returns empty', () {
      expect(searchArchive(all, 'zzz'), isEmpty);
    });
  });

  group('matchingLine', () {
    test('returns the content line that matched', () {
      expect(matchingLine(weekendNote, 'campsite'), 'Book the campsite');
    });

    test('returns null when the title matched — it is already on screen', () {
      expect(matchingLine(shoppingList, 'shopping'), isNull);
    });

    test('returns null for an empty query', () {
      expect(matchingLine(weekendNote, ''), isNull);
    });

    test('truncates a very long line', () {
      final ArchivedItem long = ArchivedItem(
        kind: ArchivedKind.note,
        id: 9,
        title: 'x',
        body: 'needle ${'a' * 200}',
      );
      final String? line = matchingLine(long, 'needle');
      expect(line, isNotNull);
      expect(line!.length, lessThanOrEqualTo(91)); // 90 chars + the ellipsis
      expect(line.endsWith('…'), isTrue);
    });
  });

  group('wasLiveWhenDeleted', () {
    final DateTime t = DateTime(2026, 8, 21, 10);

    test('same stamps mean it was live — restore goes back to active', () {
      expect(ArchiveService.wasLiveWhenDeleted(t, t), isTrue);
    });

    test('an earlier archive stamp means it was already archived', () {
      expect(
        ArchiveService.wasLiveWhenDeleted(t.subtract(const Duration(days: 3)), t),
        isFalse,
      );
    });

    test('an item that is not deleted is never "live when deleted"', () {
      expect(ArchiveService.wasLiveWhenDeleted(t, null), isFalse);
      expect(ArchiveService.wasLiveWhenDeleted(null, null), isFalse);
    });
  });

  group('daysLeftInTrash', () {
    final DateTime deleted = DateTime(2026, 8, 1, 9);

    test('counts down from 30', () {
      expect(ArchiveService.daysLeftInTrash(deleted, deleted), 30);
      expect(
        ArchiveService.daysLeftInTrash(
            deleted, deleted.add(const Duration(days: 29))),
        1,
      );
    });

    test('never goes negative once the deadline has passed', () {
      expect(
        ArchiveService.daysLeftInTrash(
            deleted, deleted.add(const Duration(days: 45))),
        0,
      );
    });
  });
}
