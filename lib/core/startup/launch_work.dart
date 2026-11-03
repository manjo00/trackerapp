/// Whether an app start that opens on [location] should run the launch work:
/// re-book every reminder, purge Recently deleted, sync the home-screen
/// widgets and the live dashboard, What's new and the update check
/// (`_reschedule` in `app.dart`).
///
/// The home-screen widget's "+" opens straight on the quick-add sheet, in a
/// window of its own that closes again after one task. The launch work there
/// was wasted (1.4 s on a fast build, 2.5 s on a debug one, measured
/// 2026-11-01, of platform calls while the user types) and could put the
/// update dialog over the sheet. Quick-added tasks book their own reminders;
/// the next normal start does the rest.
bool wantsLaunchWork(String location) => location != '/quick-add';
