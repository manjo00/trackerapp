import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/note_block_type.dart';
import '../../domain/block_label.dart';
import '../providers/notes_providers.dart';
import '../widgets/checkbox_block_view.dart';
import '../widgets/divider_block_view.dart';
import '../widgets/photo_block_view.dart';
import '../widgets/text_block_view.dart';

/// The block editor for one note. The resting view is a clean, open page: a
/// title over a flowing stack of text / checkbox / photo blocks with no
/// per-line chrome. Reordering and deleting whole lines happen in "Edit lines"
/// mode (AppBar ⋮). A text/checkbox line can also be removed by backspacing on
/// an empty line. Auto-saves (blocks on focus-loss, title on focus-loss + on
/// leaving); an empty note is deleted on exit; ⋮ → Delete note removes it
/// (cascading its tasks + auto-list).
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

  Future<void> _addBlock(NoteBlockType type) async {
    final dao = ref.read(notesDaoProvider);
    final NoteBlock? anchor = _addAnchor();
    final int id = anchor != null
        ? await dao.insertBlockAfter(
            noteId: widget.noteId,
            type: type,
            content: '',
            afterOrderIndex: anchor.orderIndex)
        : await dao.addBlock(
            noteId: widget.noteId,
            type: type,
            content: '',
            orderIndex: _nextOrder);
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
    );
    await dao.touchNote(widget.noteId, DateTime.now());
    if (mounted) setState(() => _focusRequestId = id);
  }

  Future<void> _addPhoto() async {
    // Capture the insert position NOW — the picker steals focus, which would
    // otherwise clear _focusedBlockId before the photo comes back.
    final NoteBlock? anchor = _addAnchor();
    final int end = _nextOrder;
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
    await ref.read(notesRepositoryProvider).addPhotoBlock(
          widget.noteId,
          source,
          afterOrderIndex: anchor?.orderIndex,
          endOrderIndex: end,
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

  Future<void> _deleteNote() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
            'The note, its photos, and any tasks it created are deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    _deleted = true;
    await ref
        .read(notesRepositoryProvider)
        .deleteNoteWithPhotos(widget.noteId);
    if (mounted) Navigator.of(context).pop();
  }

  void _onReorder(List<NoteBlock> blocks, int oldIndex, int newIndex) {
    // onReorderItem gives newIndex already adjusted for the removed item.
    if (oldIndex == newIndex) return;
    final List<int> ids = blocks.map((b) => b.id).toList();
    final int moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    ref.read(notesDaoProvider).reorderBlocks(ids);
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

    return PopScope(
      canPop: !_editingLines,
      onPopInvokedWithResult: (didPop, _) {
        if (_editingLines) {
          setState(() => _editingLines = false);
        } else if (didPop) {
          _onLeave();
        }
      },
      child: Scaffold(
        appBar: _editingLines ? _editAppBar() : _normalAppBar(blocks),
        // Toolbar lives at the bottom of the BODY (not bottomNavigationBar) so
        // it rides directly on top of the keyboard and is never hidden by it.
        body: _editingLines
            ? _editLinesBody(blocks)
            : Column(
                children: [
                  Expanded(child: _editorBody(blocks)),
                  _bottomBar(blocks),
                ],
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
    final NoteBlockType? kind =
        focused == null ? null : NoteBlockType.parse(focused.type);
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
                  onHeading: (level) =>
                      dao.setBlockFormat(focused.id, headingLevel: level),
                  onBold: () =>
                      dao.setBlockFormat(focused.id, bold: !focused.bold),
                  onItalic: () =>
                      dao.setBlockFormat(focused.id, italic: !focused.italic),
                  onHighlight: () => dao.setBlockFormat(focused.id,
                      highlighted: !focused.highlighted),
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
    if (anchor != null) {
      await dao.insertBlockAfter(
          noteId: widget.noteId,
          type: NoteBlockType.divider,
          content: null,
          afterOrderIndex: anchor.orderIndex);
    } else {
      await dao.addBlock(
          noteId: widget.noteId,
          type: NoteBlockType.divider,
          content: null,
          orderIndex: _nextOrder);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No templates yet — make one in Notes → Templates')));
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
                    t.title.trim().isEmpty ? 'Untitled template' : t.title),
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
    await ref.read(notesRepositoryProvider).insertTemplateInto(
        chosen.id, widget.noteId, after,
        now: DateTime.now());
  }

  /// Save the current note as a reusable template.
  Future<void> _saveAsTemplate() async {
    await ref
        .read(notesRepositoryProvider)
        .saveAsTemplate(widget.noteId, now: DateTime.now());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved to Templates')));
    }
  }

  // ---- Normal (clean) editor ------------------------------------------------

  AppBar _normalAppBar(List<NoteBlock> blocks) {
    return AppBar(
      title: const Text('Note'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'reorder':
                setState(() => _editingLines = true);
              case 'insert_template':
                _pickTemplateToInsert();
              case 'save_template':
                _saveAsTemplate();
              case 'delete':
                _deleteNote();
            }
          },
          itemBuilder: (context) => [
            if (blocks.isNotEmpty)
              const PopupMenuItem(value: 'reorder', child: Text('Edit lines')),
            const PopupMenuItem(
                value: 'insert_template', child: Text('Insert template')),
            const PopupMenuItem(
                value: 'save_template', child: Text('Save as template')),
            const PopupMenuItem(value: 'delete', child: Text('Delete note')),
          ],
        ),
      ],
    );
  }

  Widget _editorBody(List<NoteBlock> blocks) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        TextField(
          controller: _titleCtrl,
          focusNode: _titleFocus,
          textCapitalization: TextCapitalization.sentences,
          onTapOutside: (_) => _titleFocus.unfocus(),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
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
            Padding(
              key: ValueKey(b.id),
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: _blockWidget(b),
            ),
      ],
    );
  }

  Widget _blockWidget(NoteBlock b) {
    final bool focusMe = b.id == _focusRequestId;
    switch (NoteBlockType.parse(b.type)) {
      case NoteBlockType.text:
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

  AppBar _editAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.check_rounded),
        tooltip: 'Done',
        onPressed: () => setState(() => _editingLines = false),
      ),
      title: const Text('Edit lines'),
    );
  }

  Widget _editLinesBody(List<NoteBlock> blocks) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Icon(Icons.drag_indicator_rounded,
                  size: 16, color: cs.onSurface.withAlpha(120)),
              const SizedBox(width: 6),
              Text('Drag to reorder · tap the bin to delete',
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(140))),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            itemCount: blocks.length,
            // onReorderItem gives newIndex already adjusted for the removed item.
            onReorderItem: (o, n) => _onReorder(blocks, o, n),
            itemBuilder: (context, i) {
              final NoteBlock b = blocks[i];
              return _ManageRow(
                key: ValueKey(b.id),
                index: i,
                block: b,
                onDelete: () => _deleteBlock(b),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A compact, non-editable row for "Edit lines" mode: type icon · one-line
/// label · delete, with the whole tile draggable (long-press) to reorder.
class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.index,
    required this.block,
    required this.onDelete,
    super.key,
  });

  final int index;
  final NoteBlock block;
  final VoidCallback onDelete;

  IconData get _icon => switch (NoteBlockType.parse(block.type)) {
        NoteBlockType.checkbox => Icons.check_box_outlined,
        NoteBlockType.photo => Icons.photo_outlined,
        NoteBlockType.divider => Icons.horizontal_rule_rounded,
        NoteBlockType.text => Icons.notes_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(_icon, size: 20, color: cs.onSurface.withAlpha(150)),
        title: Text(
          blockLabel(block),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: cs.onSurface.withAlpha(150)),
              tooltip: 'Delete line',
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded,
                  size: 22, color: cs.onSurface.withAlpha(120)),
            ),
          ],
        ),
      ),
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
              icon: const Icon(Icons.notes_rounded)),
          IconButton(
              tooltip: 'Checkbox',
              onPressed: onCheckbox,
              icon: const Icon(Icons.check_box_outlined)),
          IconButton(
              tooltip: 'Photo',
              onPressed: onPhoto,
              icon: const Icon(Icons.photo_camera_rounded)),
          IconButton(
              tooltip: 'Divider',
              onPressed: onDivider,
              icon: const Icon(Icons.horizontal_rule_rounded)),
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

  static String _headingLabel(int l) =>
      switch (l) { 1 => 'H1', 2 => 'H2', 3 => 'H3', _ => 'Body' };

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
            foregroundColor:
                on ? cs.onSecondaryContainer : cs.onSurfaceVariant,
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
          toggle(Icons.highlight_rounded, block.highlighted, onHighlight,
              'Highlight'),
        ],
      ),
    );
  }
}
