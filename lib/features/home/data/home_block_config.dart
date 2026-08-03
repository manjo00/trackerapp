import 'dart:convert';

/// Readers/writers for `home_blocks.configJson` — a small JSON object of
/// per-block settings. All readers shrug off null/malformed data (a block
/// falls back to defaults instead of crashing). All pure, unit-tested.

Map<String, Object?> _decode(String? configJson) {
  if (configJson == null || configJson.isEmpty) return const {};
  try {
    final dynamic decoded = jsonDecode(configJson);
    return decoded is Map ? decoded.cast<String, Object?>() : const {};
  } on FormatException {
    return const {};
  }
}

/// Returns [configJson] with [updates] applied (a null value removes its key).
String mergeConfig(String? configJson, Map<String, Object?> updates) {
  final Map<String, Object?> map = Map.of(_decode(configJson));
  for (final MapEntry<String, Object?> e in updates.entries) {
    if (e.value == null) {
      map.remove(e.key);
    } else {
      map[e.key] = e.value;
    }
  }
  return jsonEncode(map);
}

int? _intOf(String? json, String key) {
  final Object? v = _decode(json)[key];
  return v is int ? v : null;
}

bool _boolOf(String? json, String key) => _decode(json)[key] == true;

// ── Which thing a block points at ─────────────────────────────────────────

/// Pinned note: `{"noteId": 5}`.
String pinnedNoteConfig(int noteId) => jsonEncode({'noteId': noteId});
int? pinnedNoteIdFromConfig(String? configJson) =>
    _intOf(configJson, 'noteId');

/// List block: `{"listId": 3}`.
String listConfig(int listId) => jsonEncode({'listId': listId});
int? listIdFromConfig(String? configJson) => _intOf(configJson, 'listId');

/// Label block: `{"labelId": 2}`.
String labelConfig(int labelId) => jsonEncode({'labelId': labelId});
int? labelIdFromConfig(String? configJson) => _intOf(configJson, 'labelId');

// ── Control pack (C) ──────────────────────────────────────────────────────

/// Max items a task block shows; null = show everything (today's behavior).
int? limitFromConfig(String? configJson) => _intOf(configJson, 'limit');

/// This-week window length in days; null = the default 7.
int? daysFromConfig(String? configJson) => _intOf(configJson, 'days');

/// Whole block (header included) disappears while it has nothing to show.
bool hideWhenEmptyFromConfig(String? configJson) =>
    _boolOf(configJson, 'hideWhenEmpty');

/// Folded on Home: header (with its ▸ chevron) only.
bool collapsedFromConfig(String? configJson) =>
    _boolOf(configJson, 'collapsed');
