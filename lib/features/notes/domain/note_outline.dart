import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// Indentation applied per outline depth (leading side, direction-aware).
const double kNoteIndentStep = 20;

bool _isHeading(NoteBlock b) =>
    NoteBlockType.parse(b.type) == NoteBlockType.text && b.headingLevel != 0;

/// Outline depth of each block by id: 0 at the base margin, +1 for each heading
/// it sits under. A heading sits at its ancestors' depth; its lines sit one
/// deeper; a nested heading (H2 under H1) is one deeper again. Pure — the widget
/// turns depth into a leading indent. Drives "what belongs to what" and makes
/// dragging a line in/out of a section visible (its indent changes with where
/// it lands).
Map<int, int> blockDepths(List<NoteBlock> blocks) {
  final Map<int, int> depths = {};
  final List<int> stack = []; // heading levels of open ancestors
  for (final NoteBlock b in blocks) {
    if (_isHeading(b)) {
      while (stack.isNotEmpty && stack.last >= b.headingLevel) {
        stack.removeLast();
      }
      depths[b.id] = stack.length;
      stack.add(b.headingLevel);
    } else {
      depths[b.id] = stack.length;
    }
  }
  return depths;
}

/// Whether a line reads right-to-left, from its first strong-directional
/// character (Arabic/Hebrew → true; Latin/digits/empty → false). Lets each line
/// indent on its own leading side, so a mixed Arabic/English note looks
/// deliberate rather than randomly shifted.
bool lineStartsRtl(String text) => Bidi.startsWithRtl(text);
