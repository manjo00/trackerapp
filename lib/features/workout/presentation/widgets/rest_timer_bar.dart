import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_providers.dart';

/// A slim, universal rest-timer bar pinned below the AppBar on the active
/// workout screen.
///
/// - Visible only while [restTimerProvider] > 0 (animated collapse when idle).
/// - Shows remaining `m:ss` + a progress bar.
/// - Controls: −15s, +15s, Restart (re-run full), Skip (cancel).
///
/// The countdown itself lives in the keep-alive [RestTimer] provider, so this
/// widget is purely presentational and can appear/disappear freely.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int remaining = ref.watch(restTimerProvider);
    final RestTimer notifier = ref.read(restTimerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    final bool visible = remaining > 0;
    final int total = notifier.totalSeconds;
    final double progress = total > 0 ? remaining / total : 0.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: !visible
          ? const SizedBox(width: double.infinity, height: 0)
          : Material(
              color: cs.primaryContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_rounded,
                            size: 18, color: cs.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Rest',
                          style: TextStyle(
                            color: cs.onPrimaryContainer.withAlpha(200),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: Text(
                            _fmt(remaining),
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _PillBtn(
                          label: '−15',
                          onTap: () => notifier.addSeconds(-15),
                          cs: cs,
                        ),
                        const SizedBox(width: 4),
                        _PillBtn(
                          label: '+15',
                          onTap: () => notifier.addSeconds(15),
                          cs: cs,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.replay_rounded,
                              size: 20, color: cs.onPrimaryContainer),
                          tooltip: 'Restart rest',
                          onPressed: notifier.restart,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.skip_next_rounded,
                              size: 22, color: cs.onPrimaryContainer),
                          tooltip: 'Skip rest',
                          onPressed: notifier.cancel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: cs.onPrimaryContainer.withAlpha(40),
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static String _fmt(int s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn({
    required this.label,
    required this.onTap,
    required this.cs,
  });

  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.surface.withAlpha(140),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
