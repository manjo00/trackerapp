import 'package:flutter/material.dart';

/// Where a topic lives in the Codex.
enum CodexCategory {
  basics,
  tasks,
  planner,
  notes,
  home,
  daily,
  workout,
  shifts,
  reminders,
  data;

  String get title => switch (this) {
        basics => 'Getting around',
        tasks => 'Tasks & lists',
        planner => 'Planner',
        notes => 'Notes',
        home => 'Home dashboard',
        daily => 'Habits & trackers',
        workout => 'Workout',
        shifts => 'Work shifts',
        reminders => 'Reminders & glances',
        data => 'Data & support',
      };

  IconData get icon => switch (this) {
        basics => Icons.explore_rounded,
        tasks => Icons.check_circle_outline_rounded,
        planner => Icons.calendar_month_rounded,
        notes => Icons.sticky_note_2_rounded,
        home => Icons.dashboard_rounded,
        daily => Icons.repeat_rounded,
        workout => Icons.fitness_center_rounded,
        shifts => Icons.work_history_rounded,
        reminders => Icons.notifications_active_rounded,
        data => Icons.settings_rounded,
      };
}

/// How one line of a topic renders.
enum CodexBlockKind {
  /// Plain prose.
  paragraph,

  /// A numbered instruction (consecutive steps auto-number 1, 2, 3…).
  step,

  /// A dash bullet.
  bullet,

  /// A highlighted "did you know" callout.
  tip,

  /// A small section heading inside a topic.
  heading,
}

class CodexBlock {
  const CodexBlock(this.kind, this.text);
  const CodexBlock.p(this.text) : kind = CodexBlockKind.paragraph;
  const CodexBlock.step(this.text) : kind = CodexBlockKind.step;
  const CodexBlock.bullet(this.text) : kind = CodexBlockKind.bullet;
  const CodexBlock.tip(this.text) : kind = CodexBlockKind.tip;
  const CodexBlock.heading(this.text) : kind = CodexBlockKind.heading;

  final CodexBlockKind kind;
  final String text;
}

/// One Codex article.
class CodexTopic {
  const CodexTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.body,
    this.hidden = false,
    this.keywords = const [],
    this.sinceVersion,
  });

  final String id;
  final String title;
  final CodexCategory category;

  /// One-line description shown in the list.
  final String summary;
  final List<CodexBlock> body;

  /// A feature you'd never find by tapping around — badged in the list and
  /// collected under "Hidden gems".
  final bool hidden;

  /// Extra search terms that don't appear in the text (synonyms).
  final List<String> keywords;

  /// Release this topic arrived in (or was rewritten for). While it equals
  /// `kCurrentRelease` the topic is listed under "What's new" instead of its
  /// own area; afterwards it returns to that area automatically.
  final String? sinceVersion;
}
