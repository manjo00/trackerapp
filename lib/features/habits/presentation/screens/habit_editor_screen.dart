import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../archive/presentation/archive_providers.dart';
import '../../data/models/habit_model.dart';
import '../../domain/habit_types.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_palette.dart';

/// Adds a habit, or edits one: name, icon and colour, tick or count, when it
/// is due, spare days, part of the day, a cue and a daily reminder.
///
/// Opened by `/habits/add` (no [habit]) and `/habits/edit` (the habit).
class HabitEditorScreen extends ConsumerStatefulWidget {
  const HabitEditorScreen({this.habit, super.key});

  final HabitModel? habit;

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends ConsumerState<HabitEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _goal;
  late final TextEditingController _unit;
  late final TextEditingController _step;
  late final TextEditingController _cue;

  late HabitKind _kind;
  late String _icon;
  late int _color;
  late HabitSchedule _schedule;
  late int _weekdayMask;
  late int _perWeek;
  late int _spares;
  bool _sparesTouched = false;
  late HabitSection _section;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  bool _saving = false;
  String? _daysError;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final HabitModel? h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _goal = TextEditingController(
        text: h != null && h.kind == HabitKind.count ? '${h.goal}' : '');
    _unit = TextEditingController(text: h?.unit ?? '');
    _step = TextEditingController(text: '${h?.step ?? 1}');
    _cue = TextEditingController(text: h?.cue ?? '');
    _kind = h?.kind ?? HabitKind.tick;
    _icon = h?.icon ?? 'check_circle';
    _color = h?.color ?? 0;
    _schedule = h?.schedule ?? HabitSchedule.daily;
    _weekdayMask = h?.weekdayMask ?? 127;
    _perWeek = h?.perWeek ?? 3;
    _spares = h?.sparesPerWeek ?? 1;
    _sparesTouched = h != null;
    _section = h?.section ?? HabitSection.any;
    _reminderEnabled = h?.reminderEnabled ?? false;
    _reminderTime =
        _parseTime(h?.reminderTime) ?? const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    for (final TextEditingController c in [_name, _goal, _unit, _step, _cue]) {
      c.dispose();
    }
    super.dispose();
  }

  static TimeOfDay? _parseTime(String? s) {
    final List<String>? parts = s?.split(':');
    if (parts == null || parts.length != 2) return null;
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
  }

  static String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _setSchedule(HabitSchedule s) => setState(() {
        _schedule = s;
        _daysError = null;
        // A new habit's spare days follow its schedule until touched: one
        // for every day, none for the others.
        if (!_sparesTouched) _spares = s == HabitSchedule.daily ? 1 : 0;
      });

  Future<void> _save() async {
    final bool formOk = _formKey.currentState?.validate() ?? false;
    final bool daysOk =
        _schedule != HabitSchedule.weekdays || _weekdayMask != 0;
    setState(() => _daysError = daysOk ? null : 'Pick at least one day');
    if (!formOk || !daysOk) return;
    setState(() => _saving = true);

    final HabitModel? old = widget.habit;
    final bool count = _kind == HabitKind.count;
    final String unit = _unit.text.trim();
    final String cue = _cue.text.trim();
    final HabitModel habit = HabitModel(
      id: old?.id ?? 0,
      name: _name.text.trim(),
      createdAt: old?.createdAt ?? DateTime.now(),
      kind: _kind,
      goal: count ? int.parse(_goal.text.trim()) : 1,
      unit: count && unit.isNotEmpty ? unit : null,
      step: count ? int.parse(_step.text.trim()) : 1,
      icon: _icon,
      color: _color,
      schedule: _schedule,
      weekdayMask: _schedule == HabitSchedule.weekdays ? _weekdayMask : 127,
      perWeek: _schedule == HabitSchedule.perWeek ? _perWeek : null,
      shiftMask: old?.shiftMask ?? 7,
      sparesPerWeek: _schedule == HabitSchedule.perWeek ? 0 : _spares,
      section: _section,
      cue: cue.isEmpty ? null : cue,
      sortOrder: old?.sortOrder ?? 0,
      autoSource: old?.autoSource,
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderEnabled ? _timeStr(_reminderTime) : null,
    );
    final int id = await ref.read(habitActionsProvider).save(habit);
    // Book or cancel the daily reminder, as the old editor did.
    if (_reminderEnabled) {
      await NotificationService.instance
          .scheduleHabitReminder(habit.copyWith(id: id));
    } else if (old?.reminderEnabled ?? false) {
      await NotificationService.instance.cancelHabitReminder(id);
    }
    if (mounted) await Navigator.of(context).maybePop();
  }

  /// Sends the habit to Recently deleted and closes the editor.
  Future<void> _confirmDelete() async {
    final HabitModel? habit = widget.habit;
    if (habit == null) return;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${habit.name}"?'),
        content: const Text(
            'It moves to Recently deleted — you can restore it for 30 days.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    await ref.read(archiveServiceProvider).trashHabit(habit.id, DateTime.now());
    if (mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool weekStartsSunday =
        ref.watch(settingsProvider.select((s) => s.weekStartsSunday));
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [
          if (_isEditing)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (_) => _confirmDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete habit')),
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _name,
              autofocus: !_isEditing,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Read 20 minutes',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Give it a name' : null,
            ),
            const _Label('Icon and colour'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < kHabitHues.length; i++)
                  _ColourDot(
                    key: ValueKey('color-$i'),
                    color: HabitColors.of(context, i).solid,
                    selected: _color == i,
                    onTap: () => setState(() => _color = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final MapEntry<String, IconData> e in kHabitIcons.entries)
                  _IconChoice(
                    key: ValueKey('icon-${e.key}'),
                    icon: e.value,
                    colors: HabitColors.of(context, _color),
                    selected: _icon == e.key,
                    onTap: () => setState(() => _icon = e.key),
                  ),
              ],
            ),
            const _Label('Kind'),
            SegmentedButton<HabitKind>(
              segments: const [
                ButtonSegment(value: HabitKind.tick, label: Text('Tick')),
                ButtonSegment(value: HabitKind.count, label: Text('Count')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            if (_kind == HabitKind.count) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _goal,
                      label: 'Goal per day',
                      validator: (v) {
                        final int? n = int.tryParse(v ?? '');
                        return n == null || n < 1 || n > 999 ? '1 to 999' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _unit,
                      maxLength: 20,
                      decoration: const InputDecoration(
                          labelText: 'Unit', hintText: 'glasses'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(
                      controller: _step,
                      label: 'Each + adds',
                      validator: (v) {
                        final int? n = int.tryParse(v ?? '');
                        final int goal = int.tryParse(_goal.text) ?? 999;
                        return n == null || n < 1 || n > goal
                            ? '1 to the goal'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const _Label('When'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (HabitSchedule s, String label) in const [
                  (HabitSchedule.daily, 'Every day'),
                  (HabitSchedule.weekdays, 'Chosen days'),
                  (HabitSchedule.perWeek, 'A few times a week'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _schedule == s,
                    onSelected: (_) => _setSchedule(s),
                  ),
              ],
            ),
            if (_schedule == HabitSchedule.weekdays) ...[
              const SizedBox(height: 8),
              _WeekdayPicker(
                mask: _weekdayMask,
                weekStartsSunday: weekStartsSunday,
                onChanged: (int m) => setState(() {
                  _weekdayMask = m;
                  _daysError = null;
                }),
              ),
              if (_daysError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_daysError!,
                      style: TextStyle(color: cs.error, fontSize: 12)),
                ),
            ],
            if (_schedule == HabitSchedule.perWeek) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Times a week'),
                  const Spacer(),
                  IconButton.outlined(
                    tooltip: 'Fewer',
                    onPressed: _perWeek > 1
                        ? () => setState(() => _perWeek--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('$_perWeek',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton.outlined(
                    tooltip: 'More times',
                    onPressed: _perWeek < 6
                        ? () => setState(() => _perWeek++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
            if (_schedule != HabitSchedule.perWeek) ...[
              const _Label('Spare days a week'),
              Wrap(
                spacing: 8,
                children: [
                  for (int n = 0; n <= 2; n++)
                    ChoiceChip(
                      label: Text('$n'),
                      selected: _spares == n,
                      onSelected: (_) => setState(() {
                        _spares = n;
                        _sparesTouched = true;
                      }),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('A missed day uses one, and the streak lives on.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ),
            ],
            const _Label('Part of the day'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (HabitSection s, String label) in const [
                  (HabitSection.wake, 'Wake-up'),
                  (HabitSection.any, 'Any time'),
                  (HabitSection.day, 'Daytime'),
                  (HabitSection.sleep, 'Before sleep'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _section == s,
                    onSelected: (_) => setState(() => _section = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cue,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cue',
                hintText: 'After I …',
                helperText: 'Optional: when you do it, e.g. "After dinner"',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                _reminderEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                color: _reminderEnabled ? cs.primary : cs.onSurfaceVariant,
              ),
              title: const Text('Daily reminder'),
              subtitle: const Text('Get notified at a set time each day'),
              value: _reminderEnabled,
              onChanged: (bool v) => setState(() => _reminderEnabled = v),
            ),
            if (_reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Reminder time'),
                trailing: Text(
                  _reminderTime.format(context),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: cs.primary),
                ),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                      context: context, initialTime: _reminderTime);
                  if (picked != null) setState(() => _reminderTime = picked);
                },
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_isEditing ? 'Save changes' : 'Save habit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _NumberField extends StatelessWidget {
  const _NumberField(
      {required this.controller, required this.label, required this.validator});

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
        validator: validator,
      );
}

class _ColourDot extends StatelessWidget {
  const _ColourDot(
      {required this.color,
      required this.selected,
      required this.onTap,
      super.key});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
      );
}

class _IconChoice extends StatelessWidget {
  const _IconChoice(
      {required this.icon,
      required this.colors,
      required this.selected,
      required this.onTap,
      super.key});

  final IconData icon;
  final HabitColorSet colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? colors.container : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colors.solid
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Icon(icon,
              color: selected
                  ? colors.onContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

/// Seven day chips in the week-start order; each toggles its bit
/// (Monday 1 … Sunday 64). Keys `day-1` … `day-7` follow `DateTime.weekday`.
class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker(
      {required this.mask,
      required this.weekStartsSunday,
      required this.onChanged});

  final int mask;
  final bool weekStartsSunday;
  final ValueChanged<int> onChanged;

  static const List<String> _names = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday', //
  ];

  @override
  Widget build(BuildContext context) {
    final List<int> order = weekStartsSunday
        ? const [7, 1, 2, 3, 4, 5, 6]
        : const [1, 2, 3, 4, 5, 6, 7];
    return Wrap(
      spacing: 6,
      children: [
        for (final int weekday in order)
          Tooltip(
            message: _names[weekday - 1],
            child: FilterChip(
              key: ValueKey('day-$weekday'),
              label: Text(_names[weekday - 1].substring(0, 1)),
              showCheckmark: false,
              selected: mask & (1 << (weekday - 1)) != 0,
              onSelected: (_) => onChanged(mask ^ (1 << (weekday - 1))),
            ),
          ),
      ],
    );
  }
}
