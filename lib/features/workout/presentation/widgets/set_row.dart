import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/workout_set_model.dart';

/// A single set row inside the active-workout exercise section.
///
/// Displays: Set# | Weight field | × | Reps field | ✓ button
/// Long-press on the row deletes it.
///
/// [hint] is the corresponding set from the previous session — shown as
/// placeholder text so the user can quickly replicate last time's weights.
class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    this.hint,
    required this.onUpdate,
    required this.onComplete,
    required this.onDelete,
  });

  final WorkoutSetModel set;

  /// Optional matching set from the previous session (for placeholder hints).
  final WorkoutSetModel? hint;

  /// Called whenever reps or weight are edited (debounced on focus-lost).
  final ValueChanged<WorkoutSetModel> onUpdate;

  /// Called when the ✓ button is tapped (saves + starts rest timer).
  final VoidCallback onComplete;

  /// Called when the row is long-pressed.
  final VoidCallback onDelete;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.set.weightKg != null
          ? _fmt(widget.set.weightKg!)
          : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.set.reps != null ? '${widget.set.reps}' : '',
    );
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller text when the model changes from outside (e.g. undo).
    final newWeight = widget.set.weightKg != null ? _fmt(widget.set.weightKg!) : '';
    final newReps = widget.set.reps != null ? '${widget.set.reps}' : '';
    if (_weightCtrl.text != newWeight) _weightCtrl.text = newWeight;
    if (_repsCtrl.text != newReps) _repsCtrl.text = newReps;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  /// Formats weight: drops trailing ".0" to keep things tidy.
  static String _fmt(double kg) =>
      kg == kg.truncateToDouble() ? '${kg.toInt()}' : '$kg';

  void _flush() {
    final double? kg = double.tryParse(_weightCtrl.text);
    final int? reps = int.tryParse(_repsCtrl.text);
    widget.onUpdate(widget.set.copyWith(weightKg: kg, reps: reps));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPr = widget.set.isPr;
    final isWarmup = widget.set.isWarmup;

    // Hint text derived from the previous-session set.
    final String weightHint = widget.hint?.weightKg != null
        ? _fmt(widget.hint!.weightKg!)
        : 'kg';
    final String repsHint =
        widget.hint?.reps != null ? '${widget.hint!.reps}' : 'reps';

    return GestureDetector(
      onLongPress: widget.onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPr
              ? cs.primaryContainer.withAlpha(80)
              : isWarmup
                  ? cs.surfaceContainerHighest.withAlpha(60)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Set number badge
            SizedBox(
              width: 28,
              child: Text(
                '${widget.set.setNumber}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: isWarmup
                      ? cs.onSurface.withAlpha(128)
                      : cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Warm-up label (replaces extra space when warmup)
            if (isWarmup) ...[
              const SizedBox(width: 4),
              Text(
                'W',
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withAlpha(128),
                ),
              ),
            ],
            const SizedBox(width: 8),

            // Weight field
            Expanded(
              flex: 3,
              child: _NumberField(
                controller: _weightCtrl,
                hint: weightHint,
                isDecimal: true,
                onEditingComplete: _flush,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '×',
                style: textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withAlpha(180),
                ),
              ),
            ),

            // Reps field
            Expanded(
              flex: 2,
              child: _NumberField(
                controller: _repsCtrl,
                hint: repsHint,
                isDecimal: false,
                onEditingComplete: _flush,
              ),
            ),

            const SizedBox(width: 8),

            // PR badge
            if (isPr)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '🏆',
                  style: textTheme.bodyMedium,
                ),
              ),

            // Complete button
            InkWell(
              onTap: () {
                _flush();
                widget.onComplete();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withAlpha(20),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helper widget ─────────────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    required this.isDecimal,
    required this.onEditingComplete,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDecimal;
  final VoidCallback onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(80),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(80),
          ),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      onEditingComplete: onEditingComplete,
    );
  }
}
