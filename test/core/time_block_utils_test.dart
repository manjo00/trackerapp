import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/utils/time_block_utils.dart';

void main() {
  group('minutesOfDay', () {
    test('parses HH:mm', () {
      expect(minutesOfDay('14:30'), 870);
      expect(minutesOfDay('00:00'), 0);
      expect(minutesOfDay('23:59'), 1439);
    });
    test('null and garbage give null', () {
      expect(minutesOfDay(null), null);
      expect(minutesOfDay('abc'), null);
      expect(minutesOfDay('25:00'), null);
      expect(minutesOfDay('12:75'), null);
    });
  });

  group('endTimeOf', () {
    test('adds the duration', () {
      expect(endTimeOf('14:00', 90), '15:30');
      expect(endTimeOf('09:15', 45), '10:00');
    });
    test('null start or duration gives null', () {
      expect(endTimeOf(null, 60), null);
      expect(endTimeOf('14:00', null), null);
    });
    test('clamps at 23:59 instead of wrapping past midnight', () {
      expect(endTimeOf('23:00', 120), '23:59');
    });
  });

  group('durationBetween', () {
    test('computes minutes', () {
      expect(durationBetween('14:00', '15:30'), 90);
    });
    test('end at or before start is invalid (null)', () {
      expect(durationBetween('14:00', '14:00'), null);
      expect(durationBetween('14:00', '13:00'), null);
    });
  });

  test('formatRange', () {
    expect(formatRange('14:00', 90), '14:00–15:30');
  });
}
