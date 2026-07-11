import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/notes/domain/task_token_parser.dart';

void main() {
  // A fixed "now" so date defaults (month/year) are deterministic.
  final now = DateTime(2026, 7, 11, 8, 0);

  ParsedTaskToken? parse(String line) => TaskTokenParser.parse(line, now: now);

  group('non-tokens return null', () {
    for (final line in const [
      '',
      'just a normal note line',
      'email me @home later',
      'meet @ 3',
      '@pm nope',
      '@ 1250pm',
      'text before @1250pm', // token must be at the START of the line
    ]) {
      test('"$line"', () => expect(parse(line), isNull));
    }
  });

  group('time parsing', () {
    test('@1250pm → 12:50 today, no title', () {
      final r = parse('@1250pm')!;
      expect(r.time, '12:50');
      expect(r.date, isNull);
      expect(r.title, '');
    });

    test('@250pm → 14:50 (am/pm applies to a 1–12 hour)', () {
      expect(parse('@250pm')!.time, '14:50');
    });

    test('@1450pm → 14:50 (already 24-hour, pm ignored)', () {
      expect(parse('@1450pm')!.time, '14:50');
    });

    test('@12:50pm colon form → 12:50', () {
      expect(parse('@12:50pm')!.time, '12:50');
    });

    test('@1250 (no am/pm) → 12:50', () {
      expect(parse('@1250')!.time, '12:50');
    });

    test('@900 → 09:00', () {
      expect(parse('@900')!.time, '09:00');
    });

    test('12am maps to midnight, 12pm stays noon', () {
      expect(parse('@1215am')!.time, '00:15');
      expect(parse('@1215pm')!.time, '12:15');
    });

    test('invalid minutes/hours return null', () {
      expect(parse('@1275'), isNull); // 75 minutes
      expect(parse('@2500'), isNull); // 25 hours
    });
  });

  group('title extraction', () {
    test('@1450pm take sample from bed 7', () {
      final r = parse('@1450pm take sample from bed 7')!;
      expect(r.time, '14:50');
      expect(r.title, 'take sample from bed 7');
    });

    test('title trims surrounding whitespace', () {
      expect(parse('@0900   morning obs   ')!.title, 'morning obs');
    });
  });

  group('date parsing', () {
    test('@1250pm/17july → that dated day', () {
      final r = parse('@1250pm/17july')!;
      expect(r.date, '2026-07-17');
      expect(r.time, '12:50');
    });

    test('3-letter month abbreviation works', () {
      expect(parse('@0800/03aug')!.date, '2026-08-03');
    });

    test('day only defaults to the current month', () {
      expect(parse('@0800/17')!.date, '2026-07-17');
    });

    test('date + title together', () {
      final r = parse('@0700/18july bloods for bed 3')!;
      expect(r.date, '2026-07-18');
      expect(r.title, 'bloods for bed 3');
    });

    test('out-of-range day falls back to no date (today)', () {
      expect(parse('@0800/32july')!.date, isNull);
    });

    test('unknown month word falls back to no date', () {
      expect(parse('@0800/17smarch')!.date, isNull);
    });
  });
}
