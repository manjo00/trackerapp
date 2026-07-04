import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/lists_providers.dart';
import 'list_form_dialog.dart';

/// Multi-select label chips for the task editor.
///
/// Renders every label as a FilterChip (colored dot + name); the trailing
/// "＋" chip creates a new label inline (name + color) and selects it.
class LabelPickerRow extends ConsumerWidget {
  const LabelPickerRow({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Label> labels =
        ref.watch(labelsProvider).valueOrNull ?? const [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final Label label in labels)
          FilterChip(
            avatar: Icon(Icons.circle, size: 12, color: Color(label.colorValue)),
            label: Text(label.name),
            selected: selected.contains(label.id),
            onSelected: (bool on) {
              final Set<int> next = Set<int>.from(selected);
              on ? next.add(label.id) : next.remove(label.id);
              onChanged(next);
            },
          ),
        ActionChip(
          avatar: Icon(Icons.add_rounded, size: 18, color: cs.primary),
          label: const Text('New label'),
          onPressed: () async {
            final (String, int)? result = await showListFormDialog(
              context,
              title: 'New label',
              hintText: 'e.g. errands',
            );
            if (result == null) return;
            final int id = await ref
                .read(listsRepositoryProvider)
                .addLabel(result.$1, result.$2);
            onChanged({...selected, id});
          },
        ),
      ],
    );
  }
}
