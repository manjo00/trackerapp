import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/drag_drop.dart';
import '../../domain/note_outline.dart';
import '../../domain/section_fold.dart';

/// How long you must hold a dragged block over a heading before you enter it.
const Duration kEnterBedHold = Duration(milliseconds: 500);

/// The arrange-mode drag surface.
///
/// Long-press a line to lift it; a heading **folds while you hold it** so its
/// whole bed travels as one tile (and reopens on release). Dropping in any gap
/// leaves the block at the top level — getting **out is easy** and a bed is
/// never split. To put a block **into** a bed you must hold it over that bed's
/// header for [kEnterBedHold]: the bed expands and highlights so you can see
/// inside and position it. A drop indicator shows the landing spot at its real
/// depth, and the list auto-scrolls near the edges.
class NoteArrangeView extends StatefulWidget {
  const NoteArrangeView({
    required this.blocks,
    required this.tileBuilder,
    required this.onApply,
    required this.onEnterBed,
    super.key,
  });

  /// All of the note's blocks, in order.
  final List<NoteBlock> blocks;

  /// Renders one row. [hiddenCount] is how many lines its fold hides;
  /// [highlighted] marks the bed you just entered.
  final Widget Function(NoteBlock block, int hiddenCount, bool highlighted)
      tileBuilder;

  /// Commit a drop: the new top-to-bottom order and each block's new depth.
  final void Function(List<int> orderedIds, Map<int, int> indentById) onApply;

  /// A bed was entered during a drag — persist its expansion so the result of
  /// the drop is visible.
  final void Function(int headingId) onEnterBed;

  @override
  State<NoteArrangeView> createState() => _NoteArrangeViewState();
}

class _NoteArrangeViewState extends State<NoteArrangeView> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _rowKeys = {};

  int? _draggingId;
  double _dragWidth = 320;

  /// Raw landing gap (used to commit) and the snapped preview shown on screen.
  int _gap = 0;
  int _previewGap = 0;
  int _previewIndent = 0;

  /// The bed entered by holding over its header, plus beds force-opened for it.
  int? _enteredBedId;
  final Set<int> _forceExpanded = {};

  int? _hoverHeadingId;
  Timer? _hoverTimer;
  Timer? _autoTimer;
  double _autoDelta = 0;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _autoTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Blocks as they behave *during* a drag: the grabbed heading is treated as
  /// folded (its bed rides along), and a bed entered by holding is opened.
  List<NoteBlock> get _effective {
    final int? dragging = _draggingId;
    if (dragging == null && _forceExpanded.isEmpty) return widget.blocks;
    return [
      for (final NoteBlock b in widget.blocks)
        if (b.id == dragging && isHeadingBlock(b))
          b.copyWith(collapsed: true)
        else if (_forceExpanded.contains(b.id))
          b.copyWith(collapsed: false)
        else
          b
    ];
  }

  // ---- drag lifecycle -------------------------------------------------------

  void _start(NoteBlock b) {
    final RenderBox? box =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    _dragWidth = (box?.size.width ?? 340) - 28;
    setState(() {
      _draggingId = b.id;
      _enteredBedId = null;
      _forceExpanded.clear();
      _gap = 0;
      _previewGap = 0;
      _previewIndent = b.indent;
    });
  }

  void _update(Offset pointer) {
    final List<NoteBlock> eff = _effective;
    final SectionFold fold = computeSectionFold(eff);
    final List<NoteBlock> visible = [
      for (final NoteBlock b in eff)
        if (!fold.hiddenIds.contains(b.id)) b
    ];

    int gap = 0;
    NoteBlock? under;
    for (final NoteBlock b in visible) {
      if (b.id == _draggingId) continue;
      final RenderBox? box =
          _rowKeys[b.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final double top = box.localToGlobal(Offset.zero).dy;
      final double bottom = top + box.size.height;
      if (pointer.dy > (top + bottom) / 2) gap++;
      if (pointer.dy >= top && pointer.dy <= bottom) under = b;
    }

    _updateHover(under, visible);
    _updateAutoScroll(pointer.dy);

    // Preview where it will actually land (snapped), at its real depth.
    final List<NoteBlock> rest = [
      for (final NoteBlock b in visible)
        if (b.id != _draggingId) b
    ];
    final int di = widget.blocks.indexWhere((b) => b.id == _draggingId);
    final DropPlan plan = resolveDrop(
      rest: rest,
      originalContainerId: di < 0 ? null : containerIdOf(widget.blocks, di),
      gap: gap,
      enteredBedId: _enteredBedId,
    );

    if (gap != _gap ||
        plan.gap != _previewGap ||
        plan.indent != _previewIndent) {
      setState(() {
        _gap = gap;
        _previewGap = plan.gap;
        _previewIndent = plan.indent;
      });
    }
  }

  /// Holding over a heading enters it; wandering out of the entered bed leaves.
  void _updateHover(NoteBlock? under, List<NoteBlock> visible) {
    final int? entered = _enteredBedId;
    if (entered != null && under != null) {
      final int i = visible.indexWhere((b) => b.id == under.id);
      final bool insideBed =
          under.id == entered || (i >= 0 && containerIdOf(visible, i) == entered);
      if (!insideBed) {
        setState(() {
          _forceExpanded.remove(entered);
          _enteredBedId = null;
        });
      }
    }

    final int? candidate =
        (under != null && isHeadingBlock(under) && under.id != _enteredBedId)
            ? under.id
            : null;
    if (candidate == _hoverHeadingId) return;
    _hoverHeadingId = candidate;
    _hoverTimer?.cancel();
    if (candidate == null) return;
    _hoverTimer = Timer(kEnterBedHold, () {
      if (!mounted || _draggingId == null) return;
      HapticFeedback.selectionClick();
      setState(() {
        _enteredBedId = candidate;
        _forceExpanded.add(candidate);
      });
    });
  }

  void _updateAutoScroll(double y) {
    final RenderBox? box =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final double top = box.localToGlobal(Offset.zero).dy;
    final double bottom = top + box.size.height;
    const double zone = 80;
    if (y < top + zone) {
      _autoDelta = -9;
    } else if (y > bottom - zone) {
      _autoDelta = 9;
    } else {
      _autoDelta = 0;
      _autoTimer?.cancel();
      _autoTimer = null;
      return;
    }
    _autoTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients) return;
      final ScrollPosition pos = _scroll.position;
      final double target = (pos.pixels + _autoDelta)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (target != pos.pixels) pos.jumpTo(target);
    });
  }

  void _finish() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _autoTimer?.cancel();
    _autoTimer = null;

    final int? dragged = _draggingId;
    if (dragged != null) {
      final SectionFold fold = computeSectionFold(_effective);
      final Arrangement? a = applyDrop(
        full: widget.blocks,
        hiddenIds: fold.hiddenIds,
        draggedId: dragged,
        gap: _gap,
        enteredBedId: _enteredBedId,
      );
      if (a != null) {
        widget.onApply(a.orderedIds, a.indentById);
        final int? bed = a.plan.enteredBedId;
        if (bed != null) widget.onEnterBed(bed);
      }
    }
    setState(() {
      _draggingId = null;
      _enteredBedId = null;
      _hoverHeadingId = null;
      _forceExpanded.clear();
    });
  }

  // ---- rendering ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<NoteBlock> eff = _effective;
    final SectionFold fold = computeSectionFold(eff);
    final List<NoteBlock> visible = [
      for (final NoteBlock b in eff)
        if (!fold.hiddenIds.contains(b.id)) b
    ];

    final List<Widget> children = [];
    int vi = 0;
    for (int i = 0; i < visible.length; i++) {
      final NoteBlock b = visible[i];
      final bool isDragged = b.id == _draggingId;
      if (!isDragged) {
        if (_draggingId != null && vi == _previewGap) {
          children.add(_indicator(cs));
        }
        vi++;
      }
      children.add(_row(b, i, fold, visible));
    }
    if (_draggingId != null && vi == _previewGap) children.add(_indicator(cs));

    return SizedBox(
      key: _viewportKey,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _indicator(ColorScheme cs) => Padding(
        padding: EdgeInsetsDirectional.only(
            start: _previewIndent * kNoteIndentStep, top: 3, bottom: 3),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _row(
      NoteBlock b, int index, SectionFold fold, List<NoteBlock> visible) {
    final int hiddenCount = fold.hiddenCountByHeadingId[b.id] ?? 0;
    final int? entered = _enteredBedId;
    final bool highlighted = entered != null &&
        (b.id == entered || containerIdOf(visible, index) == entered);
    final GlobalKey key = _rowKeys.putIfAbsent(b.id, () => GlobalKey());

    return LongPressDraggable<int>(
      data: b.id,
      axis: Axis.vertical,
      hapticFeedbackOnStart: true,
      feedback: _feedback(b, hiddenCount),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () => _start(b),
      onDragUpdate: (d) => _update(d.globalPosition),
      onDragEnd: (_) => _finish(),
      child: KeyedSubtree(
        key: key,
        child: widget.tileBuilder(b, hiddenCount, highlighted),
      ),
    );
  }

  /// The lifted tile: the row itself on a raised, rounded surface.
  Widget _feedback(NoteBlock b, int hiddenCount) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _dragWidth,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: widget.tileBuilder(b, hiddenCount, false),
      ),
    );
  }
}
