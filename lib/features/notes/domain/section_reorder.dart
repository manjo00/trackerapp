import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

int _level(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text ? b.headingLevel : 0;

bool _isCollapsedHeading(NoteBlock b) => _level(b) != 0 && b.collapsed;

/// New full top-to-bottom block-id order after an arrange-mode move of the
/// VISIBLE tile at [visOld] to [visNew] (this project's `onReorderItem`
/// pre-adjusted convention — removeAt then insert).
///
/// A dragged heading carries its **whole bed**: an expanded heading takes the
/// visible lines under it (until the next heading of the same or higher level);
/// a collapsed heading takes its hidden lines. Dropping a heading inside its own
/// section is a no-op (so it can't split). A plain line moves alone and is
/// re-parented by where it lands.
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

  final List<NoteBlock> visible = [
    for (final NoteBlock b in blocks)
      if (!hiddenIds.contains(b.id)) b
  ];
  final int n = visible.length;

  // Re-expand a visible order back to the full order (hidden children follow
  // their collapsed heading).
  List<int> expand(List<int> order) {
    final List<int> full = [];
    for (final int id in order) {
      full.add(id);
      final List<int>? kids = childrenOf[id];
      if (kids != null) full.addAll(kids);
    }
    return full;
  }

  final List<int> visIds = [for (final NoteBlock b in visible) b.id];
  if (visOld < 0 || visOld >= n) return expand(visIds);

  // Moving group in visible space: a heading takes its visible section; anything
  // else is a single tile.
  int g = 1;
  final int lvl = _level(visible[visOld]);
  if (lvl != 0) {
    for (int j = visOld + 1; j < n; j++) {
      final int jl = _level(visible[j]);
      if (jl != 0 && jl <= lvl) break;
      g++;
    }
  }

  // Dropping a group inside its own run is a no-op (prevents a heading splitting
  // across its own lines).
  if (visNew > visOld && visNew <= visOld + g - 1) return expand(visIds);

  final List<int> group = visIds.sublist(visOld, visOld + g);
  final List<int> rest = [...visIds]..removeRange(visOld, visOld + g);
  // The framework computed visNew as if ONE tile moved; we moved g, so targets
  // below the group shift left by (g-1).
  int insert = visNew <= visOld ? visNew : visNew - (g - 1);
  insert = insert.clamp(0, rest.length);
  rest.insertAll(insert, group);
  return expand(rest);
}
