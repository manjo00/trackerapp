import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

/// A single note row in a notebook: title (or "Untitled"), an optional one-line
/// preview, a relative "edited" date, and a 📷 badge when it holds photos.
class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onTap,
    this.preview = '',
    this.photoCount = 0,
    super.key,
  });

  final Note note;
  final VoidCallback onTap;
  final String preview;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final bool untitled = note.title.trim().isEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                untitled ? 'Untitled' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: untitled ? FontStyle.italic : null,
                  color: untitled ? cs.onSurface.withAlpha(130) : cs.onSurface,
                ),
              ),
              if (preview.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  preview.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    _relativeDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(110),
                    ),
                  ),
                  if (photoCount > 0) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.photo_outlined,
                        size: 13, color: cs.onSurface.withAlpha(110)),
                    const SizedBox(width: 3),
                    Text(
                      '$photoCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withAlpha(110),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    const List<String> m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month]}';
  }
}
