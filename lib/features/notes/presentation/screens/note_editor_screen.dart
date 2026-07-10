import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/note_block_type.dart';
import '../providers/notes_providers.dart';
import '../widgets/checkbox_block_view.dart';
import '../widgets/photo_block_view.dart';
import '../widgets/text_block_view.dart';

/// The block editor for one note: a title plus a stack of text / checkbox /
/// photo blocks. Auto-saves (blocks save themselves on focus-loss; the title
/// saves on focus-loss and on leaving). A note left completely empty — no
/// title and no blocks — is deleted on exit so abandoned "new note" taps don't
/// litter the notebook.
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
    await dao.addBlock(
        noteId: widget.noteId, type: type, content: '', orderIndex: _nextOrder);
    await dao.touchNote(widget.noteId, DateTime.now());
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

  Future<void> _removePhoto(NoteBlock block) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text('The image file is deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(notesRepositoryProvider)
        .removePhotoBlock(block, now: DateTime.now());
  }

  /// Saves the title and deletes the note if it ended up completely empty
  /// (no title and no blocks). Runs after the pop; providers are app-scoped so
  /// the captured refs stay valid past this widget's disposal.
  Future<void> _onLeave() async {
    _saveTitle();
    final dao = ref.read(notesDaoProvider);
    final repo = ref.read(notesRepositoryProvider);
    if (_titleCtrl.text.trim().isEmpty) {
      final List<NoteBlock> blocks = await dao.getBlocks(widget.noteId);
      if (blocks.isEmpty) {
        await repo.deleteNoteWithPhotos(widget.noteId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(widget.noteId)).valueOrNull ?? const [];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            TextField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              textCapitalization: TextCapitalization.sentences,
              onTapOutside: (_) => _titleFocus.unfocus(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
              ),
            ),
            const SizedBox(height: 4),
            if (blocks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Add a text line, a checkbox, or a photo below.',
                  style: TextStyle(color: cs.onSurface.withAlpha(120)),
                ),
              ),
            ...blocks.map(_blockWidget),
          ],
        ),
        bottomNavigationBar: _BlockToolbar(
          onText: () => _addBlock(NoteBlockType.text),
          onCheckbox: () => _addBlock(NoteBlockType.checkbox),
          onPhoto: _addPhoto,
        ),
      ),
    );
  }

  Widget _blockWidget(NoteBlock b) {
    switch (NoteBlockType.parse(b.type)) {
      case NoteBlockType.text:
        return TextBlockView(key: ValueKey(b.id), block: b);
      case NoteBlockType.checkbox:
        return CheckboxBlockView(key: ValueKey(b.id), block: b);
      case NoteBlockType.photo:
        return PhotoBlockView(
            key: ValueKey(b.id), block: b, onRemove: () => _removePhoto(b));
    }
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
