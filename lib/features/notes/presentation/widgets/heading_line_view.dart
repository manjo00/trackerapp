import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import 'text_block_view.dart';

/// A heading row: a fold caret in the left gutter + the editable heading field,
/// with a muted "· N hidden" when the section is folded. Tapping the caret
/// folds/unfolds; tapping the text edits it (the caret avoids the tap conflict
/// between "toggle fold" and "place the caret to edit"). Used by the full
/// editor and the Home pinned-note card.
class HeadingLineView extends StatelessWidget {
  const HeadingLineView({
    required this.block,
    required this.hiddenCount,
    required this.onToggle,
    this.autofocus = false,
    this.onSplit,
    this.onDeleteEmpty,
    this.onFocus,
    this.onBlur,
    super.key,
  });

  final NoteBlock block;
  final int hiddenCount;
  final VoidCallback onToggle;
  final bool autofocus;
  final void Function(String after)? onSplit;
  final VoidCallback? onDeleteEmpty;
  final void Function(int blockId)? onFocus;
  final VoidCallback? onBlur;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 2),
          child: InkResponse(
            onTap: onToggle,
            radius: 20,
            child: Icon(
              block.collapsed
                  ? Icons.chevron_right_rounded
                  : Icons.expand_more_rounded,
              color: cs.onSurface.withAlpha(140),
            ),
          ),
        ),
        Expanded(
          child: TextBlockView(
            block: block,
            autofocus: autofocus,
            onSplit: onSplit,
            onDeleteEmpty: onDeleteEmpty,
            onFocus: onFocus,
            onBlur: onBlur,
          ),
        ),
        if (block.collapsed && hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Text(
              '· $hiddenCount hidden',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(130)),
            ),
          ),
      ],
    );
  }
}
