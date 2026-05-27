import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_providers.dart';

/// Modal bottom sheet that shows a live rest-timer countdown.
///
/// The [restTimerProvider] is already running when this sheet opens.
/// The sheet auto-dismisses when the countdown reaches 0.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => const RestTimerBottomSheet(),
/// );
/// ```
class RestTimerBottomSheet extends ConsumerStatefulWidget {
  const RestTimerBottomSheet({super.key});

  @override
  ConsumerState<RestTimerBottomSheet> createState() =>
      _RestTimerBottomSheetState();
}

class _RestTimerBottomSheetState
    extends ConsumerState<RestTimerBottomSheet> {
  // Guard against double-pop: "Skip Rest" calls cancel() which sets
  // the timer to 0, which would re-trigger the auto-dismiss listener
  // and pop the Active Workout screen behind this sheet.
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final int remaining = ref.watch(restTimerProvider);
    final cs = Theme.of(context).colorScheme;

    // Auto-close when timer reaches zero.
    ref.listen<int>(restTimerProvider, (int? prev, int next) {
      if (next == 0 && (prev ?? 0) > 0) {
        _close();
      }
    });

    final String display = _formatSeconds(remaining);
    final double progress = remaining / 90.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              'Rest Timer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),

            const SizedBox(height: 24),

            // Circular countdown progress indicator + time text
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      display,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'remaining',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withAlpha(140),
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick-add buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AdjustButton(
                  label: '+30s',
                  onTap: () => ref
                      .read(restTimerProvider.notifier)
                      .start(remaining + 30),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(restTimerProvider.notifier).cancel();
                    _close();
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Skip Rest'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.secondaryContainer,
                    foregroundColor: cs.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                _AdjustButton(
                  label: '+60s',
                  onTap: () => ref
                      .read(restTimerProvider.notifier)
                      .start(remaining + 60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatSeconds(int s) {
    final m = (s ~/ 60).toString().padLeft(1, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: BorderSide(color: cs.outline.withAlpha(120)),
      ),
      child: Text(label),
    );
  }
}
