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
/// A tip with no `target` is a screen-level welcome: it dims and shows a
/// centred card. Give it a `target` only when there is one control worth
/// pointing at.
const List<CoachTip> kCoachTips = [
  // ── Home ────────────────────────────────────────────────────────────────
  CoachTip(
    id: 'home.edit',
    screen: kCoachHome,
    route: '/home',
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
    route: '/home',
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
    route: '/home',
    target: 'home.fab',
    text:
        'Adding a task? Just type when it is due — "tomorrow 5pm" — and '
        'tap the suggestion that appears.',
    sinceVersion: '1.15.0',
    codexTopicId: 'task-nl-dates',
  ),

  // ── Lists ───────────────────────────────────────────────────────────────
  CoachTip(
    id: 'lists.intro',
    screen: kCoachLists,
    route: '/lists',
    text:
        "Lists hold your tasks. Anything you add without picking one "
        'lands in Captured.',
    sinceVersion: '1.15.0',
    codexTopicId: 'lists-labels',
  ),

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
    route: '/planner',
    target: 'planner.calendar',
    text:
        'Hold any day to add a task straight to that date — no date picker '
        'needed.',
    sinceVersion: '1.15.0',
    codexTopicId: 'calendar-long-press',
  ),

  // ── Today ───────────────────────────────────────────────────────────────
  CoachTip(
    id: 'today.intro',
    screen: kCoachToday,
    route: '/today',
    text:
        "Today pulls together everything due now — habits, tasks and your "
        'checklists — so you can work straight down it.',
    sinceVersion: '1.15.0',
  ),

  // ── Notes ───────────────────────────────────────────────────────────────
  CoachTip(
    id: 'notes.intro',
    screen: kCoachNotes,
    route: '/notes',
    text:
        "Notebooks group your notes. A note is a stack of lines: text, "
        'checkboxes, photos and dividers.',
    sinceVersion: '1.15.0',
    codexTopicId: 'notes-basics',
  ),
  CoachTip(
    id: 'notebook.templates',
    screen: kCoachNotebook,
    text:
        "New notes can start from one of your templates — handy when every "
        'round has the same shape.',
    sinceVersion: '1.15.0',
    codexTopicId: 'notes-templates',
  ),

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
    route: '/workout',
    target: 'workout.myWorkouts',
    text: 'Build a workout once here, then start it any day with one tap.',
    sinceVersion: '1.15.0',
    codexTopicId: 'workout-my-workouts',
  ),

  // ── Active workout ──────────────────────────────────────────────────────
  CoachTip(
    id: 'activeWorkout.hints',
    screen: kCoachActiveWorkout,
    text:
        "Each row shows what you lifted last time — tap that hint to copy "
        "it in, and hold a row to delete the set. No '.' key? Type a comma.",
    sinceVersion: '1.15.0',
    codexTopicId: 'workout-session',
  ),

  // ── Work shifts ─────────────────────────────────────────────────────────
  CoachTip(
    id: 'shifts.tap',
    screen: kCoachShifts,
    route: '/schedule',
    target: 'shifts.calendar',
    text:
        'Tap a day to set a day or night shift and label it with your own '
        'code (ICU1, ER…). Hold a day instead to add a task to it.',
    sinceVersion: '1.15.0',
    codexTopicId: 'shifts',
  ),

  // ── Habits ──────────────────────────────────────────────────────────────
  CoachTip(
    id: 'habits.gestures',
    screen: kCoachHabits,
    route: '/habits',
    text:
        'Tap to tick a habit off, hold to edit it, swipe to delete it.',
    sinceVersion: '1.15.0',
    codexTopicId: 'habits',
  ),

  // ── Trackers ────────────────────────────────────────────────────────────
  CoachTip(
    id: 'trackers.intro',
    screen: kCoachTrackers,
    route: '/trackers',
    text:
        "Trackers are checklists you design — a daily one makes a perfect "
        'medications list, and it shows up on Today.',
    sinceVersion: '1.15.0',
    codexTopicId: 'trackers',
  ),

  // ── Archived ────────────────────────────────────────────────────────────
  CoachTip(
    id: 'archived.intro',
    screen: kCoachArchived,
    route: '/archived',
    text:
        "Nothing you archive is gone — restore it here, or delete it for "
        'good when you are sure.',
    sinceVersion: '1.15.0',
    codexTopicId: 'archive',
  ),

  // ── Codex ───────────────────────────────────────────────────────────────
  CoachTip(
    id: 'codex.gems',
    screen: kCoachCodex,
    route: '/codex',
    target: 'codex.gems',
    text:
        'Everything the app can do is written down here. Start with 💡 '
        'Hidden gems — the tricks you would never find by tapping.',
    sinceVersion: '1.15.0',
    codexTopicId: 'codex-itself',
  ),
];
