import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/startup/launch_work.dart';

/// The launch work (re-book every reminder, purge Recently deleted, sync the
/// widgets, What's new, the update check) runs on a normal open, never when
/// the home-screen widget's "+" opens the quick-add sheet.
///
/// Regression (2026-11-01, Tester chat): on a quick-add open that work ran
/// right after the sheet appeared, for 1.4 s on a fast build and 2.5 s on a
/// debug build, while the user typed.
void main() {
  test('a quick-add open skips the launch work', () {
    expect(wantsLaunchWork('/quick-add'), isFalse);
  });

  test('every normal start does it', () {
    for (final String location in ['/home', '/today', '/lists', '/notes/3']) {
      expect(wantsLaunchWork(location), isTrue, reason: location);
    }
  });
}
