import 'package:flutter/material.dart';

/// Preset colors offered for lists and labels (Material-you-ish pastels).
const List<int> kListColorPresets = [
  0xFF8AB4F8, // blue (default)
  0xFFF28B82, // red
  0xFFFCAD70, // orange
  0xFFFDD663, // yellow
  0xFF81C995, // green
  0xFF78D9EC, // cyan
  0xFFC58AF9, // purple
  0xFFFF8BCB, // pink
];

/// Name + color form used to create or rename a list (or label).
///
/// Returns `(name, colorValue)` on save, null on cancel.
Future<(String, int)?> showListFormDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  int? initialColor,
  String hintText = 'Name',
}) {
  return showDialog<(String, int)?>(
    context: context,
    builder: (context) => _ListFormDialog(
      title: title,
      initialName: initialName,
      initialColor: initialColor ?? kListColorPresets.first,
      hintText: hintText,
    ),
  );
}

class _ListFormDialog extends StatefulWidget {
  const _ListFormDialog({
    required this.title,
    required this.initialName,
    required this.initialColor,
    required this.hintText,
  });

  final String title;
  final String initialName;
  final int initialColor;
  final String hintText;

  @override
  State<_ListFormDialog> createState() => _ListFormDialogState();
}

class _ListFormDialogState extends State<_ListFormDialog> {
  late final TextEditingController _nameCtrl;
  late int _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _color = widget.initialColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name, _color));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: widget.hintText),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kListColorPresets.map((int c) {
              final bool selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: cs.onSurface, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.black54)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
