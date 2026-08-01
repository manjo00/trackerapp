import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

int _level(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text ? b.headingLevel : 0;

/// How many blocks move together when the block at [index] is dragged: 1 for a
/// normal line, or — for a heading — the heading plus every following block
/// until the next heading of the same or higher level (its whole section).
int sectionGroupSize(List<NoteBlock> blocks, int index) {
  final int lvl = _level(blocks[index]);
  if (lvl == 0) return 1;
  int size = 1;
  for (int j = index + 1; j < blocks.length; j++) {
    final int jl = _level(blocks[j]);
    if (jl > 0 && jl <= lvl) break; // next same-or-higher heading ends it
    size++;
  }
  return size;
}

/// The new top-to-bottom block-id order after dragging the item at [oldIndex]
/// to [newIndex]. If that item is a heading, its whole section travels with it;
/// a normal line moves alone and is re-parented by where it lands (drop it after
/// another heading → under that heading; above all headings → top level).
///
/// [newIndex] uses this project's `onReorderItem` convention (the destination
/// index AFTER the single dragged item is removed — i.e. removeAt(old) then
/// insert(new)), matching the existing single-line reorder.
List<int> reorderWithSections(
    List<NoteBlock> blocks, int oldIndex, int newIndex) {
  final List<int> ids = [for (final NoteBlock b in blocks) b.id];
  final int k = sectionGroupSize(blocks, oldIndex);

  if (k == 1) {
    if (oldIndex == newIndex) return ids;
    final int moved = ids.removeAt(oldIndex);
    ids.insert(newIndex.clamp(0, ids.length), moved);
    return ids;
  }

  // Dropping inside the group's own tail (its still-present members) is a no-op.
  if (newIndex >= oldIndex && newIndex <= oldIndex + k - 2) return ids;

  final List<int> group = ids.sublist(oldIndex, oldIndex + k);
  final List<int> rest = [...ids]..removeRange(oldIndex, oldIndex + k);
  // The framework computed newIndex as if ONE item was removed; we removed k, so
  // targets below the group shift left by (k-1).
  int insert = newIndex <= oldIndex ? newIndex : newIndex - (k - 1);
  insert = insert.clamp(0, rest.length);
  rest.insertAll(insert, group);
  return rest;
}
