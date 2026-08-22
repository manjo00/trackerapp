// Small pure helpers for the home-screen widget payload. Kept out of
// HomeWidgetService so they can be unit-tested without a database or a
// platform channel.

/// ARGB int → the "#AARRGGBB" string the native side parses.
///
/// Colours cross the platform channel as strings rather than ints: a Dart int
/// like 0xFF5FC6D8 doesn't survive the round trip as a 32-bit signed value.
String argbToHex(int argb) =>
    '#${(argb & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Stable checksum of an encoded widget payload (FNV-1a, 32-bit).
///
/// Deliberately NOT `String.hashCode`, which carries no promise of returning
/// the same value in a later process. This is compared against a value stored
/// in preferences by an earlier app launch, so it has to be reproducible across
/// restarts — otherwise the "nothing changed, skip the push" check would never
/// fire and every resume would redraw all three widgets for nothing.
String payloadChecksum(String input) {
  int hash = 0x811C9DC5;
  for (int i = 0; i < input.length; i++) {
    hash ^= input.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16);
}
