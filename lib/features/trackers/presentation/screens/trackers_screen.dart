import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trackers_providers.dart';
import '../widgets/tracker_progress_card.dart';

/// The main Trackers tab — lists all user-created trackers with today's
/// progress, and provides a FAB to add a new one.
class TrackersScreen extends ConsumerWidget {
  const TrackersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(trackersWithProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trackers/add'),
        icon: const Icon(Icons.add),
        label: const Text('New tracker'),
        tooltip: 'Add tracker',
      ),
      body: trackersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trackers) {
          if (trackers.isEmpty) {
            return _EmptyTrackersPlaceholder(
              onAdd: () => context.push('/trackers/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: trackers.length,
            itemBuilder: (_, i) {
              final t = trackers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TrackerProgressCard(
                  tracker: t,
                  onTap: () => context.push(
                    '/trackers/${t.trackerId}',
                    extra: {
                      'name': t.name,
                      'icon': t.icon,
                      'trackerType': t.trackerType,
                    },
                  ),
                  onDelete: () => ref
                      .read(deleteTrackerProvider.notifier)
                      .delete(t.trackerId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyTrackersPlaceholder extends StatelessWidget {
  const _EmptyTrackersPlaceholder({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No trackers yet',
              style:
                  tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Track anything — prayers, water, workouts, meds, study chapters…',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create your first tracker'),
            ),
          ],
        ),
      ),
    );
  }
}
