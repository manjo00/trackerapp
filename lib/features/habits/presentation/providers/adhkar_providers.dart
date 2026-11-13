import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../data/adhkar_store.dart';
import '../adhkar_haptics.dart';
import 'habits_providers.dart';

/// What the du'a counter does: open today's counts and save each change.
final adhkarActionsProvider = Provider<AdhkarActions>((ref) => AdhkarActions(
      ref.read(habitsRepositoryProvider),
      AdhkarStore(ref.read(sharedPreferencesProvider)),
    ));

/// The counter's tick and buzz. Tests swap in a recorder.
final adhkarHapticsProvider =
    Provider<AdhkarHaptics>((ref) => const AdhkarHaptics());
