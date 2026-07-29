import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';

/// A checklist line: a light circular checkbox + inline text. The "List item"
/// hint shows ONLY while focused, so empty unfocused items read as blank lines.
/// Ticking strikes through + dims. Text saves on focus-loss; the tick saves
/// immediately. Enter starts a new checklist item below ([onSplit]); backspace
/// on an empty line asks the parent to delete it ([onDeleteEmpty]).
class CheckboxBlockView extends ConsumerStatefulWidget {
  const CheckboxBlockView({
    required this.block,
    this.onSplit,
    this.onDeleteEmpty,
    this.onFocus,
    this.autofocus = false,
    super.key,
  });

  final NoteBlock block;
  final void Function(String after)? onSplit;
  final VoidCallback? onDeleteEmpty;

  /// Called with this block's id when it gains focus, so the editor can point
  /// the formatting toolbar at the active line.
  final void Function(int blockId)? onFocus;
  final bool autofocus;

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
    _focus = FocusNode(onKeyEvent: _onKey);
    _focus.addListener(() {
      if (mounted) setState(() {}); // toggle the focus-only hint
      if (_focus.hasFocus) {
        widget.onFocus?.call(widget.block.id);
      } else {
        _save();
      }
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

  void _onChanged(String value) {
    final int nl = value.indexOf('\n');
    if (nl < 0 || widget.onSplit == null) return;
    final String before = value.substring(0, nl);
    final String after = value.substring(nl + 1);
    _ctrl.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
    _save();
    widget.onSplit!(after);
  }

  @override
  void didUpdateWidget(CheckboxBlockView old) {
    super.didUpdateWidget(old);
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
    // Recognise / update / remove any "@time" task on this line.
    await ref
        .read(noteTaskLinkerProvider)
        .reconcileBlock(block: widget.block, content: text, now: now);
  }

  Future<void> _toggle() async {
    final bool checked = !widget.block.checked;
    final dao = ref.read(notesDaoProvider);
    await dao.setBlockChecked(widget.block.id, checked);
    await dao.touchNote(widget.block.noteId, DateTime.now());
    // Keep the linked task's completion in step with the tick.
    await ref
        .read(noteTaskLinkerProvider)
        .onBlockCheckedChanged(widget.block, checked);
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
    final NoteBlock b = widget.block;
    final bool checked = b.checked;

    final Row row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Light circular check — recedes visually until ticked.
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
          child: InkResponse(
            onTap: _toggle,
            radius: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: checked ? cs.primary : cs.onSurface.withAlpha(90),
                  width: 2,
                ),
              ),
              child: checked
                  ? Icon(Icons.check_rounded, size: 15, color: cs.onPrimary)
                  : null,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onChanged: _onChanged,
            onTapOutside: (_) => _focus.unfocus(),
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: b.bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: b.italic ? FontStyle.italic : FontStyle.normal,
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? cs.onSurface.withAlpha(120) : cs.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: _focus.hasFocus ? 'List item' : null,
              hintStyle: TextStyle(color: cs.onSurface.withAlpha(90)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );

    if (!b.highlighted) return row;
    return Container(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withAlpha(150),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: row,
    );
  }
}
