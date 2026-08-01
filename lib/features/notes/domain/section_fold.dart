import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// Which blocks are hidden by collapsed headings, and how many blocks are
/// folded under each visible collapsed heading (for a "· N hidden" label).
/// Pure — no I/O — so it is unit-testable.
class SectionFold {
  const SectionFold(this.hiddenIds, this.hiddenCountByHeadingId);

  final Set<int> hiddenIds;
  final Map<int, int> hiddenCountByHeadingId;
}

bool _isHeading(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text && b.headingLevel != 0;

/// A collapsed, visible heading hides every following block until the next
/// heading whose level is the same or higher (a smaller/equal level number), or
/// the end of the note. Headings nested inside a hidden run stay hidden, and
/// their fold count rolls up to the outermost visible collapsed heading.
SectionFold computeSectionFold(List<NoteBlock> blocks) {
  final Set<int> hidden = <int>{};
  final Map<int, int> counts = <int, int>{};
  // Open collapsed sections, innermost last. In practice at most one is ever
  // open (a deeper heading inside a collapsed run is itself hidden and never
  // pushed), but a stack keeps the rule obviously correct.
  final List<({int id, int level})> open = [];

  void hide(int id) {
    hidden.add(id);
    final int owner = open.last.id;
    counts[owner] = (counts[owner] ?? 0) + 1;
  }

  for (final NoteBlock b in blocks) {
    if (_isHeading(b)) {
      while (open.isNotEmpty && open.last.level >= b.headingLevel) {
        open.removeLast();
      }
      final bool hiddenHere = open.isNotEmpty;
      if (hiddenHere) hide(b.id);
      if (b.collapsed && !hiddenHere) {
        open.add((id: b.id, level: b.headingLevel));
      }
    } else if (open.isNotEmpty) {
      hide(b.id);
    }
  }
  return SectionFold(hidden, counts);
}
