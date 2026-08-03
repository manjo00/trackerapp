import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shifts/data/models/work_shift_model.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../../shifts/presentation/shift_style.dart';

/// Home block: today's shift at a glance (colors + rotation label + hours) and
/// the next upcoming shift within two weeks. Tap → the Work schedule.
class ShiftBlock extends ConsumerWidget {
  const ShiftBlock({super.key});

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// True when there's nothing to glance at — no shift today and none in the
  /// next 14 days. Drives the block's hide-when-empty option.
  static bool isEmpty(Map<String, WorkShiftModel> byDate, DateTime today) {
    for (int i = 0; i <= 14; i++) {
      if (byDate[_key(today.add(Duration(days: i)))] != null) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Map<String, WorkShiftModel> byDate =
        ref.watch(shiftsByDateProvider).valueOrNull ?? const {};

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final WorkShiftModel? todays = byDate[_key(today)];

    WorkShiftModel? next;
    DateTime? nextDay;
    for (int i = 1; i <= 14 && next == null; i++) {
      final DateTime d = today.add(Duration(days: i));
      final WorkShiftModel? s = byDate[_key(d)];
      if (s != null) {
        next = s;
        nextDay = d;
      }
    }

    const List<String> weekdays = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/schedule'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todays == null)
                Text('Off today 🎉',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withAlpha(170)))
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ShiftStyle.fill(todays.type),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(ShiftStyle.icon(todays.type),
                              size: 15,
                              color: ShiftStyle.iconColor(todays.type)),
                          const SizedBox(width: 6),
                          Text(
                            todays.rotationLabel ??
                                (todays.type == ShiftType.day
                                    ? 'Day'
                                    : 'Night'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ShiftStyle.foreground(todays.type),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${todays.startTime}–${todays.endTime}',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurface.withAlpha(170)),
                    ),
                  ],
                ),
              if (next != null && nextDay != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Next: ${weekdays[nextDay.weekday]} ${nextDay.day}/'
                  '${nextDay.month} · '
                  '${next.rotationLabel ?? (next.type == ShiftType.day ? 'Day' : 'Night')}',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withAlpha(140)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
