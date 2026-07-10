import 'package:flutter/material.dart';

import '../../../tasks/presentation/widgets/list_form_dialog.dart'
    show kListColorPresets;

/// Name + emoji + color form to create or rename a notebook.
///
/// Returns `(name, colorValue, icon)` on save, null on cancel.
Future<(String, int, String)?> showNotebookFormDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  int? initialColor,
  String initialIcon = '📓',
}) {
  return showDialog<(String, int, String)?>(
    context: context,
    builder: (context) => _NotebookFormDialog(
      title: title,
      initialName: initialName,
      initialColor: initialColor ?? kListColorPresets.first,
      initialIcon: initialIcon,
    ),
  );
}

/// A small curated set of notebook emojis (tap to pick; free typing also works).
const List<String> _kEmojiPresets = [
  '📓', '📔', '🩺', '💊', '🫀', '🧠', '🦴', '🧪', '📚', '⭐', '📝', '🔖',
];

class _NotebookFormDialog extends StatefulWidget {
  const _NotebookFormDialog({
    required this.title,
    required this.initialName,
    required this.initialColor,
    required this.initialIcon,
  });

  final String title;
  final String initialName;
  final int initialColor;
  final String initialIcon;

  @override
  State<_NotebookFormDialog> createState() => _NotebookFormDialogState();
}

class _NotebookFormDialogState extends State<_NotebookFormDialog> {
  late final TextEditingController _nameCtrl;
  late int _color;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _color = widget.initialColor;
    _icon = widget.initialIcon;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final String icon = _icon.trim().isEmpty ? '📓' : _icon.trim();
    Navigator.of(context).pop((name, _color, icon));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Notebook name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            Text('Icon', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _kEmojiPresets.map((String e) {
                final bool selected = e == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: cs.primary, width: 2)
                          : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Color', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
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
