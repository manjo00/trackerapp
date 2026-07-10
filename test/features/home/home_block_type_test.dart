import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/home/data/home_block_type.dart';

void main() {
  test('defaults are the slice-1 order plus workout then notes', () {
    expect(HomeBlockType.defaults, [
      HomeBlockType.urgent,
      HomeBlockType.dueToday,
      HomeBlockType.captured,
      HomeBlockType.thisWeek,
      HomeBlockType.workout,
      HomeBlockType.notes,
    ]);
  });

  test('parse keeps stored order', () {
    expect(HomeBlockType.parse(['workout', 'urgent']),
        [HomeBlockType.workout, HomeBlockType.urgent]);
  });

  test('parse drops unknown names (does NOT fall back to defaults)', () {
    expect(HomeBlockType.parse(['bogus']), isEmpty);
    expect(HomeBlockType.parse(['bogus', 'captured']),
        [HomeBlockType.captured]);
  });

  test('parse collapses duplicates keeping the first occurrence', () {
    expect(HomeBlockType.parse(['urgent', 'thisWeek', 'urgent']),
        [HomeBlockType.urgent, HomeBlockType.thisWeek]);
  });

  test('null (nothing stored yet) means defaults; empty list stays empty',
      () {
    expect(HomeBlockType.parse(null), HomeBlockType.defaults);
    expect(HomeBlockType.parse(const []), isEmpty);
  });
}
