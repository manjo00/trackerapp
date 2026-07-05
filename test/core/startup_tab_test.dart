import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/settings/startup_tab.dart';

void main() {
  test('nothing stored → Home', () {
    expect(startupLocation(storedTab: null, storedVisibleTabs: null),
        '/home');
  });

  test('stored tab that is visible wins', () {
    expect(
        startupLocation(
            storedTab: 'workout',
            storedVisibleTabs: ['home', 'lists', 'workout']),
        '/workout');
  });

  test('stored tab NOT visible → first visible tab (enum order)', () {
    expect(
        startupLocation(
            storedTab: 'workout', storedVisibleTabs: ['planner', 'lists']),
        '/lists',
        reason: 'lists comes before planner in AppTab/branch order');
  });

  test('garbage stored tab → first of the default visible set', () {
    expect(startupLocation(storedTab: 'bogus', storedVisibleTabs: null),
        '/home');
  });

  test('no stored tab but custom visible set without home → first visible',
      () {
    expect(
        startupLocation(
            storedTab: null, storedVisibleTabs: ['today', 'workout']),
        '/today');
  });
}
