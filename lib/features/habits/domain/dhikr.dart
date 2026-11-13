/// One du'a or dhikr of a morning or night list: a short name, its full
/// Arabic text and how many times it is said. Pure Dart.
class Dhikr {
  const Dhikr({
    required this.id,
    required this.title,
    required this.times,
    required this.text,
  });

  /// A stable key: today's count of this du'a is saved under it.
  final String id;

  /// A short Arabic name ("آية الكرسي").
  final String title;

  /// How many times it is said (1, 3, 4 or 100).
  final int times;

  /// The full Arabic text; a line break separates a heading ("بسم الله
  /// الرحمن الرحيم") from what follows.
  final String text;
}
