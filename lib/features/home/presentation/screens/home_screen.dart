import 'package:flutter/material.dart';

/// The app's landing dashboard (replaces the old Inbox tab).
///
/// Placeholder so the nav restructure compiles on its own — the real
/// fixed blocks (Urgent / Due today / Captured / This week) land in the
/// screens task of the organization plan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home blocks land in the next commit')),
    );
  }
}
