import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';

/// A borderless, transparent text line that behaves like a document paragraph:
/// no visible box, and the "Write…" hint shows ONLY while this line has focus,
/// so empty unfocused lines are just blank space (Notion-style).
///
/// - Saves on focus-loss (never per keystroke) and bumps the note's updatedAt.
/// - Pressing Enter splits the line: text after the caret moves to a new line
///   below and the caret follows it (via [onSplit]).
/// - Backspace on an already-empty line asks the parent to delete it
///   ([onDeleteEmpty]) — best-effort; some soft keyboards swallow the key.
/// - [autofocus] focuses this line on first build (a freshly created line).
class TextBlockView extends ConsumerStatefulWidget {
  const TextBlockView({
    required this.block,
    this.onSplit,
    this.onDeleteEmpty,
    this.autofocus = false,
    super.key,
  });

  final NoteBlock block;

  /// Enter pressed: [after] is the text that should move to a new line below.
  final void Function(String after)? onSplit;
  final VoidCallback? onDeleteEmpty;
  final bool autofocus;

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
      if (mounted) setState(() {}); // toggle the focus-only hint
      if (!_focus.hasFocus) _save();
    });
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
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

  /// Detects a newline typed by any keyboard (hardware or IME) and turns it
  /// into a block split, so Enter starts a new line instead of growing a box.
  void _onChanged(String value) {
    final int nl = value.indexOf('\n');
    if (nl < 0 || widget.onSplit == null) return;
    final String before = value.substring(0, nl);
    final String after = value.substring(nl + 1);
    _ctrl.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
    _save(); // persist the (now newline-free) content of this line
    widget.onSplit!(after);
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
      onChanged: _onChanged,
      onTapOutside: (_) => _focus.unfocus(),
      style: TextStyle(fontSize: 16, height: 1.45, color: cs.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: _focus.hasFocus ? 'Write…' : null,
        hintStyle: TextStyle(color: cs.onSurface.withAlpha(90)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
