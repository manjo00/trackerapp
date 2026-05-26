import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_database.dart';

part 'database_provider.g.dart';

/// Provides the single [AppDatabase] instance for the entire app.
///
/// [keepAlive: true] means Riverpod never disposes this provider — the
/// database connection stays open for the lifetime of the app.
///
/// Widgets and other providers access it with:
/// ```dart
/// final db = ref.watch(appDatabaseProvider);
/// ```
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final AppDatabase db = AppDatabase();

  // Close the database when this provider is disposed.
  // With keepAlive: true this only runs when the ProviderScope is destroyed
  // (i.e. when the app closes).
  ref.onDispose(db.close);

  return db;
}
