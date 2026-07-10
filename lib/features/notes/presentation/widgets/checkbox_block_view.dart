import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';

/// A checklist line: a checkbox + inline text. Ticking strikes through and
/// dims the text. Text saves on focus-loss; the tick saves immediately.
class CheckboxBlockView extends ConsumerStatefulWidget {
  const CheckboxBlockView({required this.block, super.key});

  final NoteBlock block;

  @override
  ConsumerState<CheckboxBlockView> createState() => _CheckboxBlockViewState();
}

class _CheckboxBlockViewState extends ConsumerState<CheckboxBlockView> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.block.content ?? '');
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void didUpdateWidget(CheckboxBlockView old) {
    super.didUpdateWidget(old);
    final String incoming = widget.block.content ?? '';
    if (!_focus.hasFocus && incoming != _ctrl.text) {
      _ctrl.text = incoming;
    }
  }

  void _save() {
    final String text = _ctrl.text;
    if (text == (widget.block.content ?? '')) return;
    final dao = ref.read(notesDaoProvider);
    dao.updateBlockContent(widget.block.id, text);
    dao.touchNote(widget.block.noteId, DateTime.now());
  }

  void _toggle(bool? v) {
    final dao = ref.read(notesDaoProvider);
    dao.setBlockChecked(widget.block.id, v ?? false);
    dao.touchNote(widget.block.noteId, DateTime.now());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool checked = widget.block.checked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Checkbox(
            value: checked,
            visualDensity: VisualDensity.compact,
            onChanged: _toggle,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onTapOutside: (_) => _focus.unfocus(),
            style: TextStyle(
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? cs.onSurface.withAlpha(120) : cs.onSurface,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'List item',
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
      ],
    );
  }
}
