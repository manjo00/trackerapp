import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/reminder_leads.dart';

/// Asks for a custom reminder: a number and a unit (minutes, hours or days)
/// before the due time. Returns the amount in minutes, or null if cancelled.
Future<int?> showCustomLeadDialog(BuildContext context) => showDialog<int>(
      context: context,
      builder: (_) => const CustomLeadDialog(),
    );

enum _LeadUnit {
  minutes('min', 1),
  hours('hours', 60),
  days('days', 1440);

  const _LeadUnit(this.label, this.factor);
  final String label;

  /// Minutes in one of this unit.
  final int factor;
}

class CustomLeadDialog extends StatefulWidget {
  const CustomLeadDialog({super.key});

  @override
  State<CustomLeadDialog> createState() => _CustomLeadDialogState();
}

class _CustomLeadDialogState extends State<CustomLeadDialog> {
  final TextEditingController _amount = TextEditingController();
  _LeadUnit _unit = _LeadUnit.minutes;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _typed => int.tryParse(_amount.text) ?? 0;

  /// The amount in minutes, or null unless it is 1 minute to 30 days.
  int? get _minutes {
    final int minutes = _typed * _unit.factor;
    return _typed >= 1 && minutes <= kMaxLeadMinutes ? minutes : null;
  }

  @override
  Widget build(BuildContext context) {
    final int? minutes = _minutes;
    return AlertDialog(
      title: const Text('Custom reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '30',
              errorText:
                  _typed >= 1 && minutes == null ? 'Up to 30 days' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SegmentedButton<_LeadUnit>(
            segments: [
              for (final _LeadUnit unit in _LeadUnit.values)
                ButtonSegment<_LeadUnit>(value: unit, label: Text(unit.label)),
            ],
            selected: <_LeadUnit>{_unit},
            showSelectedIcon: false,
            onSelectionChanged: (Set<_LeadUnit> picked) =>
                setState(() => _unit = picked.first),
          ),
          const SizedBox(height: 8),
          const Text('before the due time'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: minutes == null ? null : () => Navigator.pop(context, minutes),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
