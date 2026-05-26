import 'package:flutter/material.dart';
import 'app.dart';

/// App entry point.
///
/// [runApp] hands our root widget to Flutter's rendering engine.
/// In later steps we'll wrap this in a [ProviderScope] (Riverpod's
/// requirement) and pass in the database instance.
void main() {
  runApp(const LifeTrackerApp());
}
