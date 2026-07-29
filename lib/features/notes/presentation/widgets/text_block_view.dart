import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';

/// A borderless, auto-growing text block. Saves on focus-loss (never per
/// keystroke) and bumps the note's updatedAt. Pressing Backspace on an already
/// empty line asks the parent to delete this block (best-effort — some soft
/// keyboards swallow the key; "Edit lines" mode is the guaranteed delete path).
class TextBlockView extends ConsumerStatefulWidget {
  const TextBlockView({required this.block, this.onDeleteEmpty, super.key});

  final NoteBlock block;
  final VoidCallback? onDeleteEmpty;

  @override
  ConsumerState<TextBlockView> createState() => _TextBlockViewState();
}

class _TextBlockViewState extends ConsumerState<TextBlockView> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.block.content ?? '');
    _focus = FocusNode(onKeyEvent: _onKey);
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onDeleteEmpty != null &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrl.text.isEmpty) {
      widget.onDeleteEmpty!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(TextBlockView old) {
    super.didUpdateWidget(old);
    // Accept an external change ONLY when we're not actively editing, so a
    // sibling's stream re-emit never clobbers the user's in-progress text.
    final String incoming = widget.block.content ?? '';
    if (!_focus.hasFocus && incoming != _ctrl.text) {
      _ctrl.text = incoming;
    }
  }

  Future<void> _save() async {
    final String text = _ctrl.text;
    if (text == (widget.block.content ?? '')) return;
    final now = DateTime.now();
    final dao = ref.read(notesDaoProvider);
    await dao.updateBlockContent(widget.block.id, text);
    await dao.touchNote(widget.block.noteId, now);
    // Text lines never spawn tasks — only checkbox lines do (see
    // CheckboxBlockView). This keeps prose from becoming tasks.
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
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (_) => _focus.unfocus(),
      style: TextStyle(fontSize: 16, height: 1.45, color: cs.onSurface),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: 'Write…',
        hintStyle: TextStyle(color: cs.onSurface.withAlpha(90)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
