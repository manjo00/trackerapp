import 'package:flutter/material.dart';

/// A single row in the Notes overview: emoji on a colored chip, name, and an
/// optional note-count on the right. [icon] is an emoji; [color] tints the chip.
class NotebookTile extends StatelessWidget {
  const NotebookTile({
    required this.icon,
    required this.name,
    required this.color,
    required this.onTap,
    this.count,
    super.key,
  });

  final String icon;
  final String name;
  final Color color;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: TextStyle(color: cs.onSurface.withAlpha(120)),
                ),
              ],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(90)),
            ],
          ),
        ),
      ),
    );
  }
}
