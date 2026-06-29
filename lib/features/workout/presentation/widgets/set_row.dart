import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/workout_set_model.dart';
import '../../data/repositories/workout_repository.dart';
import 'exercise_history_sheet.dart';

/// A single set inside the active-workout exercise card, as a two-line tile:
///
/// ```
/// [#]  prev 35 × 12            ⋮  ✓
///      [−] 35 kg [+]  ×  [−] 12 [+]
/// ```
///
/// - **prev** (tap → copies last session's weight/reps into the fields).
/// - **⋮** opens the history picker (Recent / Max) to load any past set.
/// - **✓** marks the set done (whole tile fills green) and starts the rest timer.
/// - Long-press anywhere on the tile deletes it.
class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    this.hint,
    required this.isCompleted,
    required this.onUpdate,
    required this.onComplete,
    required this.onDelete,
  });

  final WorkoutSetModel set;

  /// Matching set from the previous session (for the "prev" label + copy).
  final WorkoutSetModel? hint;

  /// Whether this set is checked off (driven by the provider so it survives
  /// the card being collapsed/expanded).
  final bool isCompleted;

  /// Called whenever reps or weight change.
  final ValueChanged<WorkoutSetModel> onUpdate;

  /// Called when ✓ is tapped (toggles completion + starts rest timer).
  final VoidCallback onComplete;

  /// Called when the tile is long-pressed.
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
      text: widget.set.weightKg != null ? _fmt(widget.set.weightKg!) : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.set.reps != null ? '${widget.set.reps}' : '',
    );
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newWeight =
        widget.set.weightKg != null ? _fmt(widget.set.weightKg!) : '';
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

  static String _fmt(double kg) =>
      kg == kg.truncateToDouble() ? '${kg.toInt()}' : '$kg';

  void _flush() {
    final double? kg = double.tryParse(_weightCtrl.text);
    final int? reps = int.tryParse(_repsCtrl.text);
    widget.onUpdate(widget.set.copyWith(weightKg: kg, reps: reps));
  }

  void _apply(double? weightKg, int? reps) {
    if (weightKg != null) _weightCtrl.text = _fmt(weightKg);
    if (reps != null) _repsCtrl.text = '$reps';
    _flush();
    setState(() {});
  }

  void _stepWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text) ?? 0.0;
    _apply((current + delta).clamp(0.0, 999.0), int.tryParse(_repsCtrl.text));
  }

  void _stepReps(int delta) {
    final current = int.tryParse(_repsCtrl.text) ?? 0;
    _apply(double.tryParse(_weightCtrl.text), (current + delta).clamp(0, 99));
  }

  void _copyPrev() {
    final h = widget.hint;
    if (h == null) return;
    _apply(h.weightKg, h.reps);
  }

  Future<void> _openHistory() async {
    final entry = await showModalBottomSheet<ExerciseHistoryEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          ExerciseHistorySheet(exerciseName: widget.set.exerciseName),
    );
    if (entry == null) return;
    _apply(entry.weightKg, entry.reps);
  }

  String _prevText() {
    final h = widget.hint;
    if (h == null) return 'first time';
    final w = h.weightKg;
    final wStr = w == null ? '–' : _fmt(w);
    final r = h.reps?.toString() ?? '–';
    return 'prev  $wStr × $r';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPr = widget.set.isPr;
    final isWarmup = widget.set.isWarmup;
    final hasPrev = widget.hint != null;
    final completed = widget.isCompleted;

    Color? bg;
    if (completed) {
      bg = Colors.green.withAlpha(40);
    } else if (isPr) {
      bg = cs.primaryContainer.withAlpha(80);
    } else if (isWarmup) {
      bg = cs.surfaceContainerHighest.withAlpha(60);
    }

    return GestureDetector(
      onLongPress: widget.onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            // ── Row 1: number · previous · history · complete ────────────────
            Row(
              children: [
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
                // Previous (tap to copy)
                Expanded(
                  child: InkWell(
                    onTap: hasPrev ? _copyPrev : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Text(
                        _prevText(),
                        style: textTheme.bodySmall?.copyWith(
                          color: hasPrev
                              ? cs.onSurface.withAlpha(150)
                              : cs.onSurface.withAlpha(90),
                          fontStyle:
                              hasPrev ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
                // PR badge
                if (isPr)
                  const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Text('🏆', style: TextStyle(fontSize: 13)),
                  ),
                // History picker
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: cs.onSurface.withAlpha(140)),
                  tooltip: 'Load from history',
                  onPressed: _openHistory,
                ),
                // Complete (toggles; driven by provider state)
                InkWell(
                  onTap: () {
                    _flush();
                    widget.onComplete();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? Colors.green
                          : cs.primary.withAlpha(20),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: completed ? Colors.white : cs.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Row 2: weight & reps steppers ────────────────────────────────
            Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: _StepperField(
                    controller: _weightCtrl,
                    hint: 'kg',
                    isDecimal: true,
                    onEditingComplete: _flush,
                    onDecrement: () => _stepWeight(-2.5),
                    onIncrement: () => _stepWeight(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('×',
                      style: textTheme.titleMedium
                          ?.copyWith(color: cs.onSurface.withAlpha(160))),
                ),
                Expanded(
                  flex: 4,
                  child: _StepperField(
                    controller: _repsCtrl,
                    hint: 'reps',
                    isDecimal: false,
                    onEditingComplete: _flush,
                    onDecrement: () => _stepReps(-1),
                    onIncrement: () => _stepReps(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stepper field ─────────────────────────────────────────────────────────────

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
      // Persist on every keystroke so a typed value is never lost if the user
      // taps Finish (or away) without pressing the keyboard's "done".
      onChanged: (_) => onEditingComplete(),
      onEditingComplete: onEditingComplete,
    );
  }
}
