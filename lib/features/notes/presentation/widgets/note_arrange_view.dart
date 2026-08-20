import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/drag_drop.dart';
import '../../domain/note_outline.dart';
import '../../domain/section_fold.dart';

/// How long you must hold a dragged block over a heading before you enter it.
const Duration kEnterBedHold = Duration(milliseconds: 500);

/// A measured row: where it sits on screen right now.
class _Geom {
  const _Geom(this.block, this.top, this.bottom);
  final NoteBlock block;
  final double top;
  final double bottom;
  double get center => (top + bottom) / 2;
}

/// The arrange-mode drag surface.
///
/// Long-press a line to lift it; a heading **folds while you hold it** so its
/// whole bed travels as one tile. Dropping in any gap leaves the block at the
/// top level — getting **out is easy** and a bed is never split. To put a block
/// **into** a bed, hold it over that bed's header for [kEnterBedHold]: the bed
/// expands and highlights so you can see inside and position it.
///
/// The row list is deliberately **structurally stable** during a drag — rows
/// are keyed and the drop indicator is painted in an overlay rather than
/// inserted between rows. Rebuilding the list mid-drag would detach the row
/// keys this widget measures with and cancel the hold-to-enter timer.
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
  /// the drop stays visible.
  final void Function(int headingId) onEnterBed;

  @override
  State<NoteArrangeView> createState() => _NoteArrangeViewState();
}

class _NoteArrangeViewState extends State<NoteArrangeView> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _surfaceKey = GlobalKey();
  final Map<int, GlobalKey> _rowKeys = {};

  int? _draggingId;

  /// Landing gap in "visible rows minus the dragged one" space, plus the
  /// on-screen preview of where that actually resolves to.
  int _gap = 0;
  int _previewIndent = 0;
  double? _indicatorY;

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

  List<NoteBlock> _visibleOf(List<NoteBlock> eff) {
    final SectionFold fold = computeSectionFold(eff);
    return [
      for (final NoteBlock b in eff)
        if (!fold.hiddenIds.contains(b.id)) b
    ];
  }

  // ---- drag lifecycle -------------------------------------------------------

  void _start(NoteBlock b) {
    setState(() {
      _draggingId = b.id;
      _enteredBedId = null;
      _forceExpanded.clear();
      _gap = 0;
      _previewIndent = b.indent;
      _indicatorY = null; // no indicator until the first move
    });
  }

  void _update(Offset pointer) {
    if (_draggingId == null) return;
    final List<NoteBlock> visible = _visibleOf(_effective);

    // Measure the rows we could land between (everything but the dragged one).
    final List<_Geom> geoms = [];
    for (final NoteBlock b in visible) {
      if (b.id == _draggingId) continue;
      final RenderBox? box =
          _rowKeys[b.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final double top = box.localToGlobal(Offset.zero).dy;
      geoms.add(_Geom(b, top, top + box.size.height));
    }
    if (geoms.isEmpty) return;

    int gap = 0;
    NoteBlock? under;
    for (final _Geom g in geoms) {
      if (pointer.dy > g.center) gap++;
      if (pointer.dy >= g.top && pointer.dy <= g.bottom) under = g.block;
    }

    _updateHover(under, visible);
    _updateAutoScroll(pointer.dy);

    final List<NoteBlock> rest = [for (final _Geom g in geoms) g.block];
    final int di = widget.blocks.indexWhere((b) => b.id == _draggingId);
    // Where it started, in the same `rest` space the gap is measured in — the
    // preview must resolve identically to the drop, or the indicator lies.
    int originalGap = 0;
    for (final NoteBlock b in visible) {
      if (b.id == _draggingId) break;
      originalGap++;
    }
    final DropPlan plan = resolveDrop(
      rest: rest,
      originalContainerId: di < 0 ? null : containerIdOf(widget.blocks, di),
      gap: gap,
      enteredBedId: _enteredBedId,
      originalIndent: di < 0 ? 0 : widget.blocks[di].indent,
      originalGap: originalGap,
    );

    final RenderBox? surface =
        _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    final double surfaceTop =
        surface == null ? 0 : surface.localToGlobal(Offset.zero).dy;
    final double y = plan.gap < geoms.length
        ? geoms[plan.gap].top
        : geoms.last.bottom;
    final double indicatorY = y - surfaceTop;

    if (gap != _gap ||
        plan.indent != _previewIndent ||
        indicatorY != _indicatorY) {
      setState(() {
        _gap = gap;
        _previewIndent = plan.indent;
        _indicatorY = indicatorY;
      });
    }
  }

  /// Holding over a heading enters it; wandering out of the entered bed leaves.
  /// A momentary gap between rows must NOT cancel a pending enter, or the hold
  /// never completes.
  void _updateHover(NoteBlock? under, List<NoteBlock> visible) {
    final int? entered = _enteredBedId;
    if (entered != null && under != null) {
      final int i = visible.indexWhere((b) => b.id == under.id);
      final bool insideBed = under.id == entered ||
          (i >= 0 && containerIdOf(visible, i) == entered);
      if (!insideBed) {
        setState(() {
          _forceExpanded.remove(entered);
          _enteredBedId = null;
        });
      }
    }

    if (under == null) return; // between rows — keep any pending hold alive
    final int? candidate =
        (isHeadingBlock(under) && under.id != _enteredBedId) ? under.id : null;
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
        _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
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
      if (!_scroll.hasClients || _draggingId == null) return;
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
    if (dragged != null && _indicatorY != null) {
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
      _indicatorY = null;
      _forceExpanded.clear();
    });
  }

  // ---- rendering ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<NoteBlock> eff = _effective;
    final SectionFold fold = computeSectionFold(eff);
    final List<NoteBlock> visible = _visibleOf(eff);

    return Listener(
      // The pointer stream is tracked here rather than only via the Draggable's
      // own callback, so tracking survives any rebuild during the drag.
      onPointerMove: (e) {
        if (_draggingId != null) _update(e.position);
      },
      child: Stack(
        key: _surfaceKey,
        children: [
          SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < visible.length; i++)
                  _row(visible[i], i, fold, visible),
              ],
            ),
          ),
          if (_draggingId != null && _indicatorY != null)
            Positioned(
              top: _indicatorY! - 1.5,
              left: 12 + _previewIndent * kNoteIndentStep,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(
      NoteBlock b, int index, SectionFold fold, List<NoteBlock> visible) {
    final int hiddenCount = fold.hiddenCountByHeadingId[b.id] ?? 0;
    final int? entered = _enteredBedId;
    final bool highlighted = entered != null &&
        (b.id == entered || containerIdOf(visible, index) == entered);
    final Widget tile = widget.tileBuilder(b, hiddenCount, highlighted);

    // The GlobalKey sits OUTSIDE the draggable: it both identifies the row
    // across rebuilds and is the box we measure, so it never reparents when the
    // child swaps to its dragging placeholder.
    return SizedBox(
      key: _rowKeys.putIfAbsent(b.id, () => GlobalKey()),
      child: LongPressDraggable<int>(
        data: b.id,
        axis: Axis.vertical,
        hapticFeedbackOnStart: true,
        feedback: _feedback(b, hiddenCount),
        // Same footprint as the resting row, so row geometry never shifts.
        childWhenDragging: Opacity(opacity: 0.25, child: tile),
        onDragStarted: () => _start(b),
        onDragUpdate: (d) => _update(d.globalPosition),
        onDragEnd: (_) => _finish(),
        child: tile,
      ),
    );
  }

  /// The lifted tile: the row itself on a raised, rounded surface.
  Widget _feedback(NoteBlock b, int hiddenCount) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final RenderBox? box =
        _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    final double width = (box?.size.width ?? 340) - 28;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
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
