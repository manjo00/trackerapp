import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../notes/presentation/providers/notes_providers.dart';

/// Home dashboard's Notes block: quick access to the Notes tab plus the most
/// recently created/edited notebooks (tap one to jump straight in).
class NotesBlock extends ConsumerWidget {
  const NotesBlock({super.key});

  /// How many recent notebooks to surface on Home.
  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Notebook> notebooks = ref.watch(recentNotebooksProvider);

    // Empty state: a single tile inviting the user into Notes.
    if (notebooks.isEmpty) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.sticky_note_2_rounded, color: cs.tertiary),
          title: const Text('Notes'),
          subtitle: const Text('Create your first notebook'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/notes'),
        ),
      );
    }

    final List<Notebook> recent = notebooks.take(_maxShown).toList();

    return Card(
      child: Column(
        children: [
          for (final Notebook nb in recent)
            InkWell(
              onTap: () => context.push('/notes/notebook/${nb.id}'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(nb.colorValue).withAlpha(38),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(nb.icon,
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nb.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: cs.onSurface.withAlpha(90)),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
          // Footer: jump to the full Notes tab.
          InkWell(
            onTap: () => context.push('/notes'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.sticky_note_2_rounded,
                      size: 18, color: cs.tertiary),
                  const SizedBox(width: 8),
                  Text(
                    'All notes',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: cs.tertiary.withAlpha(160)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
