/// Builds a stable image filename from a caller-supplied monotonic [seed]
/// (e.g. `DateTime.now().microsecondsSinceEpoch`).
///
/// Kept pure — the timestamp stays OUTSIDE the function so this is
/// deterministic and unit-testable. The extension is normalised: lowercased,
/// a leading dot stripped, empty falls back to `jpg`.
String buildImageFilename({required int seed, String extension = 'jpg'}) {
  var ext = extension.toLowerCase();
  if (ext.startsWith('.')) ext = ext.substring(1);
  if (ext.isEmpty) ext = 'jpg';
  return 'img_$seed.$ext';
}
