import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Displays the current streak as a compact badge, e.g. "🔥 5".
///
/// Renders nothing when [streak] is zero — no badge clutters the UI
/// until the user has actually built a streak.
class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.streak, super.key});

  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Warm amber feels "earned" — distinct from the indigo accent.
        color: AppColors.streakAmber.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.streakAmber.withAlpha(120),
          width: 1,
        ),
      ),
      child: Text(
        '🔥 $streak',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.streakAmber,
        ),
      ),
    );
  }
}
