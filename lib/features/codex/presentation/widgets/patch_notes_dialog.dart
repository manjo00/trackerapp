import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/release_notes.dart';

const String kPatchNotesSeenKey = 'patch_notes_seen_version';

/// Shows "what's new" once, the first time the app opens after an update.
///
/// Silent on a **fresh install** (there is nothing to catch up on — the
/// version is recorded on that first run) and silent when the stored version
/// already matches, so this is safe to call on every launch.
Future<void> maybeShowPatchNotes(
  BuildContext context,
  SharedPreferences prefs,
) async {
  final String? seen = prefs.getString(kPatchNotesSeenKey);
  // Record either way, so a fresh install never gets a popup for a release it
  // has always had.
  await prefs.setString(kPatchNotesSeenKey, kCurrentRelease);
  if (seen == null || seen == kCurrentRelease) return;
  if (!context.mounted || kReleaseHighlights.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("What's new in v$kCurrentRelease"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final String line in kReleaseHighlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 10),
                      child: Text('•'),
                    ),
                    Expanded(
                      child: Text(line,
                          style: const TextStyle(fontSize: 14, height: 1.45)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Got it'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            // The Codex lists these changes under "What's new" at the top,
            // each with its own "Show me".
            ctx.push('/codex');
          },
          child: const Text('Show me the tips'),
        ),
      ],
    ),
  );
}
