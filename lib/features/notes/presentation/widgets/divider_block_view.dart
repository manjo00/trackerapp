import 'package:flutter/material.dart';

/// A horizontal separator block. Not editable; reordered/deleted via the
/// editor's "Edit lines" mode.
class DividerBlockView extends StatelessWidget {
  const DividerBlockView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, thickness: 1.5, color: cs.outlineVariant),
    );
  }
}
