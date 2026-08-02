import 'dart:convert';

/// Encodes the pinned-note block's config: `{"noteId": 5}`.
String pinnedNoteConfig(int noteId) => jsonEncode({'noteId': noteId});

/// Reads the pinned note id back out of a block's [configJson].
/// Null/malformed/missing → null (the block renders its "choose a note"
/// placeholder instead of crashing on bad data).
int? pinnedNoteIdFromConfig(String? configJson) {
  if (configJson == null || configJson.isEmpty) return null;
  try {
    final dynamic decoded = jsonDecode(configJson);
    if (decoded is! Map) return null;
    final dynamic id = decoded['noteId'];
    return id is int ? id : null;
  } on FormatException {
    return null;
  }
}
