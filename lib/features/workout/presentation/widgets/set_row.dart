import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/workout_set_model.dart';

/// A single set row inside the active-workout exercise section.
///
/// Layout: Set# | [−] Weight [+] | × | [−] Reps [+] | ✓
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

  /// Called whenever reps or weight are edited.
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
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.set.weightKg != null ? _fmt(widget.set.weightKg!) : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.set.reps != null ? '${widget.set.reps}' : '',
    );
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller text when the model changes from outside.
    final newWeight =
        widget.set.weightKg != null ? _fmt(widget.set.weightKg!) : '';
    final newReps =
        widget.set.reps != null ? '${widget.set.reps}' : '';
    if (_weightCtrl.text != newWeight) _weightCtrl.text = newWeight;
    if (_repsCtrl.text != newReps) _repsCtrl.text = newReps;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  /// Formats weight: drops trailing ".0" for tidiness.
  static String _fmt(double kg) =>
      kg == kg.truncateToDouble() ? '${kg.toInt()}' : '$kg';

  /// Flush current controller values to the parent model.
  void _flush() {
    final double? kg = double.tryParse(_weightCtrl.text);
    final int? reps = int.tryParse(_repsCtrl.text);
    widget.onUpdate(widget.set.copyWith(weightKg: kg, reps: reps));
  }

  /// Adjust weight by [delta] kg (e.g. +2.5 / −2.5).
  void _stepWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0.0;
    final next = (current + delta).clamp(0.0, 999.0);
    _weightCtrl.text = _fmt(next);
    _flush();
  }

  /// Adjust reps by [delta] (e.g. +1 / −1).
  void _stepReps(int delta) {
    final current = int.tryParse(_repsCtrl.text) ?? 0;
    final next = (current + delta).clamp(0, 99);
    _repsCtrl.text = '$next';
    _flush();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPr = widget.set.isPr;
    final isWarmup = widget.set.isWarmup;

    // Hint text from the previous session.
    final String weightHint = widget.hint?.weightKg != null
        ? _fmt(widget.hint!.weightKg!)
        : 'kg';
    final String repsHint =
        widget.hint?.reps != null ? '${widget.hint!.reps}' : 'reps';

    return GestureDetector(
      onLongPress: widget.onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
            // ── Set number ──────────────────────────────────────────────────
            SizedBox(
              width: 24,
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

            const SizedBox(width: 4),

            // ── Weight stepper ──────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: _StepperField(
                controller: _weightCtrl,
                hint: weightHint,
                isDecimal: true,
                onEditingComplete: _flush,
                onDecrement: () => _stepWeight(-2.5),
                onIncrement: () => _stepWeight(2.5),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '×',
                style: textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withAlpha(180),
                ),
              ),
            ),

            // ── Reps stepper ────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: _StepperField(
                controller: _repsCtrl,
                hint: repsHint,
                isDecimal: false,
                onEditingComplete: _flush,
                onDecrement: () => _stepReps(-1),
                onIncrement: () => _stepReps(1),
              ),
            ),

            const SizedBox(width: 6),

            // ── PR badge ────────────────────────────────────────────────────
            if (isPr)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('🏆', style: textTheme.bodyMedium),
              ),

            // ── Complete button ─────────────────────────────────────────────
            InkWell(
              onTap: () {
                _flush();
                setState(() => _completed = true);
                widget.onComplete();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _completed
                      ? Colors.green
                      : cs.primary.withAlpha(20),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: _completed ? Colors.white : cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stepper field ─────────────────────────────────────────────────────────────

/// A number text field flanked by [−] and [+] step buttons.
class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.controller,
    required this.hint,
    required this.isDecimal,
    required this.onEditingComplete,
    required this.onDecrement,
    required this.onIncrement,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDecimal;
  final VoidCallback onEditingComplete;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        Expanded(
          child: _NumberField(
            controller: controller,
            hint: hint,
            isDecimal: isDecimal,
            onEditingComplete: onEditingComplete,
          ),
        ),
        _StepBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

// ── Step button ───────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHighest,
        ),
        child: Icon(icon, size: 13, color: cs.onSurface.withAlpha(200)),
      ),
    );
  }
}

// ── Number text field ─────────────────────────────────────────────────────────

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
      keyboardType:
          TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
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
