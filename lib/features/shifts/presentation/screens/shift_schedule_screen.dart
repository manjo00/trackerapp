import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/work_shift_model.dart';
import '../providers/shifts_providers.dart';
import '../widgets/shift_month_calendar.dart';
import 'rotations_editor_screen.dart';

/// The Work Schedule screen — a month calendar for entering shift days.
///
/// Reached from the drawer's Features section. Tap a day to open the picker
/// (day/night + rotation). The toolbar can pre-load the July rota.
class ShiftScheduleScreen extends ConsumerWidget {
  const ShiftScheduleScreen({super.key});

  /// Ahmed Alzahrani's July 2026 day-rota (all day shifts), parsed from the
  /// hospital PDF. day-of-month → rotation label.
  static const Map<int, String> _julyRota = {
    8: 'ER', 9: 'ER',
    10: 'Cardiac', 11: 'Cardiac',
    14: 'Ward', 15: 'Ward', 16: 'Ward',
    19: 'ICU4B', 20: 'ICU4B',
    24: 'ICU2', 25: 'ICU2',
    26: 'TICU', 27: 'TICU',
    30: 'ICU1', 31: 'ICU1',
  };

  static const int _orange = 0xFFFFB347;

  Future<void> _importJuly(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load July rota?'),
        content: const Text(
          'This enters your 15 July day shifts from the hospital rota '
          '(ER, Cardiac, Ward, ICU4B, ICU2, TICU, ICU1). Existing July days '
          'will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final ShiftEditor notifier = ref.read(shiftEditorProvider.notifier);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    for (final MapEntry<int, String> e in _julyRota.entries) {
      final String date = '2026-07-${e.key.toString().padLeft(2, '0')}';
      await notifier.assign(
        date,
        ShiftType.day,
        rotationLabel: e.value,
        rotationColor: _orange,
      );
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('July rota loaded — swipe to July')),
    );
  }

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
          IconButton(
            icon: const Icon(Icons.event_available_rounded),
            tooltip: 'Load July rota',
            onPressed: () => _importJuly(context, ref),
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
