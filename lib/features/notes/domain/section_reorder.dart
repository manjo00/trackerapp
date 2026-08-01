import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

bool _isCollapsedHeading(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text &&
    b.headingLevel != 0 &&
    b.collapsed;

/// The new full top-to-bottom block-id order after arrange-mode moves a VISIBLE
/// tile from [visOld] to [visNew] (this project's `onReorderItem` pre-adjusted
/// convention — removeAt then insert). Blocks hidden under a collapsed heading
/// aren't shown as tiles; they travel with their heading, so folding a section
/// and dragging its heading moves the whole thing. Expanded lines move alone and
/// are re-parented by where they land (position decides the owning heading).
List<int> reorderVisible(
  List<NoteBlock> blocks,
  Set<int> hiddenIds,
  int visOld,
  int visNew,
) {
  // Each hidden block belongs under the most recent visible collapsed heading.
  final Map<int, List<int>> childrenOf = {};
  int? owner;
  for (final NoteBlock b in blocks) {
    if (hiddenIds.contains(b.id)) {
      if (owner != null) (childrenOf[owner] ??= []).add(b.id);
    } else {
      owner = _isCollapsedHeading(b) ? b.id : null;
    }
  }

  final List<int> visible = [
    for (final NoteBlock b in blocks)
      if (!hiddenIds.contains(b.id)) b.id
  ];
  if (visOld < 0 || visOld >= visible.length) {
    return [for (final NoteBlock b in blocks) b.id];
  }

  final int moved = visible.removeAt(visOld);
  visible.insert(visNew.clamp(0, visible.length), moved);

  // Re-expand: each visible id, followed by its hidden children (if any).
  final List<int> full = [];
  for (final int id in visible) {
    full.add(id);
    final List<int>? kids = childrenOf[id];
    if (kids != null) full.addAll(kids);
  }
  return full;
}
