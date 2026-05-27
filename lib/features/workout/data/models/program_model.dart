import 'package:freezed_annotation/freezed_annotation.dart';
import 'program_session_model.dart';

part 'program_model.freezed.dart';

/// A training program with its session types.
@freezed
class ProgramModel with _$ProgramModel {
  const ProgramModel._();

  const factory ProgramModel({
    required int id,
    required String name,
    String? description,
    @Default(false) bool isActive,

    /// 'rotating' | 'weekly'
    @Default('rotating') String splitType,
    required DateTime createdAt,

    /// Session types ordered by [ProgramSessionModel.orderIndex].
    @Default(<ProgramSessionModel>[]) List<ProgramSessionModel> sessions,
  }) = _ProgramModel;

  bool get isRotating => splitType == 'rotating';
  bool get isWeekly => splitType == 'weekly';

  /// For rotating splits: returns the next session to train based on how many
  /// sessions have already been completed under this program.
  ///
  /// [completedCount] = number of past workout sessions that have a
  /// programSessionId belonging to this program.
  ProgramSessionModel? nextRotatingSession(int completedCount) {
    if (sessions.isEmpty) return null;
    return sessions[completedCount % sessions.length];
  }

  /// For weekly splits: returns sessions scheduled for today (ISO weekday).
  List<ProgramSessionModel> todaysSessions(int isoWeekday) {
    return sessions
        .where((s) => s.isOnWeekday(isoWeekday))
        .toList();
  }
}
