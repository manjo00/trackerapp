import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../notes/data/models/note_block_type.dart';
import '../../../notes/domain/note_text_style.dart';
import '../../../notes/domain/section_fold.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../data/home_block_config.dart';
import '../providers/home_blocks_providers.dart';
import 'note_picker_sheet.dart';

/// How many note lines the Home card shows before "+N more".
const int kPinnedNotePreviewLines = 6;

/// A Home block that renders one chosen note's content inline — the note
/// itself, not a shortcut. Checkboxes tick right from Home (with the note↔task
/// sync the editor uses); tapping anywhere else opens the editor. If the note
/// is gone (deleted/archived) or none is chosen yet, the card invites picking
/// one instead of vanishing.
class PinnedNoteBlock extends ConsumerWidget {
  const PinnedNoteBlock({required this.row, super.key});

  /// The home_blocks row (id for re-pointing, configJson for the note id).
  final HomeBlock row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? noteId = pinnedNoteIdFromConfig(row.configJson);
    if (noteId == null) return _placeholder(context, ref, 'Pick a note to pin');

    final Note? note = ref.watch(watchNoteProvider(noteId)).valueOrNull;
    if (note == null || note.archivedAt != null) {
      return _placeholder(context, ref, 'Note unavailable — pick another');
    }

    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(noteId)).valueOrNull ?? const [];
    final SectionFold fold = computeSectionFold(blocks);
    final List<NoteBlock> visible = [
      for (final NoteBlock b in blocks)
        if (!fold.hiddenIds.contains(b.id)) b
    ];
    final List<NoteBlock> shown =
        visible.take(kPinnedNotePreviewLines).toList();
    final int more = visible.length - shown.length;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/notes/$noteId'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Empty note — tap to write',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurface.withAlpha(110))),
                )
              else
                for (final NoteBlock b in shown) _line(context, ref, b, cs),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+$more more',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withAlpha(120))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, WidgetRef ref, String text) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final Note? picked = await showNotePicker(context, ref);
          if (picked == null) return;
          await ref
              .read(homeBlocksDaoProvider)
              .updateConfig(row.id, pinnedNoteConfig(picked.id));
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

  /// One note line, compact: indent by outline depth, style by format flags.
  Widget _line(
      BuildContext context, WidgetRef ref, NoteBlock b, ColorScheme cs) {
    final Widget child = switch (NoteBlockType.parse(b.type)) {
      NoteBlockType.divider => Divider(
          height: 12, thickness: 1, color: cs.outlineVariant),
      NoteBlockType.photo => _photo(ref, b, cs),
      NoteBlockType.checkbox => _checkbox(ref, b, cs),
      NoteBlockType.text => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            b.content ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              // Slightly tighter than the editor so the card stays compact.
              fontSize: b.headingLevel == 0
                  ? 14
                  : noteHeadingFontSize(b.headingLevel) - 3,
              height: 1.35,
              fontWeight: (b.headingLevel != 0 || b.bold)
                  ? FontWeight.w700
                  : FontWeight.w400,
              fontStyle: b.italic ? FontStyle.italic : FontStyle.normal,
              color: cs.onSurface,
            ),
          ),
        ),
    };
    return Padding(
      padding: EdgeInsetsDirectional.only(start: b.indent * 12.0),
      child: child,
    );
  }

  Widget _checkbox(WidgetRef ref, NoteBlock b, ColorScheme cs) {
    final bool checked = b.checked;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkResponse(
            radius: 18,
            onTap: () async {
              // Same path as the editor: persist + keep any @time task in step.
              final dao = ref.read(notesDaoProvider);
              await dao.setBlockChecked(b.id, !checked);
              await dao.touchNote(b.noteId, DateTime.now());
              await ref
                  .read(noteTaskLinkerProvider)
                  .onBlockCheckedChanged(b, !checked);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 1, right: 8),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checked ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: checked ? cs.primary : cs.onSurface.withAlpha(90),
                    width: 2,
                  ),
                ),
                child: checked
                    ? Icon(Icons.check_rounded, size: 12, color: cs.onPrimary)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              b.content ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                decoration: checked ? TextDecoration.lineThrough : null,
                color:
                    checked ? cs.onSurface.withAlpha(120) : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(WidgetRef ref, NoteBlock b, ColorScheme cs) {
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path),
                height: 72, width: double.infinity, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
