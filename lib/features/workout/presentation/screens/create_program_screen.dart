import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/program_template_data.dart';
import '../providers/program_providers.dart';

/// Creates a new training program from a built-in template or from scratch.
///
/// Flow:
///   1. Choose template (PPL / Upper-Lower / Custom)
///   2. (Custom only) Enter program name + split type
///   3. Program is created & set active → navigate to detail screen
class CreateProgramScreen extends ConsumerStatefulWidget {
  const CreateProgramScreen({super.key});

  @override
  ConsumerState<CreateProgramScreen> createState() =>
      _CreateProgramScreenState();
}

class _CreateProgramScreenState
    extends ConsumerState<CreateProgramScreen> {
  bool _loading = false;

  // Custom program fields
  final _nameCtrl = TextEditingController();
  String _splitType = 'rotating';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTemplate(ProgramTemplateData template) async {
    setState(() => _loading = true);
    try {
      final program = await ref
          .read(programRepositoryProvider)
          .createFromTemplate(template);
      if (mounted) {
        context.pushReplacement('/workout/programs/${program.id}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCustom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(programRepositoryProvider);
      final int id = await repo.createProgram(
        name: name,
        splitType: _splitType,
      );
      await repo.setActiveProgram(id);
      if (mounted) {
        context.pushReplacement('/workout/programs/$id');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Program')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Templates ────────────────────────────────────────────
                  Text(
                    'Start from a template',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  for (final template in kBuiltInProgramTemplates)
                    _TemplateCard(
                      template: template,
                      onTap: () => _pickTemplate(template),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Custom program ────────────────────────────────────────
                  Text(
                    'Or build your own',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Program name',
                      hintText: 'e.g. My PPL Split',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),

                  // Split type selector
                  Text(
                    'Schedule type',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SplitTypeCard(
                          title: 'Rotating',
                          subtitle:
                              'Cycle sessions in order, regardless of weekday',
                          icon: Icons.autorenew_rounded,
                          selected: _splitType == 'rotating',
                          onTap: () =>
                              setState(() => _splitType = 'rotating'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SplitTypeCard(
                          title: 'Weekly',
                          subtitle:
                              'Pin sessions to specific days of the week',
                          icon: Icons.calendar_month_rounded,
                          selected: _splitType == 'weekly',
                          onTap: () =>
                              setState(() => _splitType = 'weekly'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _createCustom,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create & Add Sessions'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),

                  // flexible hint
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14,
                            color: cs.onSurface.withAlpha(120)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'You can always skip, combine sessions, or log outside your plan — your schedule is flexible.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(120),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Template card ─────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});
  final ProgramTemplateData template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.splitType == 'rotating'
                          ? 'Rotating'
                          : 'Weekly',
                      style: TextStyle(
                          fontSize: 11, color: cs.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(160),
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: template.sessions
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(s.colorValue).withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    Color(s.colorValue).withAlpha(120)),
                          ),
                          child: Text(s.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(s.colorValue))),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Split type card ───────────────────────────────────────────────────────────

class _SplitTypeCard extends StatelessWidget {
  const _SplitTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withAlpha(80),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? cs.primary : cs.onSurface.withAlpha(140)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? cs.onPrimaryContainer.withAlpha(180)
                        : cs.onSurface.withAlpha(140))),
          ],
        ),
      ),
    );
  }
}
