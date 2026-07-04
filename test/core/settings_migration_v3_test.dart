import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/settings/app_settings.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v3 migration: old default trio upgrades to Home/Lists/Planner',
      () async {
    SharedPreferences.setMockInitialValues({
      'settings_version': 2,
      'visible_tabs': ['today', 'inbox', 'planner'],
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    expect(notifier.state.visibleTabs,
        {AppTab.home, AppTab.lists, AppTab.planner});
  });

  test('v3 migration: custom tab set maps renamed tabs in place', () async {
    SharedPreferences.setMockInitialValues({
      'settings_version': 2,
      'visible_tabs': ['today', 'tasks', 'workout'],
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    expect(notifier.state.visibleTabs,
        {AppTab.today, AppTab.lists, AppTab.workout});
  });
}
