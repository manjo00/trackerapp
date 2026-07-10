import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';

/// A borderless, auto-growing text block. Saves on focus-loss (never per
/// keystroke) and bumps the note's updatedAt.
class TextBlockView extends ConsumerStatefulWidget {
  const TextBlockView({required this.block, super.key});

  final NoteBlock block;

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
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
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

  void _save() {
    final String text = _ctrl.text;
    if (text == (widget.block.content ?? '')) return;
    final dao = ref.read(notesDaoProvider);
    dao.updateBlockContent(widget.block.id, text);
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
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (_) => _focus.unfocus(),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: 'Write…',
        contentPadding: EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}
