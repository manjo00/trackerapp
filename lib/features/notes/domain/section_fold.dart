import '../../../core/database/app_database.dart';
import 'drag_drop.dart';

/// Which blocks are hidden by collapsed headings, and how many blocks are
/// folded under each visible collapsed heading (for a "· N hidden" label).
/// Pure — no I/O — so it is unit-testable.
class SectionFold {
  const SectionFold(this.hiddenIds, this.hiddenCountByHeadingId);

  final Set<int> hiddenIds;
  final Map<int, int> hiddenCountByHeadingId;
}

/// A collapsed, visible heading at indent `d` hides every following block whose
/// indent is greater than `d`, until a block with indent `<= d` (or the end of
/// the note). Membership is by [NoteBlock.indent], so a top-level line after a
/// bed ends that bed — which is what lets blocks live outside a heading.
/// Nested headings inside a hidden run stay hidden and their count rolls up to
/// the outermost visible collapsed heading.
SectionFold computeSectionFold(List<NoteBlock> blocks) {
  final Set<int> hidden = <int>{};
  final Map<int, int> counts = <int, int>{};
  // The open collapsed section, if any (a deeper collapsed heading inside it is
  // itself hidden, so one entry is enough).
  ({int id, int indent})? open;

  for (final NoteBlock b in blocks) {
    if (open != null && b.indent <= open.indent) open = null;
    if (open != null) {
      hidden.add(b.id);
      counts[open.id] = (counts[open.id] ?? 0) + 1;
    } else if (isHeadingBlock(b) && b.collapsed) {
      open = (id: b.id, indent: b.indent);
    }
  }
  return SectionFold(hidden, counts);
}
