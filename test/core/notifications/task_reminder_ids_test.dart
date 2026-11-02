import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/notifications/notification_service.dart';

/// Each task books up to 4 reminders. The first three keep the numbers they
/// always had, so reminders booked before the custom one existed are still
/// found and cancelled; the 4th (the custom amount) gets its own range.
void main() {
  test('the first three keep their numbers', () {
    expect(NotificationService.taskReminderId(35, 0), 10105);
    expect(NotificationService.taskReminderId(35, 2), 10107);
  });

  test('the 4th gets its own range', () {
    expect(NotificationService.maxTaskReminders, 4);
    expect(NotificationService.taskReminderId(35, 3), 40035);
  });

  test('no two reminders share a number or enter another range', () {
    final Set<int> seen = <int>{};
    final List<String> clashes = <String>[];
    for (int task = 1; task < 6666; task++) {
      for (int slot = 0; slot < NotificationService.maxTaskReminders; slot++) {
        final int id = NotificationService.taskReminderId(task, slot);
        final bool trackers = id >= 30000 && id < 40000;
        if (!seen.add(id) || trackers || id >= 50000) {
          clashes.add('task $task, slot $slot: $id');
        }
      }
    }
    expect(clashes, isEmpty);
  });
}
