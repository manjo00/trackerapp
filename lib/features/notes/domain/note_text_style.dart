/// Body/heading font size for a note text block by [level]:
/// 0 = body (16), 1 = H1 (26), 2 = H2 (22), 3 = H3 (19). Unknown → body.
///
/// Pure so the size mapping is unit-testable; the widget composes weight,
/// italic, and the highlight background around it.
double noteHeadingFontSize(int level) {
  switch (level) {
    case 1:
      return 26;
    case 2:
      return 22;
    case 3:
      return 19;
    default:
      return 16;
  }
}
