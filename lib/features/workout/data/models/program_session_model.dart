import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'program_exercise_model.dart';

part 'program_session_model.freezed.dart';

/// A session type within a program (e.g. "Push", "Pull", "Legs").
@freezed
class ProgramSessionModel with _$ProgramSessionModel {
  const ProgramSessionModel._();

  const factory ProgramSessionModel({
    required int id,
    required int programId,
    required String name,
    @Default(0xFF6750A4) int colorValue,
    @Default(0) int orderIndex,

    /// Comma-separated ISO weekday numbers for weekly splits.
    /// e.g. "1,4" = Mon + Thu.  NULL for rotating splits.
    String? weekDays,

    /// Exercises in this session, ordered by [orderIndex].
    @Default(<ProgramExerciseModel>[]) List<ProgramExerciseModel> exercises,
  }) = _ProgramSessionModel;

  Color get color => Color(colorValue);

  /// Parsed weekday list: [1..7] where 1 = Monday.
  List<int> get weekDayList {
    if (weekDays == null || weekDays!.trim().isEmpty) return [];
    return weekDays!
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  static const List<String> _dayLabels = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Human-readable schedule, e.g. "Mon · Thu".
  String get weekDayLabel {
    final days = weekDayList;
    if (days.isEmpty) return '';
    return days.map((d) => _dayLabels[d]).join(' · ');
  }

  /// True if [weekday] (1=Mon..7=Sun) is in this session's schedule.
  bool isOnWeekday(int weekday) => weekDayList.contains(weekday);
}
