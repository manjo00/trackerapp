import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/backup/last_backup.dart';
import 'package:life_tracker/core/settings/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings › Data shows how old the last backup is, so a phone that holds the
/// only copy of everything doesn't go months without one.
void main() {
  group('lastBackupLabel', () {
    final DateTime now = DateTime(2026, 11, 1, 9, 30);

    test('says so when there has never been a backup', () {
      expect(lastBackupLabel(null, now), 'No backup yet');
    });

    test('counts calendar days, not hours', () {
      expect(lastBackupLabel(DateTime(2026, 11, 1, 7), now), 'Last backup: today');
      expect(lastBackupLabel(DateTime(2026, 10, 31, 23, 50), now),
          'Last backup: yesterday');
      expect(lastBackupLabel(DateTime(2026, 10, 20, 12), now),
          'Last backup: 12 days ago');
    });

    test('treats a date in the future (clock changed) as today', () {
      expect(lastBackupLabel(DateTime(2026, 11, 3), now), 'Last backup: today');
    });
  });

  group('lastBackupProvider', () {
    test('starts empty and remembers a recorded backup', () async {
      SharedPreferences.setMockInitialValues({});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer first = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(first.dispose);

      expect(first.read(lastBackupProvider), isNull);
      final DateTime sent = DateTime(2026, 11, 1, 10, 15);
      await first.read(lastBackupProvider.notifier).record(sent);
      expect(first.read(lastBackupProvider), sent);

      // A later app start reads it back from the stored settings.
      final ProviderContainer later = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(later.dispose);
      expect(later.read(lastBackupProvider), sent);
    });
  });
}
