import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'github_feedback_service.dart';

final githubFeedbackServiceProvider =
    Provider<GithubFeedbackService>((ref) => GithubFeedbackService());

/// The saved config (null until the user sets it up). Settings invalidates
/// this after saving so its tile subtitle updates immediately.
final githubFeedbackConfigProvider =
    FutureProvider<GithubFeedbackConfig?>((ref) {
  return ref.watch(githubFeedbackServiceProvider).loadConfig();
});
