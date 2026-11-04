import '../../data/models/habit_model.dart';
import '../../domain/habit_stats.dart';
import '../../domain/habit_types.dart';

/// One habit as every habit screen shows it today: the habit, its recent
/// history (for the week strip) and today's state and numbers.
class HabitDayView {
  const HabitDayView({
    required this.habit,
    required this.history,
    required this.summary,
  });

  final HabitModel habit;
  final HabitHistory history;
  final HabitSummary summary;
}
