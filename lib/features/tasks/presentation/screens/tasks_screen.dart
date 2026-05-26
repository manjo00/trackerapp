import 'package:flutter/material.dart';

/// Placeholder for the Tasks feature (Phase 1.5).
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_box_outline_blank_rounded, size: 64),
            SizedBox(height: 16),
            Text(
              'Tasks',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
