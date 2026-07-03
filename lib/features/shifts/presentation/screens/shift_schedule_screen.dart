import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/shift_month_calendar.dart';
import 'rotations_editor_screen.dart';

/// The Work Schedule screen — a month calendar for entering shift days.
///
/// Reached from the drawer's Features section. Tap a day to open the picker
/// (day/night + rotation).
class ShiftScheduleScreen extends ConsumerWidget {
  const ShiftScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Edit rotations',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RotationsEditorScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          const ShiftMonthCalendar(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 20, color: cs.onSurface.withAlpha(160)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap a day to set its shift — day/night + rotation',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
