import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/text/when_parser.dart';

void main() {
  // Fixed "now": Saturday 11 July 2026, 09:00. Current month = July (7).
  final DateTime now = DateTime(2026, 7, 11, 9);

  group('parseTaskText — times', () {
    test('@1450pm keeps 24h when hour ≥ 13', () {
      final r = WhenParser.parseTaskText('take bloods @1450pm', now: now)!;
      expect(r.time, '14:50');
      expect(r.date, isNull);
    });
    test('am/pm applies to a 1–12 hour (250pm needs @/colon; 2:50pm works)', () {
      expect(WhenParser.parseTaskText('call 2:50pm', now: now)!.time, '14:50');
    });
    test('bare 5pm is a time (am/pm disambiguates)', () {
      final r = WhenParser.parseTaskText('5pm gym', now: now)!;
      expect(r.time, '17:00');
      expect(WhenParser.stripFrom('5pm gym', r), 'gym');
    });
    test('a dangling "at" connector is stripped from the title', () {
      const s = 'call mom at 5pm';
      final r = WhenParser.parseTaskText(s, now: now)!;
      expect(r.time, '17:00');
      expect(WhenParser.stripFrom(s, r), 'call mom');
    });
    test('"at 1250" (no colon) is a time', () {
      expect(WhenParser.parseTaskText('meet at 1250', now: now)!.time, '12:50');
    });
    test('bare 1250 with no @/at/colon/ampm is NOT a time', () {
      expect(WhenParser.parseTaskText('order 1250 units', now: now), isNull);
    });
  });

  group('parseTaskText — dates', () {
    test('month day and day month', () {
      expect(WhenParser.parseTaskText('x july 12', now: now)!.date, '2026-07-12');
      expect(WhenParser.parseTaskText('x 12 july', now: now)!.date, '2026-07-12');
      expect(WhenParser.parseTaskText('x 12jul', now: now)!.date, '2026-07-12');
    });
    test('day-only ordinal → current month', () {
      expect(WhenParser.parseTaskText('call mom 12th', now: now)!.date,
          '2026-07-12');
    });
    test('today / tomorrow', () {
      expect(WhenParser.parseTaskText('pay today', now: now)!.date, '2026-07-11');
      expect(WhenParser.parseTaskText('pay tomorrow', now: now)!.date,
          '2026-07-12');
    });
    test('out-of-range day is rejected', () {
      expect(WhenParser.parseTaskText('x 35th', now: now), isNull);
    });
  });

  group('parseTaskText — combined + strip', () {
    test('"take bloods at 12:50pm july 12" → time+date, clean title', () {
      const s = 'take bloods at 12:50pm july 12';
      final r = WhenParser.parseTaskText(s, now: now)!;
      expect(r.time, '12:50');
      expect(r.date, '2026-07-12');
      expect(WhenParser.stripFrom(s, r), 'take bloods');
    });
    test('"at 1250 july 12" → 12:50 + Jul 12', () {
      final r = WhenParser.parseTaskText('at 1250 july 12', now: now)!;
      expect(r.time, '12:50');
      expect(r.date, '2026-07-12');
    });
  });

  group('parseTaskText — clinical shorthand is NOT a date/time', () {
    for (final s in const [
      'take sample from bed 7',
      'O2 30',
      '35% 35flow',
      'give 5 units insulin',
      'room 9 done',
    ]) {
      test('"$s" → null', () {
        expect(WhenParser.parseTaskText(s, now: now), isNull);
      });
    }
  });

  group('parseNoteLine — checkbox line token (start-anchored)', () {
    test('@1450pm take bloods', () {
      final r = WhenParser.parseNoteLine('@1450pm take bloods', now: now)!;
      expect(r.time, '14:50');
      expect(r.date, isNull);
      expect(r.title, 'take bloods');
    });
    test('legacy @1250pm/17july', () {
      final r = WhenParser.parseNoteLine('@1250pm/17july', now: now)!;
      expect(r.time, '12:50');
      expect(r.date, '2026-07-17');
      expect(r.title, '');
    });
    test('new "@1250pm july 12" (space, no slash)', () {
      final r = WhenParser.parseNoteLine('@1250pm july 12 draw', now: now)!;
      expect(r.date, '2026-07-12');
      expect(r.title, 'draw');
    });
    test('"at 12:50pm review" also works at the start', () {
      final r = WhenParser.parseNoteLine('at 12:50pm review', now: now)!;
      expect(r.time, '12:50');
      expect(r.title, 'review');
    });
    test('ordinary prose (no leading token) → null', () {
      expect(WhenParser.parseNoteLine('call me at some point', now: now), isNull);
      expect(WhenParser.parseNoteLine('email boss@work now', now: now), isNull);
    });
    test('title-less token keeps an empty title', () {
      expect(WhenParser.parseNoteLine('@0900', now: now)!.title, '');
    });
  });
}
