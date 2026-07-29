import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/note_block_type.dart';
import '../../domain/block_label.dart';
import '../providers/notes_providers.dart';
import '../widgets/checkbox_block_view.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTitle();
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) _saveTitle();
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

  Future<void> _addBlock(NoteBlockType type) async {
    final dao = ref.read(notesDaoProvider);
    final int id = await dao.addBlock(
        noteId: widget.noteId, type: type, content: '', orderIndex: _nextOrder);
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
        .addPhotoBlock(widget.noteId, source, _nextOrder, now: DateTime.now());
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
        body: _editingLines ? _editLinesBody(blocks) : _editorBody(blocks),
        bottomNavigationBar: _editingLines
            ? null
            : _BlockToolbar(
                onText: () => _addBlock(NoteBlockType.text),
                onCheckbox: () => _addBlock(NoteBlockType.checkbox),
                onPhoto: _addPhoto,
              ),
      ),
    );
  }

  // ---- Normal (clean) editor ------------------------------------------------

  AppBar _normalAppBar(List<NoteBlock> blocks) {
    return AppBar(
      title: const Text('Note'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'reorder') {
              setState(() => _editingLines = true);
            } else if (v == 'delete') {
              _deleteNote();
            }
          },
          itemBuilder: (context) => [
            if (blocks.isNotEmpty)
              const PopupMenuItem(value: 'reorder', child: Text('Edit lines')),
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
        );
      case NoteBlockType.checkbox:
        return CheckboxBlockView(
          block: b,
          autofocus: focusMe,
          onSplit: (after) => _splitBlock(b, after),
          onDeleteEmpty: () => _deleteBlock(b),
        );
      case NoteBlockType.photo:
        return PhotoBlockView(block: b, onRemove: () => _deleteBlock(b));
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

class _BlockToolbar extends StatelessWidget {
  const _BlockToolbar({
    required this.onText,
    required this.onCheckbox,
    required this.onPhoto,
  });

  final VoidCallback onText;
  final VoidCallback onCheckbox;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: onText,
            icon: const Icon(Icons.notes_rounded, size: 20),
            label: const Text('Text'),
          ),
          TextButton.icon(
            onPressed: onCheckbox,
            icon: const Icon(Icons.check_box_outlined, size: 20),
            label: const Text('Checkbox'),
          ),
          TextButton.icon(
            onPressed: onPhoto,
            icon: const Icon(Icons.photo_camera_rounded, size: 20),
            label: const Text('Photo'),
          ),
        ],
      ),
    );
  }
}
