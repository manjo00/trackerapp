import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/planner/presentation/day_grid_layout.dart';
import 'package:life_tracker/features/tasks/data/models/task_model.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';

TaskModel task(
  int id, {
  String? time,
  int? duration,
  TaskPriority priority = TaskPriority.medium,
}) =>
    TaskModel(
      id: id,
      title: 't$id',
      dueTime: time,
      durationMinutes: duration,
      priority: priority,
      isCompleted: false,
      createdAt: DateTime(2026, 7, 1).add(Duration(minutes: id)),
    );

void main() {
  group('layoutDayItems', () {
    test('untimed tasks are excluded; default duration is 30', () {
      final items = layoutDayItems([task(1), task(2, time: '09:00')]);
      expect(items.length, 1);
      expect(items.single.startMin, 540);
      expect(items.single.durationMin, 30);
      expect(items.single.column, 0);
      expect(items.single.columns, 1);
    });

    test('non-overlapping items each get the full width', () {
      final items = layoutDayItems([
        task(1, time: '09:00', duration: 60),
        task(2, time: '10:00', duration: 60), // touching ≠ overlapping
      ]);
      expect(items.map((i) => i.columns), everyElement(1));
    });

    test('two overlapping items split into two columns', () {
      final items = layoutDayItems([
        task(1, time: '09:00', duration: 90),
        task(2, time: '10:00', duration: 60),
      ]);
      expect(items.map((i) => i.columns), everyElement(2));
      expect(items.map((i) => i.column).toSet(), {0, 1});
    });

    test('three overlapping items → three columns', () {
      final items = layoutDayItems([
        task(1, time: '09:00', duration: 120),
        task(2, time: '09:30', duration: 120),
        task(3, time: '10:00', duration: 120),
      ]);
      expect(items.map((i) => i.columns), everyElement(3));
      expect(items.map((i) => i.column).toSet(), {0, 1, 2});
    });

    test('fourth overlapping item wraps back onto column 0, capped at 3',
        () {
      final items = layoutDayItems([
        task(1, time: '09:00', duration: 240),
        task(2, time: '09:10', duration: 240),
        task(3, time: '09:20', duration: 240),
        task(4, time: '09:30', duration: 240),
      ]);
      expect(items.map((i) => i.columns), everyElement(3));
      expect(items[3].column, 0);
    });
  });

  group('splitTimed', () {
    test('timed sorted by start; untimed by priority then age', () {
      final (timed, untimed) = splitTimed([
        task(1, priority: TaskPriority.low),
        task(2, time: '15:00'),
        task(3, priority: TaskPriority.high),
        task(4, time: '09:00'),
      ]);
      expect(timed.map((t) => t.id), [4, 2]);
      expect(untimed.map((t) => t.id), [3, 1]);
    });
  });
}
