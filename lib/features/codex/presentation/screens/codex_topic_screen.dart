import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../data/codex_topic.dart';
import '../../domain/codex_coach_link.dart';

/// One Codex article. Steps auto-number within each consecutive run, so a
/// topic can have several separate "1, 2, 3" sequences.
class CodexTopicScreen extends ConsumerWidget {
  const CodexTopicScreen({required this.topic, super.key});

  final CodexTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    // If a coach mark demonstrates this topic, offer to replay it in place.
    final CoachTip? demo = coachTipForTopic(topic.id);

    final List<Widget> children = [];
    int stepNo = 0;
    for (final CodexBlock b in topic.body) {
      if (b.kind == CodexBlockKind.step) {
        stepNo++;
      } else {
        stepNo = 0;
      }
      children.add(_block(b, stepNo, cs, text));
    }

    return Scaffold(
      appBar: AppBar(title: Text(topic.category.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(topic.title,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
              ),
              if (topic.hidden)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text('💡', style: TextStyle(fontSize: 20)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(topic.summary,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cs.onSurface.withAlpha(160))),
          if (demo != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final String? route = demo.route;
                  // Un-see it, then go to its screen — the coach marks fire
                  // on arrival and put the spotlight on the real control.
                  await ref.read(coachControllerProvider).replay(demo.id);
                  if (!context.mounted) return;
                  if (route != null) {
                    context.go(route);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Open that screen and the tip will '
                            'show you where it is.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text('Show me'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _block(
      CodexBlock b, int stepNo, ColorScheme cs, TextTheme text) {
    switch (b.kind) {
      case CodexBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(b.text,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );
      case CodexBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(b.text, style: const TextStyle(fontSize: 15, height: 1.5)),
        );
      case CodexBlockKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: cs.onSurface.withAlpha(120),
                      shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Text(b.text,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ],
          ),
        );
      case CodexBlockKind.step:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                    color: cs.primaryContainer, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$stepNo',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer)),
              ),
              Expanded(
                child: Text(b.text,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ],
          ),
        );
      case CodexBlockKind.tip:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer.withAlpha(110),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 10, top: 1),
                child: Text('💡', style: TextStyle(fontSize: 15)),
              ),
              Expanded(
                child: Text(b.text,
                    style: const TextStyle(fontSize: 14, height: 1.45)),
              ),
            ],
          ),
        );
    }
  }
}
