import '../../coach/data/coach_content.dart';
import '../../coach/data/coach_tip.dart';

/// The coach tip that demonstrates a Codex topic, if one exists — the link
/// behind the topic's "Show me" button. Pure, so it is unit-testable.
///
/// Prefers a tip that can actually be navigated to (has a `route`); a tip on
/// a screen that needs an id to open is no use to a button.
CoachTip? coachTipForTopic(String topicId) {
  CoachTip? fallback;
  for (final CoachTip t in kCoachTips) {
    if (t.codexTopicId != topicId) continue;
    if (t.route != null) return t;
    fallback ??= t;
  }
  return fallback;
}
