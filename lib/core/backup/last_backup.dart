import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_provider.dart';

/// When a backup file was last handed to another app (the share sheet reported
/// a chosen app, so it was really sent somewhere). Null until the first one.
///
/// Shown under Settings › Data › Export data, because the phone usually holds
/// the only copy of everything.
class LastBackupNotifier extends Notifier<DateTime?> {
  static const String _key = 'last_backup_at';

  @override
  DateTime? build() {
    final int? ms = ref.watch(sharedPreferencesProvider).getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> record(DateTime sentAt) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_key, sentAt.millisecondsSinceEpoch);
    state = sentAt;
  }
}

final lastBackupProvider =
    NotifierProvider<LastBackupNotifier, DateTime?>(LastBackupNotifier.new);

/// "No backup yet", "Last backup: today", "…: yesterday" or "…: N days ago",
/// counted in calendar days.
String lastBackupLabel(DateTime? last, DateTime now) {
  if (last == null) return 'No backup yet';
  final int days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(last.year, last.month, last.day))
      .inDays;
  if (days <= 0) return 'Last backup: today';
  if (days == 1) return 'Last backup: yesterday';
  return 'Last backup: $days days ago';
}
