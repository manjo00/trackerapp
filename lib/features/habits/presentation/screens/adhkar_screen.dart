import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/habit_model.dart';
import '../../domain/adhkar_progress.dart';
import '../../domain/dhikr.dart';
import '../adhkar_haptics.dart';
import '../providers/adhkar_providers.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_palette.dart';

/// The morning or night du'a counter, look B (Ahmed's pick, 2026-11-13): one
/// du'a fills the screen and a tap anywhere counts it. When its count is
/// reached the phone buzzes and a pop-up comes up; taps count nothing until
/// he closes it, so counting without looking never spills into the next du'a.
class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({required this.habit, super.key});

  /// A du'a habit (its `autoSource` names the list).
  final HabitModel habit;

  /// The area a tap counts on.
  static const Key tapArea = Key('adhkar-tap-area');

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  late final List<Dhikr> _items =
      AdhkarList.fromSource(widget.habit.autoSource)?.items ?? const [];

  /// The habit day the counts belong to, fixed when the screen opens, so a
  /// list started at 03:50 still counts for that night after 04:00.
  late final String _day = ref.read(habitTodayProvider);

  AdhkarProgress? _progress;
  int _at = 0;
  bool _popUpOpen = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final AdhkarProgress p =
        await ref.read(adhkarActionsProvider).open(widget.habit, _day);
    if (!mounted) return;
    setState(() {
      _progress = p;
      _at = p.firstOpen ?? 0;
    });
  }

  /// Shows [next] at once, then saves it (and the habit's day value).
  Future<void> _change(AdhkarProgress next) async {
    final AdhkarProgress? before = _progress;
    if (before == null || identical(before, next)) return;
    setState(() => _progress = next);
    await ref
        .read(adhkarActionsProvider)
        .save(widget.habit, _day, before, next);
  }

  Future<void> _count() async {
    final AdhkarProgress? p = _progress;
    if (p == null || _items.isEmpty || _popUpOpen || p.isFinished(_at)) {
      return;
    }
    final AdhkarHaptics haptics = ref.read(adhkarHapticsProvider);
    final AdhkarProgress next = p.tapped(_at);
    final bool finishedNow = next.isFinished(_at);
    unawaited(haptics.tick());
    if (finishedNow) {
      _popUpOpen = true;
      unawaited(haptics.finished());
    }
    await _change(next);
    if (finishedNow && mounted) await _showFinished(next);
  }

  Future<void> _showFinished(AdhkarProgress p) async {
    final int? next = p.nextOpen(after: _at);
    _popUpOpen = true;
    final bool? goOn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _FinishedPopUp(
        finished: _items[_at],
        next: next == null ? null : _items[next],
        color: HabitColors.of(context, widget.habit.color).solid,
      ),
    );
    _popUpOpen = false;
    if (!mounted || goOn != true) return;
    if (next == null) {
      await Navigator.of(context).maybePop();
    } else {
      setState(() => _at = next);
    }
  }

  void _move(int delta) {
    final int to = _at + delta;
    if (to < 0 || to >= _items.length) return;
    setState(() => _at = to);
  }

  Future<void> _takeBack() async {
    final AdhkarProgress? p = _progress;
    if (p != null) await _change(p.untapped(_at));
  }

  Future<void> _startAgain() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Start this list again?'),
        content: const Text("Today's counts go back to 0."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start again'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _at = 0);
    await _change(AdhkarProgress.empty(_items));
  }

  Future<void> _showList() async {
    final AdhkarProgress? p = _progress;
    if (p == null) return;
    final int? pick = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (int i = 0; i < _items.length; i++)
              ListTile(
                selected: i == _at,
                leading: p.isFinished(i)
                    ? const Icon(Icons.check_circle_rounded)
                    : Text('${p.countOf(i)}/${_items[i].times}'),
                title: Text(_items[i].title,
                    textDirection: TextDirection.rtl),
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
    if (pick != null && mounted) setState(() => _at = pick);
  }

  @override
  Widget build(BuildContext context) {
    final AdhkarProgress? p = _progress;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.habit.name, overflow: TextOverflow.ellipsis),
            if (p != null)
              Text('${p.finished} of ${_items.length} done',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "All du'as",
            icon: const Icon(Icons.format_list_bulleted_rounded),
            onPressed: p == null ? null : _showList,
          ),
          IconButton(
            tooltip: 'Start again',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: p == null ? null : _startAgain,
          ),
        ],
      ),
      body: switch (p) {
        null => const Center(child: CircularProgressIndicator()),
        _ when _items.isEmpty =>
          const Center(child: Text("This habit has no du'a list.")),
        final AdhkarProgress p => _counter(context, p),
      },
    );
  }

  Widget _counter(BuildContext context, AdhkarProgress p) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final Color solid = HabitColors.of(context, widget.habit.color).solid;
    final Dhikr d = _items[_at];
    final int v = p.countOf(_at);
    final bool done = p.isFinished(_at);

    return Column(
      children: [
        LinearProgressIndicator(
          value: p.finished / _items.length,
          minHeight: 3,
          color: solid,
          backgroundColor: cs.surfaceContainerHighest,
        ),
        Expanded(
          child: Semantics(
            button: true,
            label: done
                ? '${d.title}, finished'
                : 'Tap to count. ${d.title}, $v of ${d.times}',
            child: GestureDetector(
              key: AdhkarScreen.tapArea,
              behavior: HitTestBehavior.opaque,
              onTap: _count,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Text("Du'a ${_at + 1} of ${_items.length}",
                            style: tt.labelMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        const Spacer(),
                        if (done)
                          Icon(Icons.check_circle_rounded,
                              size: 20, color: solid),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        children: [
                          Text(
                            d.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: tt.titleSmall?.copyWith(
                                color: solid, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            d.text,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: tt.headlineSmall
                                ?.copyWith(fontSize: 22, height: 1.9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 124,
                    height: 124,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v / d.times,
                            strokeWidth: 8,
                            color: solid,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '$v',
                              style: tt.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          TextSpan(
                              text: ' / ${d.times}',
                              style: tt.titleSmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(done ? 'Finished' : 'Tap anywhere to count',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: "Previous du'a",
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _at == 0 ? null : () => _move(-1),
                        ),
                        IconButton(
                          tooltip: 'Take one back',
                          icon: const Icon(Icons.undo_rounded),
                          onPressed: v == 0 ? null : _takeBack,
                        ),
                        IconButton(
                          tooltip: "Next du'a",
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _at == _items.length - 1
                              ? null
                              : () => _move(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Done" (or "All done") after a du'a reaches its count. Its button sleeps
/// for [wake] first, so a reflex tap from counting can't skip ahead.
class _FinishedPopUp extends StatefulWidget {
  const _FinishedPopUp(
      {required this.finished, required this.next, required this.color});

  final Dhikr finished;

  /// The du'a the button opens; null when every du'a is done.
  final Dhikr? next;
  final Color color;

  static const Duration wake = Duration(milliseconds: 800);

  @override
  State<_FinishedPopUp> createState() => _FinishedPopUpState();
}

class _FinishedPopUpState extends State<_FinishedPopUp> {
  bool _ready = false;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_FinishedPopUp.wake, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Dhikr? next = widget.next;
    return AlertDialog(
      icon: Icon(Icons.check_circle_rounded, size: 44, color: widget.color),
      title: Text(next == null ? 'All done' : 'Done'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.finished.title,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: tt.titleMedium),
          const SizedBox(height: 16),
          if (next != null) ...[
            Text('Next',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text(next.title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: tt.titleMedium),
          ] else
            Text("Every du'a is counted for today.",
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _ready ? () => Navigator.of(context).pop(true) : null,
            child: Text(next == null ? 'Close' : "Next du'a"),
          ),
        ),
      ],
    );
  }
}
