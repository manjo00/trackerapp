import 'package:flutter/material.dart';
import 'tracker_item_model.dart';
import 'tracker_model.dart';

/// A pre-built template the user can pick when creating a new tracker.
///
/// Templates are pure Dart constants — they are never stored in the DB.
/// When the user picks one, a [CustomTracker] row is created from it.
class TrackerTemplate {
  const TrackerTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.defaultItems,
  });

  final String name;
  final String description;
  final String icon;
  final Color color;
  final TrackerType type;

  /// Pre-filled items. Each entry is (itemName, fieldType).
  /// Empty for "Custom" — user adds their own.
  final List<(String, FieldType)> defaultItems;
}

/// All built-in templates shown in the template picker.
///
/// AI-generated templates will slot in here at runtime in a future phase.
const List<TrackerTemplate> kBuiltInTemplates = [
  TrackerTemplate(
    name: 'Daily Prayers',
    description: 'Track your 5 daily prayers',
    icon: '🕌',
    color: Color(0xFF4CAF50),
    type: TrackerType.dailyChecklist,
    defaultItems: [
      ('Fajr', FieldType.checkbox),
      ('Dhuhr', FieldType.checkbox),
      ('Asr', FieldType.checkbox),
      ('Maghrib', FieldType.checkbox),
      ('Isha', FieldType.checkbox),
    ],
  ),
  TrackerTemplate(
    name: 'Gym Workout',
    description: 'Log exercises, sets, reps and weight per session',
    icon: '🏋️',
    color: Color(0xFF1976D2),
    type: TrackerType.sessionLog,
    defaultItems: [
      ('Exercise', FieldType.text),
      ('Sets', FieldType.number),
      ('Reps', FieldType.number),
      ('Weight (kg)', FieldType.number),
    ],
  ),
  TrackerTemplate(
    name: 'Medications',
    description: 'Track daily medication intake',
    icon: '💊',
    color: Color(0xFFE64A19),
    type: TrackerType.dailyChecklist,
    defaultItems: [
      ('Morning dose', FieldType.checkbox),
      ('Evening dose', FieldType.checkbox),
    ],
  ),
  TrackerTemplate(
    name: 'Study Progress',
    description: 'Mark chapters or topics as done',
    icon: '📚',
    color: Color(0xFF7B1FA2),
    type: TrackerType.dailyChecklist,
    defaultItems: [],   // user adds their own chapters
  ),
  TrackerTemplate(
    name: 'Water Intake',
    description: 'Count glasses of water per day',
    icon: '💧',
    color: Color(0xFF0288D1),
    type: TrackerType.dailyChecklist,
    defaultItems: [
      ('Glass 1', FieldType.checkbox),
      ('Glass 2', FieldType.checkbox),
      ('Glass 3', FieldType.checkbox),
      ('Glass 4', FieldType.checkbox),
      ('Glass 5', FieldType.checkbox),
      ('Glass 6', FieldType.checkbox),
      ('Glass 7', FieldType.checkbox),
      ('Glass 8', FieldType.checkbox),
    ],
  ),
  TrackerTemplate(
    name: 'Custom',
    description: 'Build your own tracker from scratch',
    icon: '✏️',
    color: Color(0xFF607D8B),
    type: TrackerType.dailyChecklist,
    defaultItems: [],
  ),
];
