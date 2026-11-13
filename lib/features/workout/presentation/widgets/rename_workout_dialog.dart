import 'package:flutter/material.dart';

/// Asks for a workout's new name, filled in with [initialName] (selected, so
/// typing replaces it), and pops with the trimmed text, or null on Cancel.
///
/// The dialog owns its text controller, so the controller lives until the
/// dialog's closing animation has finished (disposing it as soon as
/// `showDialog` returns breaks the still-visible text field).
class RenameWorkoutDialog extends StatefulWidget {
  const RenameWorkoutDialog({super.key, required this.initialName});

  final String initialName;

  @override
  State<RenameWorkoutDialog> createState() => _RenameWorkoutDialogState();
}

class _RenameWorkoutDialogState extends State<RenameWorkoutDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialName.length,
        );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_ctrl.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Rename workout'),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          maxLength: 100, // a saved workout's name holds 1–100 characters
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _save(),
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
