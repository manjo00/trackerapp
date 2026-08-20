import 'codex_topic.dart';

/// The Codex: Uplan's built-in manual. Static content — no database, works
/// offline, ships with the app. Topics flagged `hidden: true` are the things
/// you would never discover by tapping around; they get a 💡 badge and are
/// collected under "Hidden gems".
///
/// Keep this in step with the app: when a feature changes, update its topic.
const List<CodexTopic> kCodexTopics = [
  // ── Getting around ──────────────────────────────────────────────────────
  CodexTopic(
    id: 'codex-itself',
    title: 'About the Codex',
    category: CodexCategory.basics,
    summary: 'What this manual is, and how to get answers out of it fast.',
    keywords: ['help', 'manual', 'guide', 'tutorial', 'how to', 'docs'],
    body: [
      CodexBlock.p(
          'The Codex documents every part of Uplan — including the things you '
          'would never find by tapping around. It works offline and ships '
          'with the app, so it is always in step with the version you have.'),
      CodexBlock.heading('Finding things'),
      CodexBlock.bullet(
          'Search matches titles, the text of every article, and synonyms — '
          'so describing a feature in your own words usually finds it.'),
      CodexBlock.bullet(
          'The 💡 Hidden gems chip filters to the buried features: gestures, '
          'shortcuts and tricks that have no visible button.'),
      CodexBlock.bullet(
          'With the search box empty, topics are grouped by area — read it '
          'like a manual.'),
      CodexBlock.tip(
          'A 💡 next to a topic means "you would not have discovered this on '
          'your own". If you only read a few articles, read those.'),
      CodexBlock.p(
          'Where an article has a **Show me** button, tapping it takes you to '
          'the screen and highlights the exact control it describes — the '
          'same tip you saw the first time you opened that screen.'),
      CodexBlock.p(
          'Every new feature is added here as it is built, so the Codex stays '
          'a complete picture of what the app can do.'),
    ],
  ),
  CodexTopic(
    id: 'nav',
    title: 'Tabs, drawer and where things live',
    category: CodexCategory.basics,
    summary: 'The bottom bar, the side drawer, and how to choose your tabs.',
    keywords: ['navigation', 'menu', 'bottom bar'],
    body: [
      CodexBlock.p(
          'The bottom bar holds your most-used screens (Home, Lists and '
          'Planner by default). Everything else lives in the drawer — swipe '
          'from the left edge or tap the ☰ icon.'),
      CodexBlock.heading('Choose your own tabs'),
      CodexBlock.step('Open the drawer → Settings.'),
      CodexBlock.step('Go to Tabs.'),
      CodexBlock.step('Tick the screens you want in the bottom bar.'),
      CodexBlock.p(
          'A screen you remove from the bar stays reachable from the drawer '
          '— the drawer only lists what is not already in the bar, so you '
          'never see the same thing twice.'),
      CodexBlock.tip(
          'Settings → "Open at launch" picks which screen Uplan opens on. '
          'If you plan your day on the Planner, start there.'),
    ],
  ),
  CodexTopic(
    id: 'appearance',
    title: 'Theme and the start of your week',
    category: CodexCategory.basics,
    summary: 'Light/dark mode, and Sunday vs Monday week starts.',
    keywords: ['dark mode', 'sunday', 'monday', 'colours'],
    body: [
      CodexBlock.p(
          'The drawer has a quick light/dark toggle. Uplan follows Material '
          'colours, so both themes stay readable in a bright ward or a dark '
          'on-call room.'),
      CodexBlock.p(
          'Settings → Appearance → "Week starts on Sunday" changes every '
          'calendar in the app at once: the planner strip, the shift month '
          'view, the workout week strip, weekly targets, and the home-screen '
          'widget.'),
    ],
  ),

  // ── Tasks & lists ───────────────────────────────────────────────────────
  CodexTopic(
    id: 'task-add',
    title: 'Adding tasks',
    category: CodexCategory.tasks,
    summary: 'The + button, and the fields worth filling in.',
    body: [
      CodexBlock.p(
          'Tap the ✚ button on Home, a list, or the Planner. Type a title and '
          'save — everything else is optional.'),
      CodexBlock.bullet('Due date and time — when it should happen.'),
      CodexBlock.bullet('Priority — Low, Medium or High (colours the dot).'),
      CodexBlock.bullet('List and section — where it is filed.'),
      CodexBlock.bullet('Labels — cross-cutting tags like "ward" or "home".'),
      CodexBlock.bullet('Note — any detail you want with it.'),
      CodexBlock.p(
          'A task with no list lands in Captured — the catch-all for things '
          'you jotted down before deciding where they belong.'),
    ],
  ),
  CodexTopic(
    id: 'task-nl-dates',
    title: 'Type the date instead of picking it',
    category: CodexCategory.tasks,
    hidden: true,
    summary: 'Write "tomorrow 5pm" in the title and tap the suggestion.',
    keywords: ['natural language', 'auto time', 'auto date', 'quick date'],
    body: [
      CodexBlock.p(
          'While typing a task title, Uplan reads it for a date or time. If '
          'it finds one, a "Set due …" chip appears under the field. Tap the '
          'chip and the due date/time is filled in — and the words are '
          'removed from the title so it stays clean.'),
      CodexBlock.heading('What it understands'),
      CodexBlock.bullet('Times: 5pm · 17:00 · 12:50pm · @1450 · at 1250'),
      CodexBlock.bullet('Days: today · tomorrow'),
      CodexBlock.bullet('Dates: july 12 · 12 july · 12jul · 12th'),
      CodexBlock.p(
          '"12th" on its own means the 12th of the current month. Both a date '
          'and a time can appear together, in any order.'),
      CodexBlock.tip(
          'It is deliberately strict so clinical shorthand is never mistaken '
          'for a date — "bed 7", "O2 30" and "35flow" stay as plain text.'),
    ],
  ),
  CodexTopic(
    id: 'task-gestures',
    title: 'Tap, hold, swipe — what each one does',
    category: CodexCategory.tasks,
    hidden: true,
    summary: 'Tap opens details, only the circle completes.',
    keywords: ['gestures', 'complete', 'swipe', 'long press', 'accidental'],
    body: [
      CodexBlock.bullet(
          'Tap the circle — completes (or un-completes) the task. This is the '
          'only tap that marks something done.'),
      CodexBlock.bullet(
          'Tap the task text — opens the detail card: the full note, due '
          'date, priority, labels, and links to where it came from.'),
      CodexBlock.bullet('Long-press — jumps straight into the editor.'),
      CodexBlock.bullet(
          'Swipe left — archives the task (recoverable, with an Undo).'),
      CodexBlock.heading('The detail card'),
      CodexBlock.p(
          'The card links back to the task\'s list, and — if the task was '
          'born from a note line — to the note itself. Tap either to jump '
          'there.'),
    ],
  ),
  CodexTopic(
    id: 'task-time-blocks',
    title: 'Time blocking',
    category: CodexCategory.tasks,
    summary: 'Give a task a length and see it as a block on the day grid.',
    keywords: ['duration', 'schedule', 'calendar', 'grid'],
    body: [
      CodexBlock.p(
          'Once a task has a due time, an "End time" row appears in the '
          'editor. Set it and the task becomes a block with a real length — '
          'shown as "14:00–15:30 · 1h 30m".'),
      CodexBlock.p(
          'On the Planner, switch the day panel to Grid to see those blocks '
          'laid out over 24 hours, coloured by priority, with your shift '
          'hours shaded and a red line at the current time.'),
      CodexBlock.tip(
          'Long-press an empty hour on the grid to create a task already set '
          'to that time.'),
    ],
  ),
  CodexTopic(
    id: 'lists-labels',
    title: 'Lists, sections and labels',
    category: CodexCategory.tasks,
    summary: 'Two ways to organise: where it lives, and what it is about.',
    body: [
      CodexBlock.p(
          'A list is a container (Work, Home, Study). Inside a list you can '
          'add sections to group tasks further. A task lives in exactly one '
          'list and one section.'),
      CodexBlock.p(
          'Labels cut across lists — tag anything "urgent" or "call" and pull '
          'it up regardless of where it is filed. A task can carry several.'),
      CodexBlock.p(
          'Open a list and use its ⋮ menu to rename it, recolour it, or '
          'archive it.'),
    ],
  ),
  CodexTopic(
    id: 'list-auto-archive',
    title: 'Auto-archive finished tasks per list',
    category: CodexCategory.tasks,
    hidden: true,
    summary: 'Make a list tidy itself the moment you tick something off.',
    keywords: ['clean', 'hide completed', 'tidy'],
    body: [
      CodexBlock.p(
          'Some lists should keep their completed tasks visible; others '
          'should clear themselves. This is per list.'),
      CodexBlock.step('Open the list.'),
      CodexBlock.step('Tap ⋮ in the top corner.'),
      CodexBlock.step('Tick "Auto-archive done tasks".'),
      CodexBlock.p(
          'From then on, completing a task in that list archives it straight '
          'away. It is not deleted — the Archived screen still has it.'),
    ],
  ),
  CodexTopic(
    id: 'reminders',
    title: 'Task reminders',
    category: CodexCategory.tasks,
    summary: 'Get nudged a day, a few hours, or minutes before.',
    keywords: ['notification', 'alarm', 'alert'],
    body: [
      CodexBlock.p(
          'Turn on reminders in the task editor and choose how far ahead you '
          'want warning — 1 day, 3 hours and 5 minutes before are all '
          'available, and you can pick more than one.'),
      CodexBlock.p(
          'Reminders need a due date (and are most useful with a due time).'),
      CodexBlock.tip(
          'If reminders ever stop arriving, open Settings → Testing & '
          'support → Diagnostics. It checks notification permission, exact '
          'alarms and battery settings, and each failing row has a Fix '
          'button. Samsung and OnePlus battery savers are the usual culprit.'),
    ],
  ),
  CodexTopic(
    id: 'archive',
    title: 'Archive and restore',
    category: CodexCategory.tasks,
    summary: 'Nothing is really gone until you say so.',
    keywords: ['delete', 'undo', 'trash', 'recover'],
    body: [
      CodexBlock.p(
          'Archiving hides something without deleting it — swipe a task, or '
          'use a list\'s ⋮ menu.'),
      CodexBlock.step('Open the drawer → Archived.'),
      CodexBlock.step(
          'Find the item under its section (tasks, lists, habits, trackers).'),
      CodexBlock.step('Restore it, or Delete forever if you are sure.'),
    ],
  ),

  // ── Planner ─────────────────────────────────────────────────────────────
  CodexTopic(
    id: 'planner',
    title: 'The Planner',
    category: CodexCategory.planner,
    summary: 'A month at a glance, and one day in detail.',
    keywords: ['calendar', 'month', 'day', 'agenda'],
    body: [
      CodexBlock.p(
          'The Planner shows a month calendar with your shifts coloured in. '
          'Tap a day to open its panel underneath.'),
      CodexBlock.heading('Two ways to see a day'),
      CodexBlock.bullet(
          'List — tasks split into Scheduled (in time order) and Anytime.'),
      CodexBlock.bullet(
          'Grid — a 24-hour timeline with your time-blocked tasks drawn to '
          'scale, shift hours shaded, and a red line at the current time.'),
      CodexBlock.p(
          'The ⋮ menu on the day panel hides completed tasks and filters by '
          'list or label. Your choice of List or Grid is remembered as the '
          'default; filters last for the visit.'),
      CodexBlock.tip(
          'Long-press an empty hour in Grid view to create a task already set '
          'to that time.'),
    ],
  ),

  CodexTopic(
    id: 'calendar-long-press',
    title: 'Long-press any day to add a task to it',
    category: CodexCategory.planner,
    hidden: true,
    summary: 'Works on every calendar in the app.',
    keywords: ['shortcut', 'quick add', 'hold', 'long press', 'date'],
    body: [
      CodexBlock.p(
          'Anywhere Uplan shows days, holding one opens the task editor with '
          'that date already filled in — no date picker needed.'),
      CodexBlock.bullet('The Planner\'s month grid and its week strip.'),
      CodexBlock.bullet('The month calendar on the Work schedule screen.'),
      CodexBlock.p(
          'A normal tap still does the usual thing (select the day, or set '
          'the shift) — only the hold adds a task.'),
      CodexBlock.tip(
          'In the Planner\'s Grid view, holding an empty HOUR fills in the '
          'time as well as the date.'),
    ],
  ),

  // ── Habits & trackers ───────────────────────────────────────────────────
  CodexTopic(
    id: 'habits',
    title: 'Habits and streaks',
    category: CodexCategory.daily,
    summary: 'Things you want to do every day, with a streak counter.',
    keywords: ['streak', 'daily', 'routine'],
    body: [
      CodexBlock.p(
          'Drawer → Habits. Give a habit a name, an emoji and a colour, and '
          'tick it off each day. Uplan counts your streak automatically.'),
      CodexBlock.p(
          'Habits appear on the Today screen and can be added to Home as a '
          'block, so you can tick them from wherever you start your day.'),
      CodexBlock.p('Each habit can carry its own daily reminder time.'),
      CodexBlock.heading('Tile gestures'),
      CodexBlock.bullet('Tap — tick it off for today.'),
      CodexBlock.bullet('Long-press — open it for editing.'),
      CodexBlock.bullet('Swipe left — delete the habit.'),
    ],
  ),
  CodexTopic(
    id: 'trackers',
    title: 'Trackers (and medications)',
    category: CodexCategory.daily,
    summary: 'Custom checklists and session logs you design yourself.',
    keywords: ['medication', 'meds', 'checklist', 'log', 'custom'],
    body: [
      CodexBlock.p(
          'Drawer → Trackers. A tracker is a small thing you built yourself, '
          'in one of two shapes:'),
      CodexBlock.bullet(
          'Daily checklist — a set of items you tick each day.'),
      CodexBlock.bullet(
          'Session log — an entry you record whenever something happens.'),
      CodexBlock.p(
          'Daily checklists show inline on the Today screen, so you can tick '
          'items without opening the tracker.'),
      CodexBlock.p(
          'Swipe a tracker card left to delete it — it asks first.'),
      CodexBlock.tip(
          'There is no separate medications feature — a daily checklist IS '
          'the medication tracker. Make one called "Meds" with an item per '
          'tablet and tick them off each day.'),
    ],
  ),

  // ── Notes ───────────────────────────────────────────────────────────────
  CodexTopic(
    id: 'notes-basics',
    title: 'Notebooks and notes',
    category: CodexCategory.notes,
    summary: 'Notebooks hold notes; notes are a stack of lines.',
    body: [
      CodexBlock.p(
          'Drawer → Notes. Notebooks group your notes (a site, a rotation, a '
          'project); notes that belong nowhere sit under Unfiled.'),
      CodexBlock.p(
          'Inside a notebook, notes appear as photo cards — the first photo '
          'becomes the cover, with a snippet of text under it — newest edited '
          'first.'),
      CodexBlock.p(
          'A note is a stack of lines. Each line is its own thing: text, a '
          'checkbox, a photo, or a divider.'),
    ],
  ),
  CodexTopic(
    id: 'notes-writing',
    title: 'Writing: Enter, backspace and the toolbar',
    category: CodexCategory.notes,
    hidden: true,
    summary: 'It behaves like a document, not a form.',
    keywords: ['new line', 'delete line', 'typing'],
    body: [
      CodexBlock.bullet(
          'Press Enter to start a new line of the same kind; anything after '
          'the cursor moves down with it.'),
      CodexBlock.bullet(
          'Press backspace on an empty line to delete that line.'),
      CodexBlock.bullet(
          'The toolbar sits on top of the keyboard. New lines are inserted '
          'right after the line you are on — not at the bottom of the note.'),
      CodexBlock.p(
          'Everything saves by itself. Empty lines are cleaned up when you '
          'leave, and a note you never wrote in is discarded.'),
    ],
  ),
  CodexTopic(
    id: 'notes-format',
    title: 'Headings, bold, highlight and dividers',
    category: CodexCategory.notes,
    summary: 'Formatting applies to the whole line you are on.',
    keywords: ['h1', 'h2', 'italic', 'colour', 'style'],
    body: [
      CodexBlock.p(
          'Put the cursor in a line and the format row appears above the '
          'toolbar: heading level (Body → H1 → H2 → H3), bold, italic and '
          'highlight.'),
      CodexBlock.p(
          'Formatting is per line — there is no need to select text. The '
          'divider button drops a horizontal rule to separate areas.'),
      CodexBlock.tip(
          'Headings do more than look big: they define sections you can fold, '
          'and they carry their lines with them when you rearrange.'),
    ],
  ),
  CodexTopic(
    id: 'notes-photos',
    title: 'Photos in notes',
    category: CodexCategory.notes,
    summary: 'Camera or gallery, croppable, tap for full screen.',
    keywords: ['camera', 'image', 'crop', 'picture'],
    body: [
      CodexBlock.step('Tap the camera button in the note toolbar.'),
      CodexBlock.step('Take a photo or choose one from the gallery.'),
      CodexBlock.p(
          'Photos are inserted after the line you are on. They are capped to '
          'a sensible height so one picture never swallows the screen — tap '
          'to open it full size.'),
      CodexBlock.p(
          'Each photo has a crop button to trim it, and an ✕ to remove it.'),
      CodexBlock.p(
          'Opened full screen, a photo can be pinched to zoom in (up to 5×) '
          'and dragged around — useful for reading a vent screen.'),
      CodexBlock.tip(
          'Photos live in the app\'s own storage, not your gallery — and they '
          'are NOT inside the JSON backup file. Keep that in mind before '
          'wiping the app.'),
    ],
  ),
  CodexTopic(
    id: 'notes-time-tasks',
    title: 'Turn a note line into a task with a time',
    category: CodexCategory.notes,
    hidden: true,
    summary: 'Start a checkbox line with @1450pm and a linked task appears.',
    keywords: [
      'auto time placing',
      'auto task',
      'at time',
      'rounds',
      'linked task'
    ],
    body: [
      CodexBlock.p(
          'While writing rounds, you often note something that must happen at '
          'a time. Write it as a checkbox line beginning with a time and '
          'Uplan creates a real task for it — automatically.'),
      CodexBlock.heading('How'),
      CodexBlock.step('Add a checkbox line (☑ in the toolbar).'),
      CodexBlock.step('Start it with a time, then what to do.'),
      CodexBlock.step(
          'Example: "@1450pm take bloods" or "at 12:50pm july 12 review CT".'),
      CodexBlock.p(
          'The task is filed into a list named after the note, so everything '
          'from one round stays together.'),
      CodexBlock.heading('They stay in step'),
      CodexBlock.bullet(
          'Tick the note line → the task completes. Tick the task → the note '
          'line ticks.'),
      CodexBlock.bullet(
          'Delete the task → the note line goes too (it will not come back).'),
      CodexBlock.bullet(
          'Archive the task → the line stays, but the time token is removed, '
          'so it does not respawn.'),
      CodexBlock.tip(
          'Only checkbox lines do this. Plain text lines never turn into '
          'tasks, so your prose is safe.'),
    ],
  ),
  CodexTopic(
    id: 'notes-fold',
    title: 'Folding long notes',
    category: CodexCategory.notes,
    summary: 'Collapse a heading to hide everything under it.',
    keywords: ['collapse', 'hide', 'sections', 'long'],
    body: [
      CodexBlock.p(
          'Every heading has a ▾ caret on its left. Tap it and the whole '
          'section folds away, showing how many lines are hidden.'),
      CodexBlock.p(
          'Folding a top-level heading also folds the smaller headings inside '
          'it. Your folds are remembered — reopen the note tomorrow and it '
          'looks the way you left it.'),
      CodexBlock.tip(
          'The note\'s ⋮ menu has Collapse all / Expand all — the fastest way '
          'to get an overview of a six-bed round.'),
    ],
  ),
  CodexTopic(
    id: 'notes-arrange',
    title: 'Rearranging a note',
    category: CodexCategory.notes,
    hidden: true,
    summary: 'Hold to drag; hold over a heading to move something inside it.',
    keywords: ['reorder', 'move', 'drag', 'nest', 'indent'],
    body: [
      CodexBlock.p(
          'Tap the ⇅ button next to ⋮ to enter arrange mode. The note still '
          'looks like itself — each line just gains a ⊖ to delete it.'),
      CodexBlock.heading('Moving things'),
      CodexBlock.bullet('Hold any line to lift it, then drag.'),
      CodexBlock.bullet(
          'Hold a heading and its whole section folds into your hand and '
          'travels with it.'),
      CodexBlock.bullet(
          'Drop into any gap and the line moves OUT to the top level — '
          'including dragging it DOWN past the last line of its section. A '
          'stray drop never splits a section apart.'),
      CodexBlock.bullet(
          'To put a line INSIDE a section, hold it over that heading for '
          'about half a second — the section opens and highlights, then drop '
          'it where you want. That is also how you add a line to the END of a '
          'section, since dropping there on its own moves the line out.'),
      CodexBlock.p(
          'A blue line previews where it will land, and its indent shows you '
          'whether you are landing inside or outside.'),
    ],
  ),
  CodexTopic(
    id: 'notes-templates',
    title: 'Note templates',
    category: CodexCategory.notes,
    summary: 'Build a note once, reuse its shape forever.',
    keywords: ['reuse', 'preset', 'boilerplate', 'icu', 'beds'],
    body: [
      CodexBlock.p(
          'If your notes follow a shape — a heading per bed, the same '
          'checkboxes each time — save that shape once.'),
      CodexBlock.step('Build the note the way you want it.'),
      CodexBlock.step('Tap ⋮ → Save as template.'),
      CodexBlock.p(
          'From then on, the ✚ button in a notebook offers Blank or one of '
          'your templates. You can also drop a template into the middle of an '
          'existing note with ⋮ → Insert template.'),
      CodexBlock.p(
          'Templates live under Notes → Templates, where you can edit or '
          'delete them. Copies are independent — photos are duplicated, so '
          'editing a note never changes the template.'),
    ],
  ),
  CodexTopic(
    id: 'notes-rtl',
    title: 'Arabic and English in the same note',
    category: CodexCategory.notes,
    hidden: true,
    summary: 'Each line indents from its own side.',
    keywords: ['arabic', 'rtl', 'language', 'direction'],
    body: [
      CodexBlock.p(
          'Uplan reads the first word of each line to decide its direction. '
          'Arabic lines read and indent from the right; English lines from '
          'the left.'),
      CodexBlock.p(
          'That means a mixed note looks deliberate rather than randomly '
          'shifted — nesting is still obvious in both languages.'),
    ],
  ),

  // ── Home dashboard ──────────────────────────────────────────────────────
  CodexTopic(
    id: 'home-blocks',
    title: 'Building your Home screen',
    category: CodexCategory.home,
    summary: 'Home is a stack of blocks you choose and order.',
    keywords: ['dashboard', 'widgets', 'customise'],
    body: [
      CodexBlock.p(
          'Everything on Home is a block. Tap the ✎ in the top corner to add, '
          'remove and reorder them.'),
      CodexBlock.p('Blocks you can add:'),
      CodexBlock.bullet('Urgent · Due today · Captured · This week — tasks.'),
      CodexBlock.bullet('Done — what you have completed (un-tick mistakes).'),
      CodexBlock.bullet('List — one chosen list. Label — one chosen tag.'),
      CodexBlock.bullet('Habits — today\'s check-offs. Shift — today + next.'),
      CodexBlock.bullet('Workout — your suggested session. Notes — notebooks.'),
      CodexBlock.bullet('Pinned note — a whole note, editable, on Home.'),
      CodexBlock.tip(
          'You can drag a block straight on Home: long-press its header and '
          'move it. Tap the chevron on any header to fold that block away.'),
    ],
  ),
  CodexTopic(
    id: 'home-options',
    title: 'Per-block options',
    category: CodexCategory.home,
    hidden: true,
    summary: 'Cap how many items show, or hide a block when it is empty.',
    keywords: ['limit', 'settings', 'tune', 'hide'],
    body: [
      CodexBlock.step('Home → ✎ (Edit Home).'),
      CodexBlock.step('Tap the ⚙ on a block row.'),
      CodexBlock.bullet(
          'Items shown — cap a block at 3, 5 or 10. The rest appear as '
          '"+N more", and they still show up in your later blocks.'),
      CodexBlock.bullet('Days ahead — how far "This week" looks.'),
      CodexBlock.bullet(
          'Hide when empty — the block disappears until it has something.'),
      CodexBlock.p(
          'Edit Home also has drag handles for reordering, if you would '
          'rather not long-press on Home itself.'),
    ],
  ),
  CodexTopic(
    id: 'home-pinned-note',
    title: 'A note that lives on Home',
    category: CodexCategory.home,
    summary: 'Write in a note without opening it.',
    keywords: ['pin', 'handover', 'scratchpad'],
    body: [
      CodexBlock.p(
          'The Pinned note block is not a shortcut — it is the note itself. '
          'Type in any line, press Enter for a new one, tick checkboxes, fold '
          'headings. It saves as you go, exactly like the full editor.'),
      CodexBlock.p(
          'The ✚ buttons at the foot add a line or a checkbox; the ⤢ button '
          'opens the full editor, where formatting, photos and rearranging '
          'live. A long note scrolls inside its card.'),
      CodexBlock.tip(
          'Pin as many notes as you like — one block each. Perfect for a '
          'handover note you touch all shift.'),
    ],
  ),
  CodexTopic(
    id: 'home-wide',
    title: 'Tablets and unfolded phones',
    category: CodexCategory.home,
    hidden: true,
    summary: 'Home spreads into columns on a big screen.',
    keywords: ['tablet', 'foldable', 'columns', 'landscape'],
    body: [
      CodexBlock.p(
          'On a wide screen — a tablet, or a foldable opened up — Home lays '
          'its blocks into two or three columns instead of one long strip. '
          'Your order is preserved, so the blocks you care about stay at the '
          'top of each column.'),
      CodexBlock.p(
          'Reordering on a wide screen is done from ✎ Edit Home.'),
    ],
  ),

  // ── Workout ─────────────────────────────────────────────────────────────
  CodexTopic(
    id: 'workout-programs',
    title: 'Programs and training days',
    category: CodexCategory.workout,
    summary: 'A program is a set of days; each day is a list of exercises.',
    keywords: ['split', 'routine', 'ppl'],
    body: [
      CodexBlock.p(
          'Drawer → Workout. A program holds training days (Push, Pull, '
          'Legs…), and each day holds exercises with target sets, reps and '
          'rest.'),
      CodexBlock.p('Two ways days get scheduled:'),
      CodexBlock.bullet(
          'Rotating — you cycle through the days in order, whenever you '
          'train.'),
      CodexBlock.bullet(
          'Weekly — each day is pinned to weekdays (e.g. Upper on Mon+Thu).'),
      CodexBlock.p(
          'Start from a built-in template (Push/Pull/Legs, Upper/Lower) or '
          'build one from scratch — either way, everything stays editable.'),
    ],
  ),
  CodexTopic(
    id: 'workout-my-workouts',
    title: 'My workouts — your own one-tap sessions',
    category: CodexCategory.workout,
    summary: 'Build a workout once, then start it any day with one tap.',
    keywords: ['template', 'reuse', 'custom', 'preset', 'routine', 'quick'],
    body: [
      CodexBlock.p(
          'For workouts you repeat but that do not belong to a program — a '
          'favourite chest day, a quick home session — build them once under '
          'My Workouts on the Workout screen.'),
      CodexBlock.step('Workout → My Workouts → New.'),
      CodexBlock.step('Name it (e.g. "Chest & arms").'),
      CodexBlock.step(
          'Add exercises with target sets, reps and rest — the same editor '
          'programs use.'),
      CodexBlock.p(
          'From then on: tap it to start training it immediately, with all '
          'the usual previous-set hints and the rest timer. Tap ✎ to change '
          'it any time; hold it to delete it. Deleting never touches the '
          'sessions you already logged.'),
      CodexBlock.tip(
          'Whole programs can be kept too: open a program → ⋮ → "Save as my '
          'template", and reuse it later from Create Program → My templates.'),
    ],
  ),
  CodexTopic(
    id: 'workout-session',
    title: 'Running a workout',
    category: CodexCategory.workout,
    hidden: true,
    summary: 'Previous-set hints, history, and one-tap copying.',
    keywords: ['sets', 'reps', 'logging', 'previous', 'pr'],
    body: [
      CodexBlock.p(
          'Start a session and each exercise opens as a card with its set '
          'rows. Every row shows what you did last time in the same slot.'),
      CodexBlock.bullet(
          'Tap the "previous" hint to copy last session\'s weight and reps '
          'into the row.'),
      CodexBlock.bullet(
          'Use the ⋮ on an exercise to see its full history, or your best '
          'sets ever.'),
      CodexBlock.bullet(
          'Tick a set to mark it done — the whole row turns green.'),
      CodexBlock.bullet(
          'Long-press a set row to delete that set.'),
      CodexBlock.bullet(
          'In a program day or one of your own workouts, drag the handle on '
          'the right of an exercise to reorder it.'),
      CodexBlock.p(
          'Collapse an exercise to work through another one in between; your '
          'ticks survive. Finishing shows a summary: duration, total volume, '
          'personal records and top sets.'),
    ],
  ),
  CodexTopic(
    id: 'workout-weight',
    title: 'Typing weights (and the decimal comma)',
    category: CodexCategory.workout,
    hidden: true,
    summary: 'The ± buttons follow real plate jumps; commas work as dots.',
    keywords: ['decimal', 'kg', 'plates', 'stepper', 'float'],
    body: [
      CodexBlock.p(
          'The + and − buttons beside a weight do not just add 2.5 — they '
          'snap to the next sensible plate jump, so you land on numbers you '
          'can actually load.'),
      CodexBlock.tip(
          'If your keyboard has no "." key, type a comma (or the Arabic '
          'decimal mark) instead — Uplan accepts all three. That is the fix '
          'if you have ever been unable to enter 62.5.'),
    ],
  ),
  CodexTopic(
    id: 'workout-rest',
    title: 'The rest timer',
    category: CodexCategory.workout,
    summary: 'A bar under the app bar, and a live countdown outside the app.',
    keywords: ['timer', 'countdown', 'rest'],
    body: [
      CodexBlock.p(
          'Finishing a set starts the rest timer. It shows as a bar pinned '
          'under the app bar with −15s, +15s, restart and skip.'),
      CodexBlock.p(
          'The timer also posts a live notification, so you can leave the app '
          'and still see the countdown — with +15s and Skip buttons that keep '
          'the in-app bar in step. When it hits zero, the phone buzzes.'),
      CodexBlock.tip('Tapping that notification jumps back into the workout.'),
    ],
  ),
  CodexTopic(
    id: 'workout-targets',
    title: 'Weekly muscle targets (Labs)',
    category: CodexCategory.workout,
    hidden: true,
    summary: 'An experimental scoreboard of sets per muscle per week.',
    keywords: ['labs', 'volume', 'experimental', 'muscles'],
    body: [
      CodexBlock.p(
          'Settings → Labs has an experimental alternative to programs: '
          'weekly targets. Instead of following a split, you set how many '
          'sets each muscle should get per week and Uplan keeps score from '
          'the sets you actually log.'),
      CodexBlock.p(
          'It reads your shift rota to know how many free days you have, and '
          'adjusts targets on a short week. Quick-start sessions (Push, Pull, '
          'Upper, Full) let you train without a program at all.'),
      CodexBlock.p(
          'It is off by default — the normal Program mode is what you get '
          'until you switch it on.'),
    ],
  ),

  // ── Work shifts ─────────────────────────────────────────────────────────
  CodexTopic(
    id: 'shifts',
    title: 'Your shift calendar',
    category: CodexCategory.shifts,
    summary: 'Mark day/night shifts and label them with your own codes.',
    keywords: ['rota', 'roster', 'schedule', 'icu', 'night'],
    body: [
      CodexBlock.p(
          'Drawer → Work schedule shows a month grid. Tap a day to set it as '
          'a day shift, a night shift, or off — day shifts show a sun in '
          'cyan, nights a moon in navy.'),
      CodexBlock.heading('Your own placement codes'),
      CodexBlock.p(
          'When you tap a day you can also give it a rotation label — ICU1, '
          'ER, Ward, whatever you use. The label shows in the corner of the '
          'tile in every calendar.'),
      CodexBlock.p(
          'Manage the codes themselves (add, rename, recolour) from the '
          'rotation editor on that screen.'),
      CodexBlock.tip(
          'Shifts are not just decoration: the planner shades your working '
          'hours, and weekly workout targets scale to the days you are off.'),
    ],
  ),

  // ── Reminders & glances ─────────────────────────────────────────────────
  CodexTopic(
    id: 'live-notification',
    title: 'The always-on dashboard notification',
    category: CodexCategory.reminders,
    hidden: true,
    summary: 'Tick tasks off without opening the app.',
    keywords: ['live', 'ongoing', 'shade', 'snooze', 'lock screen'],
    body: [
      CodexBlock.p(
          'Settings → Live notification turns on a permanent notification '
          'that cycles through what needs doing: overdue first, then due '
          'today, then habits, then captured items.'),
      CodexBlock.bullet('◀ ▶ page through the cards.'),
      CodexBlock.bullet(
          '✓ completes the item — it works with the app fully closed.'),
      CodexBlock.bullet('Snooze hides it for now.'),
      CodexBlock.p(
          'You choose what Snooze means in that settings screen: hide for an '
          'hour, or push the due date to tomorrow.'),
      CodexBlock.tip(
          'If the notification vanishes overnight, set Uplan to '
          '"Unrestricted" battery and add it to your phone\'s never-sleeping '
          'apps. Diagnostics will tell you if this is the problem.'),
    ],
  ),
  CodexTopic(
    id: 'home-widget',
    title: 'The home-screen widget',
    category: CodexCategory.reminders,
    summary: 'A month calendar and your task list, on your launcher.',
    keywords: ['widget', 'launcher', 'shortcut', 'quick add'],
    body: [
      CodexBlock.p(
          'Long-press your phone\'s home screen → Widgets → Uplan. The widget '
          'shows a month calendar with your shifts (sun/moon and rotation '
          'labels) above a scrollable task list.'),
      CodexBlock.bullet('‹ › move between months.'),
      CodexBlock.bullet(
          'Tap a day on the widget to open Uplan on that date.'),
      CodexBlock.bullet('The ✚ opens a quick-add sheet without leaving home.'),
      CodexBlock.bullet('Resize it taller to see more tasks.'),
      CodexBlock.p(
          'Settings → Widget appearance changes its background colour and '
          'transparency.'),
    ],
  ),

  // ── Data & support ──────────────────────────────────────────────────────
  CodexTopic(
    id: 'backup',
    title: 'Backing up and restoring',
    category: CodexCategory.data,
    summary: 'Export everything to a file you keep.',
    keywords: ['export', 'import', 'transfer', 'new phone', 'json'],
    body: [
      CodexBlock.step('Settings → Data → Export.'),
      CodexBlock.step(
          'Share the file somewhere safe (Drive, email, your PC).'),
      CodexBlock.p(
          'To restore, use Data → Import and pick that file. Importing '
          'replaces what is in the app, so restore onto a fresh install or '
          'when you genuinely want to roll back.'),
      CodexBlock.p(
          'The file carries your tasks, lists, labels, notes, notebooks, '
          'habits, trackers, workouts, programs, shifts and your Home layout.'),
      CodexBlock.tip(
          'Photos in notes are NOT in the file — only the text and the '
          'filenames. Restoring on a new phone shows "Image unavailable" for '
          'them.'),
    ],
  ),
  CodexTopic(
    id: 'diagnostics',
    title: 'When something is not working',
    category: CodexCategory.data,
    summary: 'A self-check screen, and how to report a problem.',
    keywords: ['broken', 'help', 'bug', 'crash', 'battery'],
    body: [
      CodexBlock.p(
          'Settings → Testing & support → Diagnostics runs a checklist: '
          'notifications, exact alarms, battery exemption and live updates. '
          'Anything failing gets a Fix button that opens the right system '
          'screen.'),
      CodexBlock.p(
          '"Share diagnostics" bundles that report with recent errors so you '
          'can send it on.'),
      CodexBlock.p(
          'The same screen has test buttons for an instant notification and a '
          'scheduled one — the fastest way to prove reminders work.'),
    ],
  ),
  CodexTopic(
    id: 'updates',
    title: 'Updating Uplan',
    category: CodexCategory.data,
    summary: 'Uplan checks for new versions by itself.',
    keywords: ['version', 'upgrade', 'new'],
    body: [
      CodexBlock.p(
          'Uplan checks once a day for a newer release and offers it. You can '
          'also check on demand from Settings → Testing & support → Check for '
          'updates.'),
      CodexBlock.p(
          'Updates download in your browser and install over the top — your '
          'data is kept.'),
    ],
  ),
  CodexTopic(
    id: 'developer-mode',
    title: 'Developer mode',
    category: CodexCategory.data,
    hidden: true,
    summary: 'Seven taps on the version number unlock extra tools.',
    keywords: ['secret', 'hidden', 'github', 'feedback', 'debug'],
    body: [
      CodexBlock.p(
          'Open the drawer and tap the About / version row seven times '
          'quickly. Developer mode switches on.'),
      CodexBlock.p(
          'It reveals GitHub feedback sync — a list ⋮ action that pushes that '
          'list to a repository as a Markdown file, so bugs and ideas you '
          'collect in Uplan can be read straight from the repo.'),
      CodexBlock.p(
          'It stays hidden and inert unless you turn it on, so nothing '
          'changes for anyone you share the app with.'),
    ],
  ),
];
