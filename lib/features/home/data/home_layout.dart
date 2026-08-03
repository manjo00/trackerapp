/// Distributes [items] over [columns] round-robin (item i → column i mod n),
/// preserving the user's order so the TOP of every column holds their
/// highest-priority blocks. columns <= 1 (or empty input) → one column.
/// Pure, unit-tested — drives the wide-screen Home layout.
List<List<T>> distributeRoundRobin<T>(List<T> items, int columns) {
  final int n = columns < 1 ? 1 : columns;
  final List<List<T>> out = [for (int c = 0; c < n; c++) <T>[]];
  for (int i = 0; i < items.length; i++) {
    out[i % n].add(items[i]);
  }
  return out;
}
