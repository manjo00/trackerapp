import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/work_shift_model.dart';
import '../providers/shifts_providers.dart';

/// Editor for the rotation labels (ICU1, ER, …) — add, rename, recolor, delete.
class RotationsEditorScreen extends ConsumerWidget {
  const RotationsEditorScreen({super.key});

  /// Preset label colours offered in the editor.
  static const List<int> _palette = [
    0xFFF4511E, // deep orange
    0xFF5FC6D8, // cyan
    0xFFA6ABEC, // periwinkle
    0xFFE07070, // red
    0xFF7FBF7F, // green
    0xFFB39DDB, // purple
    0xFFE6A0C4, // pink
    0xFFBFC4CC, // grey
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ShiftRotationModel> rotations =
        ref.watch(rotationsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Rotations')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final ShiftRotationModel r in rotations)
            ListTile(
              leading: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(r.colorValue),
                ),
              ),
              title: Text(r.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () =>
                    ref.read(shiftEditorProvider.notifier).deleteRotation(r.id),
              ),
              onTap: () => _editDialog(context, ref, rotation: r),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editDialog(context, ref),
        tooltip: 'Add rotation',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref, {
    ShiftRotationModel? rotation,
  }) async {
    final TextEditingController ctrl =
        TextEditingController(text: rotation?.name ?? '');
    int color = rotation?.colorValue ?? _palette.first;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(rotation == null ? 'New rotation' : 'Edit rotation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Label, e.g. ICU1'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final int c in _palette)
                    GestureDetector(
                      onTap: () => setState(() => color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c),
                          border: Border.all(
                            color: color == c
                                ? Theme.of(ctx).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String name = ctrl.text.trim();
                if (name.isEmpty) return;
                final notifier = ref.read(shiftEditorProvider.notifier);
                if (rotation == null) {
                  notifier.addRotation(name, color);
                } else {
                  notifier.updateRotation(
                    rotation.copyWith(name: name, colorValue: color),
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
