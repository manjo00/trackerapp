import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/github/markdown_feedback_builder.dart';
import 'package:life_tracker/features/tasks/data/models/task_model.dart';
import 'package:life_tracker/features/tasks/data/models/task_priority.dart';

TaskModel task(
  int id,
  String title, {
  TaskPriority priority = TaskPriority.medium,
  bool done = false,
  String? note,
  int? sectionId,
}) =>
    TaskModel(
      id: id,
      title: title,
      note: note,
      priority: priority,
      isCompleted: done,
      createdAt: DateTime(2026, 7, 1),
      sectionId: sectionId,
    );

void main() {
  group('slugify', () {
    test('lowercases and replaces spaces', () {
      expect(slugify('My App List'), 'my-app-list');
    });
    test('collapses punctuation runs and trims dashes', () {
      expect(slugify('  Big!! Issues?? '), 'big-issues');
    });
    test('falls back for fully-symbolic names', () {
      expect(slugify('***'), 'list');
    });
  });

  group('buildFeedbackMarkdown', () {
    test('empty list still produces a valid header', () {
      final String md = buildFeedbackMarkdown(
        listName: 'app',
        sections: const [],
        tasks: const [],
        now: DateTime(2026, 7, 4),
      );
      expect(md, contains('# app — Feedback & Ideas'));
      expect(md, contains('2026-07-04'));
      expect(md, contains('_No open items_'));
    });

    test('unsectioned tasks land under General with priority tags', () {
      final String md = buildFeedbackMarkdown(
        listName: 'app',
        sections: const [],
        tasks: [
          task(1, 'fix drawer', priority: TaskPriority.high),
          task(2, 'archive system', note: 'lists + trackers'),
        ],
        now: DateTime(2026, 7, 4),
      );
      expect(md, contains('## General'));
      expect(md, contains('- [ ] **fix drawer** `High`'));
      expect(md, contains('- [ ] **archive system** `Med`'));
      expect(md, contains('  - lists + trackers'));
    });

    test('sections render in order with their tasks; done gets [x]', () {
      final String md = buildFeedbackMarkdown(
        listName: 'app',
        sections: const [(id: 10, name: 'BIG ISSUES')],
        tasks: [
          task(1, 'bug 2', sectionId: 10),
          task(2, 'old bug', sectionId: 10, done: true),
          task(3, 'loose idea'),
        ],
        now: DateTime(2026, 7, 4),
      );
      final int general = md.indexOf('## General');
      final int section = md.indexOf('## BIG ISSUES');
      expect(general, isNot(-1));
      expect(section, isNot(-1));
      expect(general < section, true,
          reason: 'unsectioned tasks come before sections');
      expect(md, contains('- [ ] **bug 2** `Med`'));
      expect(md, contains('- [x] **old bug** `Med`'));
    });

    test('empty sections are omitted', () {
      final String md = buildFeedbackMarkdown(
        listName: 'app',
        sections: const [(id: 10, name: 'Empty one')],
        tasks: [task(1, 'x')],
        now: DateTime(2026, 7, 4),
      );
      expect(md.contains('## Empty one'), false);
    });
  });
}
