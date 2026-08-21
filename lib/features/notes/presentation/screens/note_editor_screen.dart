import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/note_block_type.dart';
import '../../domain/drag_drop.dart';
import '../../domain/note_outline.dart';
import '../../domain/note_text_style.dart';
import '../../domain/section_fold.dart';
import '../../../archive/presentation/archive_providers.dart';
import '../providers/notes_providers.dart';
import '../widgets/checkbox_block_view.dart';
import '../widgets/divider_block_view.dart';
import '../widgets/heading_line_view.dart';
import '../widgets/note_arrange_view.dart';
import '../widgets/photo_block_view.dart';
import '../widgets/text_block_view.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../coach/presentation/coach_target.dart';

/// The block editor for one note. The resting view is a clean, open page: a
/// title over a flowing stack of text / checkbox / photo blocks with no
/// per-line chrome. Reordering and deleting whole lines happen in "Edit lines"
/// mode (AppBar ⋮). A text/checkbox line can also be removed by backspacing on
/// an empty line. Auto-saves (blocks on focus-loss, title on focus-loss + on
/// leaving); an empty note is deleted on exit. ⋮ → Archive note puts it away
/// (Undo in the snackbar); ⋮ → Delete note sends it to Recently deleted, where
/// it waits 30 days before its rows, photos and auto-list are really gone.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({required this.noteId, super.key});

  final int noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  String _savedTitle = '';
  bool _deleted = false;
  bool _editingLines = false;

  /// The block id that should grab focus on the next build — set when a line is
  /// freshly created (toolbar add or Enter-split) so the caret follows it.
  int? _focusRequestId;

  /// The block currently being edited — drives the formatting toolbar. Null
  /// when no text/checkbox line is focused (→ the add-block bar shows).
  int? _focusedBlockId;

  @override
  void initState() {
    super.initState();
    _loadTitle();
    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) {
        // Editing the title → no formattable line; show the add-block bar.
        if (mounted) setState(() => _focusedBlockId = null);
      } else {
        _saveTitle();
      }
    });
  }

  Future<void> _loadTitle() async {
    final Note? note = await ref.read(notesDaoProvider).getNote(widget.noteId);
    if (!mounted || note == null) return;
    setState(() {
      _savedTitle = note.title;
      _titleCtrl.text = note.title;
    });
  }

  void _saveTitle() {
    if (_deleted) return;
    final String title = _titleCtrl.text;
    if (title == _savedTitle) return;
    _savedTitle = title;
    ref
        .read(notesDaoProvider)
        .updateNoteTitle(widget.noteId, title, DateTime.now());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  int get _nextOrder =>
      ref.read(noteBlocksProvider(widget.noteId)).valueOrNull?.length ?? 0;

  /// The block the toolbar's add actions should insert after (the focused
  /// line), or null to append at the end.
  NoteBlock? _addAnchor() {
    if (_focusedBlockId == null) return null;
    final List<NoteBlock> blocks =
        ref.read(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];
    return blocks.where((b) => b.id == _focusedBlockId).firstOrNull;
  }

  NoteBlock? _lastBlock() {
    final List<NoteBlock> list =
        ref.read(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];
    return list.isEmpty ? null : list.last;
  }

  Future<void> _addBlock(NoteBlockType type) async {
    final dao = ref.read(notesDaoProvider);
    final NoteBlock? anchor = _addAnchor();
    final int indent = indentForInsertAfter(anchor ?? _lastBlock());
    final int id = anchor != null
        ? await dao.insertBlockAfter(
            noteId: widget.noteId,
            type: type,
            content: '',
            afterOrderIndex: anchor.orderIndex,
            indent: indent,
          )
        : await dao.addBlock(
            noteId: widget.noteId,
            type: type,
            content: '',
            orderIndex: _nextOrder,
            indent: indent,
          );
    await dao.touchNote(widget.noteId, DateTime.now());
    if (mounted) setState(() => _focusRequestId = id);
  }

  /// Enter pressed inside [current]: start a new line of the same type below,
  /// carrying [after] (text past the caret), and move focus to it.
  Future<void> _splitBlock(NoteBlock current, String after) async {
    final dao = ref.read(notesDaoProvider);
    final int id = await dao.insertBlockAfter(
      noteId: widget.noteId,
      type: NoteBlockType.parse(current.type),
      content: after,
      afterOrderIndex: current.orderIndex,
      indent: indentForInsertAfter(current),
    );
    await dao.touchNote(widget.noteId, DateTime.now());
    if (mounted) setState(() => _focusRequestId = id);
  }

  Future<void> _addPhoto() async {
    // Capture the insert position NOW — the picker steals focus, which would
    // otherwise clear _focusedBlockId before the photo comes back.
    final NoteBlock? anchor = _addAnchor();
    final int end = _nextOrder;
    final int indent = indentForInsertAfter(anchor ?? _lastBlock());
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await ref
        .read(notesRepositoryProvider)
        .addPhotoBlock(
          widget.noteId,
          source,
          afterOrderIndex: anchor?.orderIndex,
          endOrderIndex: end,
          indent: indent,
          now: DateTime.now(),
        );
  }

  /// Deletes a single block (photo file cleaned up); its linked task, if any,
  /// is removed by the database's ON DELETE CASCADE.
  Future<void> _deleteBlock(NoteBlock b) async {
    if (b.type == NoteBlockType.photo.storageKey) {
      await ref
          .read(notesRepositoryProvider)
          .removePhotoBlock(b, now: DateTime.now());
    } else {
      final dao = ref.read(notesDaoProvider);
      await dao.deleteBlock(b.id);
      await dao.touchNote(b.noteId, DateTime.now());
    }
  }

  /// Puts the note away without asking — archiving is reversible, so the
  /// snackbar's Undo is a better answer than a confirm dialog. The messenger is
  /// captured before the pop so the snackbar survives leaving this screen.
  Future<void> _archiveNote() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ArchiveService svc = ref.read(archiveServiceProvider);
    _deleted = true; // stops the empty-note cleanup from also firing on exit
    await svc.archiveNote(widget.noteId, DateTime.now());
    messenger.showSnackBar(SnackBar(
      content: const Text('Note archived'),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
          label: 'Undo', onPressed: () => svc.restoreNote(widget.noteId)),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteNote() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'The note and its photos move to Recently deleted — you can restore '
          'them for 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _deleted = true;
    await ref
        .read(archiveServiceProvider)
        .trashNote(widget.noteId, DateTime.now());
    if (mounted) Navigator.of(context).pop();
  }

  /// Commits an arrange-mode drop (new order + new depths) in one write.
  Future<void> _applyArrangement(
    List<int> orderedIds,
    Map<int, int> indentById,
  ) async {
    final dao = ref.read(notesDaoProvider);
    await dao.applyArrangement(orderedIds, indentById);
    await dao.touchNote(widget.noteId, DateTime.now());
  }

  /// On leaving: save the title, prune phantom empty text lines (so blank
  /// fields never accumulate), then delete the note if nothing is left.
  Future<void> _onLeave() async {
    if (_deleted) return;
    _saveTitle();
    final dao = ref.read(notesDaoProvider);
    final repo = ref.read(notesRepositoryProvider);

    final List<NoteBlock> blocks = await dao.getBlocks(widget.noteId);
    for (final NoteBlock b in blocks) {
      if (NoteBlockType.parse(b.type) == NoteBlockType.text &&
          (b.content ?? '').trim().isEmpty) {
        await dao.deleteBlock(b.id);
      }
    }

    if (_titleCtrl.text.trim().isEmpty) {
      final List<NoteBlock> remaining = await dao.getBlocks(widget.noteId);
      if (remaining.isEmpty) await repo.deleteNoteWithPhotos(widget.noteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];

    // Nothing left to manage → drop back to the clean editor.
    if (_editingLines && blocks.isEmpty) _editingLines = false;

    return CoachMarks(
      screen: kCoachNoteEditor,
      child: PopScope(
        canPop: !_editingLines,
        onPopInvokedWithResult: (didPop, _) {
          if (_editingLines) {
            setState(() => _editingLines = false);
          } else if (didPop) {
            _onLeave();
          }
        },
        child: Scaffold(
          appBar: _editingLines ? _arrangeAppBar() : _normalAppBar(blocks),
          // Toolbar lives at the bottom of the BODY (not bottomNavigationBar) so
          // it rides directly on top of the keyboard and is never hidden by it.
          body: _editingLines
              ? _arrangeBody(blocks)
              : Column(
                  children: [
                    Expanded(child: _editorBody(blocks)),
                    _bottomBar(blocks),
                  ],
                ),
        ),
      ),
    );
  }

  /// The keyboard-accessory toolbar: a format row (only while a text/checkbox
  /// line is focused) stacked over an always-present add row. Wrapped in a
  /// [TextFieldTapRegion] so tapping it never unfocuses the active line.
  Widget _bottomBar(List<NoteBlock> blocks) {
    final NoteBlock? focused = _focusedBlockId == null
        ? null
        : blocks.where((b) => b.id == _focusedBlockId).firstOrNull;
    final NoteBlockType? kind = focused == null
        ? null
        : NoteBlockType.parse(focused.type);
    final bool formattable =
        kind == NoteBlockType.text || kind == NoteBlockType.checkbox;
    final dao = ref.read(notesDaoProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return TextFieldTapRegion(
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (formattable) ...[
                _FormatRow(
                  block: focused!,
                  isText: kind == NoteBlockType.text,
                  onHeading: (level) async {
                    await dao.setBlockFormat(focused.id, headingLevel: level);
                    // Becoming a heading adopts the lines below it; dropping
                    // back to body releases them one level.
                    await dao.reflowAfterHeadingChange(
                      widget.noteId,
                      focused.id,
                    );
                  },
                  onBold: () =>
                      dao.setBlockFormat(focused.id, bold: !focused.bold),
                  onItalic: () =>
                      dao.setBlockFormat(focused.id, italic: !focused.italic),
                  onHighlight: () => dao.setBlockFormat(
                    focused.id,
                    highlighted: !focused.highlighted,
                  ),
                ),
                Divider(height: 1, thickness: 1, color: cs.outlineVariant),
              ],
              _AddRow(
                onText: () => _addBlock(NoteBlockType.text),
                onCheckbox: () => _addBlock(NoteBlockType.checkbox),
                onPhoto: _addPhoto,
                onDivider: _addDividerBlock,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDividerBlock() async {
    final dao = ref.read(notesDaoProvider);
    final NoteBlock? anchor = _addAnchor();
    final int indent = indentForInsertAfter(anchor ?? _lastBlock());
    if (anchor != null) {
      await dao.insertBlockAfter(
        noteId: widget.noteId,
        type: NoteBlockType.divider,
        content: null,
        afterOrderIndex: anchor.orderIndex,
        indent: indent,
      );
    } else {
      await dao.addBlock(
        noteId: widget.noteId,
        type: NoteBlockType.divider,
        content: null,
        orderIndex: _nextOrder,
        indent: indent,
      );
    }
    await dao.touchNote(widget.noteId, DateTime.now());
  }

  /// Pick a template and splice its blocks in after the focused line (or at the
  /// end of the note when nothing is focused).
  Future<void> _pickTemplateToInsert() async {
    final List<Note> templates =
        ref.read(templatesProvider).valueOrNull ?? const [];
    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No templates yet — make one in Notes → Templates'),
          ),
        );
      }
      return;
    }
    final Note? chosen = await showModalBottomSheet<Note>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final Note t in templates)
              ListTile(
                leading: const Icon(Icons.dashboard_customize_rounded),
                title: Text(
                  t.title.trim().isEmpty ? 'Untitled template' : t.title,
                ),
                onTap: () => Navigator.of(c).pop(t),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    final NoteBlock? anchor = _addAnchor();
    final List<NoteBlock> blocks =
        ref.read(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];
    final int after = anchor?.orderIndex ?? (blocks.length - 1);
    await ref
        .read(notesRepositoryProvider)
        .insertTemplateInto(
          chosen.id,
          widget.noteId,
          after,
          now: DateTime.now(),
        );
  }

  /// Save the current note as a reusable template.
  Future<void> _saveAsTemplate() async {
    await ref
        .read(notesRepositoryProvider)
        .saveAsTemplate(widget.noteId, now: DateTime.now());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Templates')));
    }
  }

  // ---- Normal (clean) editor ------------------------------------------------

  AppBar _normalAppBar(List<NoteBlock> blocks) {
    final bool hasHeading = blocks.any(
      (b) =>
          NoteBlockType.parse(b.type) == NoteBlockType.text &&
          b.headingLevel != 0,
    );
    return AppBar(
      title: const Text('Note'),
      actions: [
        if (blocks.isNotEmpty)
          CoachTarget(
            id: 'noteEditor.arrange',
            child: IconButton(
              icon: const Icon(Icons.swap_vert_rounded),
              tooltip: 'Rearrange',
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _editingLines = true);
              },
            ),
          ),
        CoachTarget(
          id: 'noteEditor.menu',
          child: PopupMenuButton<String>(
            onSelected: (v) async {
              final dao = ref.read(notesDaoProvider);
              switch (v) {
                case 'collapse_all':
                  await dao.setAllHeadingsCollapsed(widget.noteId, true);
                  await dao.touchNote(widget.noteId, DateTime.now());
                case 'expand_all':
                  await dao.setAllHeadingsCollapsed(widget.noteId, false);
                  await dao.touchNote(widget.noteId, DateTime.now());
                case 'insert_template':
                  _pickTemplateToInsert();
                case 'save_template':
                  _saveAsTemplate();
                case 'archive':
                  _archiveNote();
                case 'delete':
                  _deleteNote();
              }
            },
            itemBuilder: (context) => [
              if (hasHeading) ...[
                const PopupMenuItem(
                  value: 'collapse_all',
                  child: Text('Collapse all'),
                ),
                const PopupMenuItem(
                  value: 'expand_all',
                  child: Text('Expand all'),
                ),
              ],
              const PopupMenuItem(
                value: 'insert_template',
                child: Text('Insert template'),
              ),
              const PopupMenuItem(
                value: 'save_template',
                child: Text('Save as template'),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Text('Archive note'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete note')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editorBody(List<NoteBlock> blocks) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SectionFold fold = computeSectionFold(blocks);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        TextField(
          controller: _titleCtrl,
          focusNode: _titleFocus,
          textCapitalization: TextCapitalization.sentences,
          onTapOutside: (_) => _titleFocus.unfocus(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Title',
            hintStyle: TextStyle(color: cs.onSurface.withAlpha(80)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        const SizedBox(height: 8),
        if (blocks.isEmpty)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _addBlock(NoteBlockType.text),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Tap here to start writing…',
                style: TextStyle(color: cs.onSurface.withAlpha(110)),
              ),
            ),
          )
        else
          for (final NoteBlock b in blocks)
            if (!fold.hiddenIds.contains(b.id))
              Directionality(
                key: ValueKey(b.id),
                textDirection: lineStartsRtl(b.content ?? '')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: b.indent * kNoteIndentStep,
                    top: 1,
                    bottom: 1,
                  ),
                  child: _blockWidget(b, fold),
                ),
              ),
      ],
    );
  }

  Widget _blockWidget(NoteBlock b, SectionFold fold) {
    final bool focusMe = b.id == _focusRequestId;
    switch (NoteBlockType.parse(b.type)) {
      case NoteBlockType.text:
        if (b.headingLevel != 0) {
          return HeadingLineView(
            block: b,
            hiddenCount: fold.hiddenCountByHeadingId[b.id] ?? 0,
            autofocus: focusMe,
            onToggle: () async {
              final dao = ref.read(notesDaoProvider);
              await dao.setBlockCollapsed(b.id, !b.collapsed);
              await dao.touchNote(b.noteId, DateTime.now());
            },
            onSplit: (after) => _splitBlock(b, after),
            onDeleteEmpty: () => _deleteBlock(b),
            onFocus: (id) => setState(() => _focusedBlockId = id),
            onBlur: () => setState(() => _focusedBlockId = null),
          );
        }
        return TextBlockView(
          block: b,
          autofocus: focusMe,
          onSplit: (after) => _splitBlock(b, after),
          onDeleteEmpty: () => _deleteBlock(b),
          onFocus: (id) => setState(() => _focusedBlockId = id),
          onBlur: () => setState(() => _focusedBlockId = null),
        );
      case NoteBlockType.checkbox:
        return CheckboxBlockView(
          block: b,
          autofocus: focusMe,
          onSplit: (after) => _splitBlock(b, after),
          onDeleteEmpty: () => _deleteBlock(b),
          onFocus: (id) => setState(() => _focusedBlockId = id),
          onBlur: () => setState(() => _focusedBlockId = null),
        );
      case NoteBlockType.photo:
        return PhotoBlockView(
          block: b,
          onRemove: () => _deleteBlock(b),
          onCrop: () => ref
              .read(notesRepositoryProvider)
              .cropPhotoBlock(b, now: DateTime.now()),
        );
      case NoteBlockType.divider:
        return const DividerBlockView();
    }
  }

  // ---- "Edit lines" mode (reorder + delete) ---------------------------------

  AppBar _arrangeAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.check_rounded),
        tooltip: 'Done',
        onPressed: () => setState(() => _editingLines = false),
      ),
      title: const Text('Arrange'),
    );
  }

  // ---- In-place "Arrange" mode (clean-lift reorder + delete) ----------------

  Widget _arrangeBody(List<NoteBlock> blocks) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
          child: Row(
            children: [
              Icon(
                Icons.open_with_rounded,
                size: 15,
                color: cs.onSurface.withAlpha(120),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hold to drag · drop in a gap to move it out · hold over a '
                  'heading to put it inside',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(140),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: NoteArrangeView(
            blocks: blocks,
            onApply: _applyArrangement,
            onEnterBed: (id) =>
                ref.read(notesDaoProvider).setBlockCollapsed(id, false),
            tileBuilder: _arrangeTile,
          ),
        ),
      ],
    );
  }

  /// One arrange-mode row: the block rendered read-only (so it looks like the
  /// note, not a boxy list) plus a delete badge, indented to its outline depth.
  /// [highlighted] tints the bed you just entered by holding over its header.
  Widget _arrangeTile(NoteBlock b, int hiddenCount, bool highlighted) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isHeading = isHeadingBlock(b);
    return Directionality(
      textDirection: lineStartsRtl(b.content ?? '')
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsetsDirectional.only(
          start: b.indent * kNoteIndentStep,
          top: 2,
          bottom: 2,
        ),
        decoration: BoxDecoration(
          color: highlighted
              ? cs.primaryContainer.withAlpha(90)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isHeading)
                InkResponse(
                  onTap: () async {
                    final dao = ref.read(notesDaoProvider);
                    await dao.setBlockCollapsed(b.id, !b.collapsed);
                    await dao.touchNote(b.noteId, DateTime.now());
                  },
                  radius: 20,
                  child: Icon(
                    b.collapsed
                        ? Icons.chevron_right_rounded
                        : Icons.expand_more_rounded,
                    color: cs.onSurface.withAlpha(140),
                  ),
                ),
              Expanded(child: _arrangePreview(b)),
              if (b.collapsed && hiddenCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '· $hiddenCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(130),
                    ),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.remove_circle_rounded,
                  size: 22,
                  color: cs.error.withAlpha(210),
                ),
                tooltip: 'Delete line',
                onPressed: () => _deleteBlock(b),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A read-only rendering of a block for arrange mode — same fonts/weights as
  /// the live editor, but inert plain widgets, so a long-press starts a drag
  /// instead of editing text.
  Widget _arrangePreview(NoteBlock b) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    switch (NoteBlockType.parse(b.type)) {
      case NoteBlockType.divider:
        return const DividerBlockView();
      case NoteBlockType.photo:
        return _arrangePhoto(b.content ?? '');
      case NoteBlockType.checkbox:
        final bool checked = b.checked;
        final Widget row = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
              child: Container(
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
            Expanded(
              child: Text(
                b.content ?? '',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: b.bold ? FontWeight.w700 : FontWeight.w400,
                  fontStyle: b.italic ? FontStyle.italic : FontStyle.normal,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? cs.onSurface.withAlpha(120) : cs.onSurface,
                ),
              ),
            ),
          ],
        );
        return b.highlighted ? _highlightWrap(row, cs) : row;
      case NoteBlockType.text:
        final Widget t = Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            b.content ?? '',
            style: TextStyle(
              fontSize: noteHeadingFontSize(b.headingLevel),
              height: 1.4,
              fontWeight: (b.headingLevel != 0 || b.bold)
                  ? FontWeight.w700
                  : FontWeight.w400,
              fontStyle: b.italic ? FontStyle.italic : FontStyle.normal,
              color: cs.onSurface,
            ),
          ),
        );
        return b.highlighted ? _highlightWrap(t, cs) : t;
    }
  }

  Widget _highlightWrap(Widget child, ColorScheme cs) => Container(
    decoration: BoxDecoration(
      color: cs.tertiaryContainer.withAlpha(150),
      borderRadius: BorderRadius.circular(6),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: child,
  );

  /// A compact, tap-inert photo thumbnail for arrange mode.
  Widget _arrangePhoto(String filename) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final images = ref.read(imageStorageServiceProvider);
    return FutureBuilder<String>(
      future: images.resolvePath(filename),
      builder: (context, snap) {
        final String? path = snap.data;
        if (path == null) return const SizedBox(height: 60);
        final bool exists = filename.isNotEmpty && File(path).existsSync();
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: exists
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: Image.file(
                    File(path),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  height: 60,
                  width: double.infinity,
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
        );
      },
    );
  }
}

/// The always-present add row: insert a Text / Checkbox / Photo / Divider block
/// (after the focused line), or open the template picker.
class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.onText,
    required this.onCheckbox,
    required this.onPhoto,
    required this.onDivider,
  });

  final VoidCallback onText;
  final VoidCallback onCheckbox;
  final VoidCallback onPhoto;
  final VoidCallback onDivider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Text',
            onPressed: onText,
            icon: const Icon(Icons.notes_rounded),
          ),
          IconButton(
            tooltip: 'Checkbox',
            onPressed: onCheckbox,
            icon: const Icon(Icons.check_box_outlined),
          ),
          IconButton(
            tooltip: 'Photo',
            onPressed: onPhoto,
            icon: const Icon(Icons.photo_camera_rounded),
          ),
          IconButton(
            tooltip: 'Divider',
            onPressed: onDivider,
            icon: const Icon(Icons.horizontal_rule_rounded),
          ),
        ],
      ),
    );
  }
}

/// The format row, shown above the add row while a text/checkbox line is
/// focused. Cycles heading level (text only) and toggles bold/italic/highlight.
class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.block,
    required this.isText,
    required this.onHeading,
    required this.onBold,
    required this.onItalic,
    required this.onHighlight,
  });

  final NoteBlock block;
  final bool isText;
  final void Function(int level) onHeading;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onHighlight;

  static String _headingLabel(int l) => switch (l) {
    1 => 'H1',
    2 => 'H2',
    3 => 'H3',
    _ => 'Body',
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    Widget toggle(IconData icon, bool on, VoidCallback onTap, String tip) =>
        IconButton(
          tooltip: tip,
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: on ? cs.secondaryContainer : null,
            foregroundColor: on ? cs.onSecondaryContainer : cs.onSurfaceVariant,
          ),
        );

    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isText)
            TextButton.icon(
              onPressed: () => onHeading((block.headingLevel + 1) % 4),
              icon: const Icon(Icons.title_rounded, size: 20),
              label: Text(_headingLabel(block.headingLevel)),
            ),
          toggle(Icons.format_bold_rounded, block.bold, onBold, 'Bold'),
          toggle(Icons.format_italic_rounded, block.italic, onItalic, 'Italic'),
          toggle(
            Icons.highlight_rounded,
            block.highlighted,
            onHighlight,
            'Highlight',
          ),
        ],
      ),
    );
  }
}
