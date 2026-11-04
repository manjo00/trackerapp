import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/coach/data/coach_content.dart';
import 'package:life_tracker/features/coach/data/coach_tip.dart';

/// The Habits screen's first tip describes Look A: the circle ticks, a tap on
/// the habit opens it.
void main() {
  test('the habits tip says the circle ticks and a tap opens the habit', () {
    final CoachTip tip =
        kCoachTips.firstWhere((CoachTip t) => t.id == 'habits.gestures');
    expect(tip.text, contains('Tap the circle to tick'));
    expect(tip.text, contains('tap the habit to edit it'));
  });
}
