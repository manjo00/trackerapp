import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/habit_with_status.dart';
import '../providers/habits_providers.dart';
import '../widgets/empty_habits_placeholder.dart';
import '../widgets/habit_tile.dart';

/// Main habits tab — shows all habits and today's completion state.
///
/// Uses [ConsumerWidget] to watch [habitsWithStatusProvider].
///
/// [habitsWithStatusProvider] is a StreamProvider — it emits a new list
/// every time the database changes (add habit, toggle completion, etc.).
/// [ref.watch] subscribes to that stream; the widget rebuilds automatically
/// on each emission.
class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue has three states: loading / error / data.
    // .when() handles all three without any if/else boilerplate.
    final AsyncValue<List<HabitWithStatus>> habitsAsync =
        ref.watch(habitsWithStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
      ),
      body: habitsAsync.when(
        // ── Loading ──────────────────────────────────────────────────────
        loading: () => const Center(child: CircularProgressIndicator()),

        // ── Error ─────────────────────────────────────────────────────────
        error: (Object err, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong:\n$err',
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // ── Data ──────────────────────────────────────────────────────────
        data: (List<HabitWithStatus> habits) {
          if (habits.isEmpty) {
            return const EmptyHabitsPlaceholder();
          }

          return ListView.builder(
            // Top padding so the first card doesn't touch the app bar.
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: habits.length,
            itemBuilder: (BuildContext context, int index) {
              return HabitTile(item: habits[index]);
            },
          );
        },
      ),

      // ── FAB — navigate to AddHabitScreen ─────────────────────────────────
      floatingActionButton: FloatingActionButton(
        // context.push keeps the bottom nav visible in the shell while
        // pushing AddHabitScreen as a full-screen overlay.
        onPressed: () => context.push('/habits/add'),
        tooltip: 'Add habit',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
