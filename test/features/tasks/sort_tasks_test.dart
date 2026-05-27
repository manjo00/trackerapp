import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/tasks/data/models/task_model.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';
import 'package:life_tracker/features/tasks/data/repositories/tasks_repository.dart';

/// Builds a minimal [TaskModel] for test use.
TaskModel _task(
  int id,
  String title, {
  bool done = false,
  String? dueDate,
  TaskPriority priority = TaskPriority.medium,
}) =>
    TaskModel(
      id: id,
      title: title,
      isCompleted: done,
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime(2026, 5, 1, id), // different times for stable sort
    );

void main() {
  group('TasksRepository.sortTasks', () {
    test('incomplete tasks appear before completed tasks', () {
      final List<TaskModel> input = [
        _task(1, 'Done task', done: true),
        _task(2, 'Active task'),
      ];

      final List<TaskModel> sorted = TasksRepository.sortTasks(input);

      expect(sorted.first.title, 'Active task');
      expect(sorted.last.title, 'Done task');
    });

    test('among incomplete: earlier due date sorts first', () {
      final List<TaskModel> input = [
        _task(1, 'Later', dueDate: '2026-06-01'),
        _task(2, 'Earlier', dueDate: '2026-05-28'),
      ];

      final List<TaskModel> sorted = TasksRepository.sortTasks(input);

      expect(sorted.first.title, 'Earlier');
    });

    test('tasks with no due date sort after tasks with a due date', () {
      final List<TaskModel> input = [
        _task(1, 'No date'),
        _task(2, 'Has date', dueDate: '2026-05-28'),
      ];

      final List<TaskModel> sorted = TasksRepository.sortTasks(input);

      expect(sorted.first.title, 'Has date');
      expect(sorted.last.title, 'No date');
    });

    test('same due date: higher priority sorts first', () {
      final List<TaskModel> input = [
        _task(1, 'Low', dueDate: '2026-05-28', priority: TaskPriority.low),
        _task(2, 'High', dueDate: '2026-05-28', priority: TaskPriority.high),
        _task(3, 'Med', dueDate: '2026-05-28', priority: TaskPriority.medium),
      ];

      final List<TaskModel> sorted = TasksRepository.sortTasks(input);

      expect(sorted[0].title, 'High');
      expect(sorted[1].title, 'Med');
      expect(sorted[2].title, 'Low');
    });

    test('does not mutate the input list', () {
      final List<TaskModel> input = [
        _task(1, 'Done', done: true),
        _task(2, 'Active'),
      ];
      final List<TaskModel> original = List.of(input);

      TasksRepository.sortTasks(input);

      // Input order unchanged
      expect(input[0].title, original[0].title);
      expect(input[1].title, original[1].title);
    });
  });
}
