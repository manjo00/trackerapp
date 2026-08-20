import 'package:flutter/material.dart';

import '../../data/codex_content.dart';
import '../../data/release_notes.dart';
import '../../domain/whats_new.dart';
import '../../data/codex_topic.dart';
import '../../domain/codex_search.dart';
import 'codex_topic_screen.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../coach/presentation/coach_target.dart';

/// The Codex — Uplan's built-in manual. Search across every topic, browse by
/// area, or filter to the hidden features most people never find.
class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  final TextEditingController _search = TextEditingController();
  bool _gemsOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String query = _search.text;
    final List<CodexTopic> pool = _gemsOnly
        ? hiddenGems(kCodexTopics)
        : kCodexTopics;
    final List<CodexTopic> results = searchCodex(pool, query);
    final bool searching = query.trim().isNotEmpty;

    return CoachMarks(
      screen: kCoachCodex,
      child: Scaffold(
        appBar: AppBar(title: const Text('Codex')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search the manual…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searching
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: CoachTarget(
                  id: 'codex.gems',
                  child: FilterChip(
                    label: const Text('💡 Hidden gems'),
                    selected: _gemsOnly,
                    onSelected: (v) => setState(() => _gemsOnly = v),
                  ),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Nothing matches "$query".',
                          style: TextStyle(color: cs.onSurface.withAlpha(140)),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: searching || _gemsOnly
                          ? [for (final CodexTopic t in results) _tile(t, cs)]
                          : _byCategory(results, cs),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Browse layout: the "What's new" shelf (this release only), then a header
  /// per area. New topics are deliberately pulled OUT of their areas while
  /// they are new, and drop back in on their own once the release moves on.
  List<Widget> _byCategory(List<CodexTopic> topics, ColorScheme cs) {
    final List<Widget> out = [];
    final List<CodexTopic> fresh = whatsNewTopics(topics, kCurrentRelease);
    if (fresh.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              'NEW IN v$kCurrentRelease',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
            ),
          ],
        ),
      ));
      out.addAll(fresh.map((t) => _tile(t, cs)));
    }
    topics = browsableTopics(topics, kCurrentRelease);
    for (final CodexCategory c in CodexCategory.values) {
      final List<CodexTopic> mine = topics
          .where((t) => t.category == c)
          .toList();
      if (mine.isEmpty) continue;
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Row(
            children: [
              Icon(c.icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                c.title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
      out.addAll(mine.map((t) => _tile(t, cs)));
    }
    return out;
  }

  Widget _tile(CodexTopic t, ColorScheme cs) => ListTile(
    leading: Icon(t.category.icon, color: cs.onSurface.withAlpha(150)),
    title: Row(
      children: [
        Flexible(child: Text(t.title)),
        if (t.hidden) ...[
          const SizedBox(width: 6),
          const Text('💡', style: TextStyle(fontSize: 13)),
        ],
      ],
    ),
    subtitle: Text(t.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CodexTopicScreen(topic: t))),
  );
}
