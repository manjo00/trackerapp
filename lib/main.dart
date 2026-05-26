import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// App entry point.
///
/// [ProviderScope] is Riverpod's required wrapper — it is the container
/// that stores every provider's state.  Without it, any `ref.watch()` call
/// would throw at runtime.  It wraps the entire widget tree so all widgets
/// have access to providers.
void main() {
  runApp(
    const ProviderScope(
      child: LifeTrackerApp(),
    ),
  );
}
