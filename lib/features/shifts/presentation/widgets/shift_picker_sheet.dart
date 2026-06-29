import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/work_shift_model.dart';
import '../providers/shifts_providers.dart';
import '../shift_style.dart';

/// Bottom sheet to assign a shift to [date]: pick day/night + a rotation, or
/// clear the day. Opened by tapping a day on the Work Schedule calendar.
Future<void> showShiftPicker(BuildContext context, String date) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShiftPickerSheet(date: date),
  );
}

class _ShiftPickerSheet extends ConsumerStatefulWidget {
  const _ShiftPickerSheet({required this.date});
  final String date;

  @override
  ConsumerState<_ShiftPickerSheet> createState() => _ShiftPickerSheetState();
}

class _ShiftPickerSheetState extends ConsumerState<_ShiftPickerSheet> {
  ShiftType _type = ShiftType.day;

  @override
  void initState() {
    super.initState();
    // Pre-select day/night from the existing shift on this day, if any.
    final existing =
        ref.read(shiftsByDateProvider).valueOrNull?[widget.date];
    if (existing != null) _type = existing.type;
  }

  void _assign(ShiftRotationModel r) {
    ref.read(shiftEditorProvider.notifier).assign(
          widget.date,
          _type,
          rotationLabel: r.name,
          rotationColor: r.colorValue,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<ShiftRotationModel> rotations =
        ref.watch(rotationsProvider).valueOrNull ?? const [];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Day / Night
              SegmentedButton<ShiftType>(
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
                segments: [
                  ButtonSegment(
                    value: ShiftType.day,
                    icon: Icon(ShiftStyle.icon(ShiftType.day), size: 16),
                    label: const Text('Day'),
                  ),
                  ButtonSegment(
                    value: ShiftType.night,
                    icon: Icon(ShiftStyle.icon(ShiftType.night), size: 16),
                    label: const Text('Night'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),

              const SizedBox(height: 16),
              Text(
                'Rotation',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
              ),
              const SizedBox(height: 8),

              // Rotation chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ShiftRotationModel r in rotations)
                    ActionChip(
                      label: Text(r.name),
                      labelStyle: TextStyle(
                        color: Color(r.colorValue),
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(color: Color(r.colorValue).withAlpha(140)),
                      backgroundColor: Color(r.colorValue).withAlpha(28),
                      onPressed: () => _assign(r),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(shiftEditorProvider.notifier)
                        .clear(widget.date);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear / Off'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
