import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

/// What the picker hands back. A record rather than a bare `int?`, so that
/// "the user chose Unfiled" (notebookId null) is distinguishable from "the
/// user dismissed the sheet" (the whole result null).
typedef NotebookChoice = ({int? notebookId});

/// Bottom sheet listing Unfiled plus every notebook. The one the note already
/// lives in is shown ticked and disabled, so the list reads as "where else
/// could this go" rather than a form to fill in.
Future<NotebookChoice?> showNotebookPickerSheet(
  BuildContext context, {
  required List<Notebook> notebooks,
  required int? currentNotebookId,
  String title = 'Move to',
}) {
  return showModalBottomSheet<NotebookChoice>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) {
      final ColorScheme cs = Theme.of(ctx).colorScheme;
      Widget row({
        required String icon,
        required String name,
        required Color color,
        required int? id,
      }) {
        final bool here = id == currentNotebookId;
        return ListTile(
          leading: Text(icon, style: const TextStyle(fontSize: 22)),
          title: Text(name),
          trailing: here
              ? Icon(Icons.check_rounded, color: cs.primary)
              : null,
          enabled: !here,
          onTap: here ? null : () => Navigator.of(ctx).pop((notebookId: id)),
        );
      }

      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            row(icon: '📥', name: 'Unfiled', color: cs.primary, id: null),
            if (notebooks.isNotEmpty) const Divider(height: 1),
            for (final Notebook nb in notebooks)
              row(
                icon: nb.icon,
                name: nb.name,
                color: Color(nb.colorValue),
                id: nb.id,
              ),
          ],
        ),
      );
    },
  );
}
