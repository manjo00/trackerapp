import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../notes/data/models/note_block_type.dart';
import '../../../notes/domain/note_outline.dart';
import '../../../notes/domain/section_fold.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../notes/presentation/screens/photo_view_screen.dart';
import '../../../notes/presentation/widgets/checkbox_block_view.dart';
import '../../../notes/presentation/widgets/divider_block_view.dart';
import '../../../notes/presentation/widgets/heading_line_view.dart';
import '../../../notes/presentation/widgets/text_block_view.dart';
import '../../data/home_block_config.dart';
import '../providers/home_blocks_providers.dart';
import 'note_picker_sheet.dart';

/// Tallest the pinned card grows before its content scrolls internally.
const double kPinnedNoteMaxHeight = 320;

/// Per-level indent inside the card (tighter than the editor's 20).
const double _indentStep = 14;

/// A Home block that IS the note — a live mini-editor, not a preview. Type in
/// any line (saves on focus-loss like the editor), Enter splits to a new line,
/// backspace on an empty line deletes it, checkboxes tick (with note↔task
/// sync), headings fold/unfold, and ＋ buttons append lines. Long notes scroll
/// inside the card; ⤢ opens the full editor (formatting, photos, arrange live
/// there). If the note is gone or none is chosen, the card invites picking one.
class PinnedNoteBlock extends ConsumerStatefulWidget {
  const PinnedNoteBlock({required this.row, super.key});

  /// The home_blocks row (id for re-pointing, configJson for the note id).
  final HomeBlock row;

  @override
  ConsumerState<PinnedNoteBlock> createState() => _PinnedNoteBlockState();
}

class _PinnedNoteBlockState extends ConsumerState<PinnedNoteBlock> {
  /// A freshly created line grabs focus on its first build (same mechanism as
  /// the full editor), so the caret follows Enter-splits and ＋ adds.
  int? _focusRequestId;

  @override
  Widget build(BuildContext context) {
    final int? noteId = pinnedNoteIdFromConfig(widget.row.configJson);
    if (noteId == null) return _placeholder('Pick a note to pin');

    final Note? note = ref.watch(watchNoteProvider(noteId)).valueOrNull;
    if (note == null || note.archivedAt != null) {
      return _placeholder('Note unavailable — pick another');
    }

    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(noteId)).valueOrNull ?? const [];
    final SectionFold fold = computeSectionFold(blocks);
    final List<NoteBlock> visible = [
      for (final NoteBlock b in blocks)
        if (!fold.hiddenIds.contains(b.id)) b
    ];
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: kPinnedNoteMaxHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (visible.isEmpty)
                      InkWell(
                        onTap: () => _append(noteId, NoteBlockType.text,
                            blocks: blocks),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text('Tap to write…',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withAlpha(110))),
                        ),
                      )
                    else
                      for (final NoteBlock b in visible) _line(b, fold),
                  ],
                ),
              ),
            ),
            // Foot: add-line buttons + open-full-editor, one quiet row.
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 19,
                  tooltip: 'Add line',
                  icon: Icon(Icons.add_rounded,
                      color: cs.onSurface.withAlpha(140)),
                  onPressed: () =>
                      _append(noteId, NoteBlockType.text, blocks: blocks),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 19,
                  tooltip: 'Add checkbox',
                  icon: Icon(Icons.check_box_outlined,
                      color: cs.onSurface.withAlpha(140)),
                  onPressed: () =>
                      _append(noteId, NoteBlockType.checkbox, blocks: blocks),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 19,
                  tooltip: 'Open note',
                  icon: Icon(Icons.open_in_full_rounded,
                      color: cs.onSurface.withAlpha(140)),
                  onPressed: () => context.push('/notes/$noteId'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- editing (same DB paths as the full editor) ---------------------------

  Future<void> _append(int noteId, NoteBlockType type,
      {required List<NoteBlock> blocks}) async {
    final dao = ref.read(notesDaoProvider);
    final NoteBlock? last = blocks.isEmpty ? null : blocks.last;
    final int id = await dao.addBlock(
      noteId: noteId,
      type: type,
      content: '',
      orderIndex: blocks.length,
      indent: indentForInsertAfter(last),
    );
    await dao.touchNote(noteId, DateTime.now());
    if (mounted) setState(() => _focusRequestId = id);
  }

  Future<void> _split(NoteBlock current, String after) async {
    final dao = ref.read(notesDaoProvider);
    final int id = await dao.insertBlockAfter(
      noteId: current.noteId,
      type: NoteBlockType.parse(current.type),
      content: after,
      afterOrderIndex: current.orderIndex,
      indent: indentForInsertAfter(current),
    );
    await dao.touchNote(current.noteId, DateTime.now());
    if (mounted) setState(() => _focusRequestId = id);
  }

  Future<void> _deleteEmpty(NoteBlock b) async {
    final dao = ref.read(notesDaoProvider);
    await dao.deleteBlock(b.id);
    await dao.touchNote(b.noteId, DateTime.now());
  }

  Future<void> _toggleFold(NoteBlock b) async {
    final dao = ref.read(notesDaoProvider);
    await dao.setBlockCollapsed(b.id, !b.collapsed);
    await dao.touchNote(b.noteId, DateTime.now());
  }

  // ---- rendering ------------------------------------------------------------

  Widget _line(NoteBlock b, SectionFold fold) {
    final bool focusMe = b.id == _focusRequestId;
    final Widget child = switch (NoteBlockType.parse(b.type)) {
      NoteBlockType.divider => const DividerBlockView(),
      NoteBlockType.photo => _photo(b),
      NoteBlockType.checkbox => CheckboxBlockView(
          block: b,
          autofocus: focusMe,
          onSplit: (after) => _split(b, after),
          onDeleteEmpty: () => _deleteEmpty(b),
        ),
      NoteBlockType.text => b.headingLevel != 0
          ? HeadingLineView(
              block: b,
              hiddenCount: fold.hiddenCountByHeadingId[b.id] ?? 0,
              autofocus: focusMe,
              onToggle: () => _toggleFold(b),
              onSplit: (after) => _split(b, after),
              onDeleteEmpty: () => _deleteEmpty(b),
            )
          : TextBlockView(
              block: b,
              autofocus: focusMe,
              onSplit: (after) => _split(b, after),
              onDeleteEmpty: () => _deleteEmpty(b),
            ),
    };
    return Directionality(
      key: ValueKey(b.id),
      textDirection:
          lineStartsRtl(b.content ?? '') ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: b.indent * _indentStep),
        child: child,
      ),
    );
  }

  Widget _photo(NoteBlock b) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final images = ref.read(imageStorageServiceProvider);
    final String filename = b.content ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FutureBuilder<String>(
        future: images.resolvePath(filename),
        builder: (context, snap) {
          final String? path = snap.data;
          final bool exists =
              path != null && filename.isNotEmpty && File(path).existsSync();
          if (!exists) {
            return Row(children: [
              Icon(Icons.photo_outlined,
                  size: 16, color: cs.onSurface.withAlpha(110)),
              const SizedBox(width: 6),
              Text('Photo',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withAlpha(110))),
            ]);
          }
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => PhotoViewScreen(path: path)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(path),
                  height: 90, width: double.infinity, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(String text) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final Note? picked = await showNotePicker(context, ref);
          if (picked == null) return;
          await ref
              .read(homeBlocksDaoProvider)
              .updateConfig(widget.row.id, pinnedNoteConfig(picked.id));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.push_pin_outlined,
                  size: 18, color: cs.onSurface.withAlpha(120)),
              const SizedBox(width: 8),
              Text(text,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withAlpha(120))),
            ],
          ),
        ),
      ),
    );
  }
}
