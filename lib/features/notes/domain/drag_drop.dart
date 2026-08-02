import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// A heading block — the only kind that owns a "bed" (a nested section).
bool isHeadingBlock(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text && b.headingLevel != 0;

/// How many blocks travel with the block at [index]: 1 for a plain line, or a
/// heading plus every following block nested under it (indent greater than its
/// own). Membership is by [NoteBlock.indent].
int bedSize(List<NoteBlock> list, int index) {
  if (index < 0 || index >= list.length) return 1;
  if (!isHeadingBlock(list[index])) return 1;
  final int d = list[index].indent;
  int n = 1;
  for (int j = index + 1; j < list.length; j++) {
    if (list[j].indent <= d) break;
    n++;
  }
  return n;
}

/// Id of the innermost heading containing the block at [index]; null = top level.
int? containerIdOf(List<NoteBlock> list, int index) {
  if (index < 0 || index >= list.length) return null;
  final int d = list[index].indent;
  if (d == 0) return null;
  for (int j = index - 1; j >= 0; j--) {
    if (list[j].indent < d) {
      return isHeadingBlock(list[j]) ? list[j].id : null;
    }
  }
  return null;
}

/// Where a dragged block will land: [gap] = insert-before index in the list the
/// drag is measured against, [indent] = its new outline depth.
class DropPlan {
  const DropPlan(this.gap, this.indent, this.enteredBedId);

  final int gap;
  final int indent;
  final int? enteredBedId;
}

/// Decides the landing spot. **Out is easy, in is deliberate:** dropping in any
/// gap keeps you at the top level (and never splits a bed — a drop inside a bed
/// you don't belong to snaps to just after it). To nest INTO a bed you must have
/// entered it by holding over its header ([enteredBedId]). Reordering inside
/// your own bed keeps you there.
DropPlan resolveDrop({
  required List<NoteBlock> rest,
  required int? originalContainerId,
  required int gap,
  required int? enteredBedId,
}) {
  final int g0 = gap.clamp(0, rest.length);

  // Deliberately entered a bed → land inside it, one level deeper.
  if (enteredBedId != null) {
    final int bi = rest.indexWhere((b) => b.id == enteredBedId);
    if (bi >= 0 && isHeadingBlock(rest[bi])) {
      final int end = bi + bedSize(rest, bi);
      return DropPlan(g0.clamp(bi + 1, end), rest[bi].indent + 1, enteredBedId);
    }
  }

  if (g0 == 0) return const DropPlan(0, 0, null);
  final NoteBlock above = rest[g0 - 1];

  if (isHeadingBlock(above)) {
    // Returning to the bed you came from as its first child is allowed.
    if (above.id == originalContainerId) {
      return DropPlan(g0, above.indent + 1, null);
    }
    // Otherwise you'd be entering a bed without holding → land after it.
    return DropPlan((g0 - 1) + bedSize(rest, g0 - 1), 0, null);
  }

  final int? aboveContainer = containerIdOf(rest, g0 - 1);
  // Same bed you started in → a plain reorder among your siblings.
  if (aboveContainer == originalContainerId) {
    return DropPlan(g0, above.indent, null);
  }
  if (aboveContainer == null) return DropPlan(g0, 0, null);
  // Landed among another bed's lines without holding → snap out, after that bed.
  final int ci = rest.indexWhere((b) => b.id == aboveContainer);
  if (ci < 0) return DropPlan(g0, 0, null);
  return DropPlan(ci + bedSize(rest, ci), 0, null);
}

/// The new order + indent for every block after a drop.
class Arrangement {
  const Arrangement(this.orderedIds, this.indentById, this.plan);

  final List<int> orderedIds;
  final Map<int, int> indentById;
  final DropPlan plan;
}

/// Applies a drop to the whole note. [gap] is measured in VISIBLE blocks with
/// the dragged group removed; hidden blocks travel with their collapsed heading.
Arrangement? applyDrop({
  required List<NoteBlock> full,
  required Set<int> hiddenIds,
  required int draggedId,
  required int gap,
  required int? enteredBedId,
}) {
  final int di = full.indexWhere((b) => b.id == draggedId);
  if (di < 0) return null;

  final int gsize = bedSize(full, di);
  final List<NoteBlock> group = full.sublist(di, di + gsize);
  final Set<int> groupIds = {for (final NoteBlock b in group) b.id};
  final List<NoteBlock> restFull = [...full]..removeRange(di, di + gsize);
  final List<NoteBlock> restVisible = [
    for (final NoteBlock b in restFull)
      if (!hiddenIds.contains(b.id)) b
  ];

  final DropPlan plan = resolveDrop(
    rest: restVisible,
    originalContainerId: containerIdOf(full, di),
    gap: gap,
    enteredBedId: enteredBedId,
  );

  int insertAt = restFull.length;
  if (plan.gap < restVisible.length) {
    final int at =
        restFull.indexWhere((b) => b.id == restVisible[plan.gap].id);
    if (at >= 0) insertAt = at;
  }

  final int delta = plan.indent - full[di].indent;
  final List<NoteBlock> out = [...restFull]..insertAll(insertAt, group);
  return Arrangement(
    [for (final NoteBlock b in out) b.id],
    {
      for (final NoteBlock b in out)
        b.id: groupIds.contains(b.id)
            ? (b.indent + delta).clamp(0, 9)
            : b.indent
    },
    plan,
  );
}
