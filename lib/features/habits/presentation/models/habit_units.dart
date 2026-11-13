import 'package:intl/intl.dart';

/// The most a count habit's goal or one day's amount can be: room for
/// 2,000 ml of water or 10,000 steps.
const int kMaxHabitAmount = 99999;

/// Quick units for a count habit in the editor. While the goal is still
/// empty, picking one also fills a goal and a step (what one + adds).
/// Whole numbers only, so ml rather than litres.
const List<({String unit, int goal, int step})> kUnitPresets = [
  (unit: 'glasses', goal: 8, step: 1),
  (unit: 'ml', goal: 2000, step: 250),
  (unit: 'min', goal: 30, step: 5),
  (unit: 'hours', goal: 8, step: 1),
  (unit: 'pages', goal: 20, step: 5),
  (unit: 'steps', goal: 8000, step: 1000),
  (unit: 'km', goal: 5, step: 1),
  (unit: 'times', goal: 10, step: 1),
];

/// An amount with thousands separators: 1250 → "1,250".
String formatAmount(int n) => NumberFormat('#,##0').format(n);
