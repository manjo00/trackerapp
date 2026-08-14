/// One coach mark: a short tip anchored to a real widget on a screen.
///
/// Tips are shown the first time you open the screen they belong to, and any
/// tip added later appears on your next visit — that is how a new feature
/// introduces itself after an update.
class CoachTip {
  const CoachTip({
    required this.id,
    required this.screen,
    required this.target,
    required this.text,
    required this.sinceVersion,
    this.codexTopicId,
  });

  /// Stable, unique — it is what gets remembered as "seen". Never reuse an id
  /// for different advice, or the new tip will be silently skipped.
  final String id;

  /// Screen key this belongs to (see kCoachScreen* constants).
  final String screen;

  /// Id of the [CoachTarget] to spotlight. A tip whose target is not on
  /// screen right now is skipped and offered again next visit.
  final String target;

  final String text;

  /// App version this tip arrived in — used to badge it "New" for people who
  /// already used an older build.
  final String sinceVersion;

  /// Optional Codex topic for a "Learn more" link.
  final String? codexTopicId;
}

// Screen keys — one per screen that teaches itself.
const String kCoachHome = 'home';
const String kCoachLists = 'lists';
const String kCoachListDetail = 'list_detail';
const String kCoachPlanner = 'planner';
const String kCoachToday = 'today';
const String kCoachNotes = 'notes';
const String kCoachNotebook = 'notebook';
const String kCoachNoteEditor = 'note_editor';
const String kCoachWorkout = 'workout';
const String kCoachActiveWorkout = 'active_workout';
const String kCoachShifts = 'shifts';
const String kCoachHabits = 'habits';
const String kCoachTrackers = 'trackers';
const String kCoachArchived = 'archived';
const String kCoachCodex = 'codex';
