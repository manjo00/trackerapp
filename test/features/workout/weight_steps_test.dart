import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/workout/data/models/weight_steps.dart';

void main() {
  group('nextWeightUp', () {
    test('on-ladder value climbs one rung', () {
      expect(nextWeightUp(10), 12.5);
      expect(nextWeightUp(12.5), 15);
      expect(nextWeightUp(0), 2.5);
    });
    test('off-ladder value snaps to the rung above', () {
      expect(nextWeightUp(11), 12.5);
      expect(nextWeightUp(13.7), 15);
      expect(nextWeightUp(2.4), 2.5);
    });
  });

  group('nextWeightDown', () {
    test('on-ladder value descends one rung', () {
      expect(nextWeightDown(15), 12.5);
      expect(nextWeightDown(12.5), 10);
    });
    test('off-ladder value snaps to the rung below', () {
      expect(nextWeightDown(11), 10);
      expect(nextWeightDown(13.7), 12.5);
    });
    test('never goes below zero', () {
      expect(nextWeightDown(0), 0);
      expect(nextWeightDown(1.5), 0);
    });
  });

  group('parseWeight', () {
    test('accepts dot decimals', () {
      expect(parseWeight('12.5'), 12.5);
    });
    test('accepts comma and Arabic decimal separators', () {
      expect(parseWeight('12,5'), 12.5);
      expect(parseWeight('12٫5'), 12.5);
    });
    test('returns null for junk or empty', () {
      expect(parseWeight(''), null);
      expect(parseWeight('abc'), null);
    });
  });
}
