import 'package:flutter/material.dart';

/// The 8 habit colours, as hues. A habit stores an index into this list, so
/// each colour can look right in both light and dark mode.
const List<int> kHabitHues = [252, 205, 168, 130, 45, 20, 330, 290];

/// A habit's colours for the current theme: a soft [container] behind its
/// icon, [onContainer] for the icon, and a strong [solid] for a done tick.
typedef HabitColorSet = ({Color container, Color onContainer, Color solid});

abstract final class HabitColors {
  static HabitColorSet of(BuildContext context, int index) {
    final double hue = kHabitHues[index % kHabitHues.length].toDouble();
    Color hsl(double s, double l) => HSLColor.fromAHSL(1, hue, s, l).toColor();
    return Theme.of(context).brightness == Brightness.dark
        ? (
            container: hsl(0.26, 0.25),
            onContainer: hsl(0.72, 0.82),
            solid: hsl(0.62, 0.69),
          )
        : (
            container: hsl(0.72, 0.90),
            onContainer: hsl(0.58, 0.27),
            solid: hsl(0.52, 0.44),
          );
  }
}

/// The icons a habit can have, by the name it is stored under.
const Map<String, IconData> kHabitIcons = {
  'check_circle': Icons.check_circle_rounded,
  'water_drop': Icons.water_drop_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'directions_walk': Icons.directions_walk_rounded,
  'directions_run': Icons.directions_run_rounded,
  'self_improvement': Icons.self_improvement_rounded,
  'menu_book': Icons.menu_book_rounded,
  'bedtime': Icons.bedtime_rounded,
  'mobile_off': Icons.mobile_off_rounded,
  'restaurant': Icons.restaurant_rounded,
  'local_drink': Icons.local_drink_rounded,
  'medication': Icons.medication_rounded,
  'spa': Icons.spa_rounded,
  'school': Icons.school_rounded,
  'edit_note': Icons.edit_note_rounded,
  'savings': Icons.savings_rounded,
  'cleaning_services': Icons.cleaning_services_rounded,
  'pets': Icons.pets_rounded,
  'language': Icons.language_rounded,
  'music_note': Icons.music_note_rounded,
  'brush': Icons.brush_rounded,
  'wb_sunny': Icons.wb_sunny_rounded,
  'favorite': Icons.favorite_rounded,
  'smoke_free': Icons.smoke_free_rounded,
};

/// The icon stored under [name], or a plain check when it is unknown.
IconData habitIcon(String name) =>
    kHabitIcons[name] ?? Icons.check_circle_rounded;
