import 'coach_tip.dart';

/// Every coach mark in the app.
///
/// Adding a tip here is all it takes for it to appear — on a fresh install as
/// part of that screen's first-visit tour, and for existing users on their
/// next visit to the screen, badged "New" when `sinceVersion` is newer than
/// the version they last ran.
///
/// Rules of thumb: point at things that have no label, are behind a gesture,
/// or that people ask about. Keep each tip to one sentence. Never reuse an id.
///
/// ⚠ A tip only ever fires if a [CoachTarget] with its `target` id is mounted
/// on that screen. Adding a tip here WITHOUT wrapping its widget makes dead
/// content that silently never shows — always do both.
///
/// TODO(coach): screens still to wire — Today, Lists overview, Notes
/// overview, Notebook detail, Active workout, Habits, Trackers, Archived.
/// Their tips are written but held back until their targets exist.
const List<CoachTip> kCoachTips = [
  // ── Home ────────────────────────────────────────────────────────────────
  CoachTip(
    id: 'home.edit',
    screen: kCoachHome,
    target: 'home.edit',
    text:
        'Home is yours to build. Tap ✎ to add blocks — a list, a label, '
        'your habits, today\'s shift, even a whole note you can type in.',
    sinceVersion: '1.15.0',
    codexTopicId: 'home-blocks',
  ),
  CoachTip(
    id: 'home.header',
    screen: kCoachHome,
    target: 'home.firstHeader',
    text:
        'Long-press a block\'s header to drag it, or tap the chevron to '
        'fold it away.',
    sinceVersion: '1.15.0',
    codexTopicId: 'home-blocks',
  ),
  CoachTip(
    id: 'home.fab',
    screen: kCoachHome,
    target: 'home.fab',
    text:
        'Adding a task? Just type when it is due — "tomorrow 5pm" — and '
        'tap the suggestion that appears.',
    sinceVersion: '1.15.0',
    codexTopicId: 'task-nl-dates',
  ),

  // ── Lists ───────────────────────────────────────────────────────────────

  // ── List detail ─────────────────────────────────────────────────────────
  CoachTip(
    id: 'listDetail.menu',
    screen: kCoachListDetail,
    target: 'listDetail.menu',
    text:
        'This menu renames or recolours the list — and can auto-archive '
        'tasks the moment you tick them off.',
    sinceVersion: '1.15.0',
    codexTopicId: 'list-auto-archive',
  ),

  // ── Planner ─────────────────────────────────────────────────────────────
  CoachTip(
    id: 'planner.longPress',
    screen: kCoachPlanner,
    target: 'planner.calendar',
    text:
        'Hold any day to add a task straight to that date — no date picker '
        'needed.',
    sinceVersion: '1.15.0',
    codexTopicId: 'calendar-long-press',
  ),

  // ── Today ───────────────────────────────────────────────────────────────

  // ── Notes ───────────────────────────────────────────────────────────────

  // ── Note editor ─────────────────────────────────────────────────────────
  CoachTip(
    id: 'noteEditor.arrange',
    screen: kCoachNoteEditor,
    target: 'noteEditor.arrange',
    text:
        'Rearranging: hold a line to drag it. Drop it in a gap to move it '
        'out, or hold it over a heading to tuck it inside.',
    sinceVersion: '1.15.0',
    codexTopicId: 'notes-arrange',
  ),
  CoachTip(
    id: 'noteEditor.menu',
    screen: kCoachNoteEditor,
    target: 'noteEditor.menu',
    text: 'Long note? Collapse all folds every heading at once.',
    sinceVersion: '1.15.0',
    codexTopicId: 'notes-fold',
  ),

  // ── Workout ─────────────────────────────────────────────────────────────
  CoachTip(
    id: 'workout.myWorkouts',
    screen: kCoachWorkout,
    target: 'workout.myWorkouts',
    text: 'Build a workout once here, then start it any day with one tap.',
    sinceVersion: '1.15.0',
    codexTopicId: 'workout-my-workouts',
  ),

  // ── Active workout ──────────────────────────────────────────────────────

  // ── Work shifts ─────────────────────────────────────────────────────────
  CoachTip(
    id: 'shifts.tap',
    screen: kCoachShifts,
    target: 'shifts.calendar',
    text:
        'Tap a day to set a day or night shift and label it with your own '
        'code (ICU1, ER…). Hold a day instead to add a task to it.',
    sinceVersion: '1.15.0',
    codexTopicId: 'shifts',
  ),

  // ── Habits ──────────────────────────────────────────────────────────────

  // ── Trackers ────────────────────────────────────────────────────────────

  // ── Archived ────────────────────────────────────────────────────────────

  // ── Codex ───────────────────────────────────────────────────────────────
  CoachTip(
    id: 'codex.gems',
    screen: kCoachCodex,
    target: 'codex.gems',
    text:
        'Everything the app can do is written down here. Start with 💡 '
        'Hidden gems — the tricks you would never find by tapping.',
    sinceVersion: '1.15.0',
    codexTopicId: 'codex-itself',
  ),
];
