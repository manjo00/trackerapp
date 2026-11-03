import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/tasks/presentation/providers/lists_providers.dart';
import 'package:life_tracker/features/tasks/presentation/screens/quick_add_task_screen.dart';

/// The widget's "+" must bring the keyboard up even when Uplan is already
/// running.
///
/// Regression (2026-11-02, found on the Z Flip 6): when the "+" brought back a
/// running app, the title field asked for the keyboard about 40 ms before
/// Android gave the window focus. Android ignores a request made that early,
/// and nothing asked again, so the sheet opened without a keyboard. Flutter
/// reports "resumed" only once the window has focus, so the sheet asks again
/// then, and keeps asking briefly: Android hides the keyboard as a window
/// comes to the front (Flutter's view isn't a text box for it), and on the
/// emulator that hide landed 20-90 ms after the sheet's ask.
void main() {
  Future<void> openSheetBeforeWindowFocus(WidgetTester tester) async {
    // The app is back on screen, but its window has no focus yet.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    addTearDown(() =>
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await tester.pumpWidget(ProviderScope(
      overrides: [taskListsProvider.overrideWith((ref) => Stream.value(const []))],
      child: const MaterialApp(home: QuickAddTaskScreen()),
    ));
    await tester.pump();
  }

  Iterable<String> keyboardCalls(WidgetTester tester) =>
      tester.testTextInput.log.map((call) => call.method);

  int keyboardAsks(WidgetTester tester) =>
      keyboardCalls(tester).where((m) => m == 'TextInput.show').length;

  /// What MainActivity sends when Android gives the window focus.
  Future<void> androidGivesWindowFocus(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'uplan/quick_add',
      const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('windowFocused')),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('asks for the keyboard again once the window has focus',
      (tester) async {
    await openSheetBeforeWindowFocus(tester);
    // This first ask is the one Android ignored on the phone.
    expect(keyboardCalls(tester), contains('TextInput.show'));
    tester.testTextInput.log.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(keyboardCalls(tester), contains('TextInput.show'));
  });

  testWidgets('keeps asking until the keyboard is up', (tester) async {
    // Android can hide the keyboard just after the first ask (it does so when
    // a window comes back to the front, since Flutter's view isn't a text box
    // for it), so one ask is not enough.
    await openSheetBeforeWindowFocus(tester);
    tester.testTextInput.log.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(keyboardCalls(tester).where((m) => m == 'TextInput.show'), hasLength(2));

    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.reset);
    await tester.pump();
    tester.testTextInput.log.clear();
    await tester.pump(const Duration(seconds: 1));
    expect(keyboardCalls(tester), isNot(contains('TextInput.show')));
  });

  testWidgets('stops asking after a moment when no keyboard comes up',
      (tester) async {
    // A hardware keyboard, say: the on-screen one never appears.
    await openSheetBeforeWindowFocus(tester);
    tester.testTextInput.log.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));

    expect(keyboardAsks(tester), inInclusiveRange(2, 8));
  });

  // Regression (2026-11-03, the Z Flip 6): Flutter's engine starts each window
  // believing it has focus, so a new window reports "resumed" before Android
  // gives it focus. On the phone the sheet's first frame and keyboard asks
  // came about 60 ms before the focus, all ignored, and nothing asked after
  // (no keyboard in 3 of 3). MainActivity now forwards Android's own focus.
  testWidgets('asks when Android gives the window focus', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [taskListsProvider.overrideWith((ref) => Stream.value(const []))],
      child: const MaterialApp(home: QuickAddTaskScreen()),
    ));
    await tester.pump();
    tester.testTextInput.log.clear();

    await androidGivesWindowFocus(tester);

    expect(keyboardCalls(tester), contains('TextInput.show'));
  });

  testWidgets('asks even if a keyboard looked up when the app left',
      (tester) async {
    // Leaving with the keyboard up can leave its height in Flutter's view
    // insets; the sheet must not take that for a keyboard that is up now.
    await openSheetBeforeWindowFocus(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.reset);
    await tester.pump();
    tester.testTextInput.log.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(keyboardCalls(tester), contains('TextInput.show'));
  });

  testWidgets('asks once the field gets its focus back a moment later',
      (tester) async {
    await openSheetBeforeWindowFocus(tester);
    final FocusNode title =
        tester.widget<TextField>(find.byType(TextField).first).focusNode!;
    title.unfocus();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await androidGivesWindowFocus(tester);

    title.requestFocus();
    await tester.pump();
    tester.testTextInput.log.clear(); // the field's own ask as it takes focus
    await tester.pump(const Duration(milliseconds: 150));

    expect(keyboardCalls(tester), contains('TextInput.show'));
  });

  testWidgets('does not bring the keyboard up when nothing is being typed',
      (tester) async {
    await openSheetBeforeWindowFocus(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    tester.testTextInput.log.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(keyboardCalls(tester), isNot(contains('TextInput.show')));
  });
}
