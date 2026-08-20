import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/coach_tip.dart';

/// A tip plus where its target sits on screen right now.
class CoachStep {
  const CoachStep(this.tip, this.rect, {this.isNew = false});

  final CoachTip tip;

  /// Where to cut the spotlight, or null for a screen-level tip that just
  /// dims and shows a centred card.
  final Rect? rect;
  final bool isNew;
}

/// Full-screen spotlight: dims everything, punches a rounded hole around the
/// target, and floats a tip card beside it. Tap anywhere (or Next) to advance;
/// Skip dismisses the rest for this screen.
class CoachOverlay extends StatefulWidget {
  const CoachOverlay({
    required this.steps,
    required this.onSeen,
    required this.onFinished,
    super.key,
  });

  final List<CoachStep> steps;

  /// Called as each tip is actually shown, so it is never repeated.
  final void Function(CoachTip tip) onSeen;
  final VoidCallback onFinished;

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    widget.onSeen(widget.steps.first.tip);
  }

  void _next() {
    if (_i >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() => _i++);
    widget.onSeen(widget.steps[_i].tip);
  }

  /// Skip marks the REMAINING tips seen too — "not now" would otherwise
  /// ambush the user with the same tour on every visit.
  void _skip() {
    for (int j = _i + 1; j < widget.steps.length; j++) {
      widget.onSeen(widget.steps[j].tip);
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final CoachStep step = widget.steps[_i];
    final Size screen = MediaQuery.of(context).size;
    final ColorScheme cs = Theme.of(context).colorScheme;

    // Grow the hole a little so the target does not touch the dim edge.
    final Rect? hole = step.rect?.inflate(6);
    final bool below = hole != null && hole.bottom + 180 < screen.height;
    final bool last = _i == widget.steps.length - 1;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dim + cutout. Tapping the dim advances.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(painter: _SpotlightPainter(hole)),
            ),
          ),
          // A ring around the spotlight so it reads as "this thing here".
          if (hole != null)
            Positioned(
              left: hole.left,
              top: hole.top,
              width: hole.width,
              height: hole.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary, width: 2),
                  ),
                ),
              ),
            ),
          // Tip card: beside the target, or centred for a screen-level tip.
          Positioned(
            left: 16,
            right: 16,
            top: hole == null
                ? screen.height / 2 - 90
                : (below ? hole.bottom + 14 : null),
            bottom: hole == null || below
                ? null
                : (screen.height - hole.top) + 14,
            child: _TipCard(
              step: step,
              index: _i,
              total: widget.steps.length,
              isLast: last,
              onNext: _next,
              onSkip: _skip,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole);

  /// Null dims the whole screen (screen-level tip, nothing to point at).
  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dim = Paint()..color = Colors.black.withAlpha(170);
    final Rect? h = hole;
    if (h == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }
    final Path full = Path()..addRect(Offset.zero & size);
    final Path cut = Path()
      ..addRRect(RRect.fromRectAndRadius(h, const Radius.circular(14)));
    canvas.drawPath(Path.combine(PathOperation.difference, full, cut), dim);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (step.isNew)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            Text(
              step.tip.text,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (total > 1)
                  Text(
                    '${index + 1}/$total',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(130),
                    ),
                  ),
                const Spacer(),
                if (step.tip.codexTopicId != null)
                  TextButton(
                    onPressed: () {
                      onSkip();
                      context.push('/codex');
                    },
                    child: const Text('Learn more'),
                  ),
                if (!isLast)
                  TextButton(onPressed: onSkip, child: const Text('Skip')),
                FilledButton(
                  onPressed: onNext,
                  child: Text(isLast ? 'Got it' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
