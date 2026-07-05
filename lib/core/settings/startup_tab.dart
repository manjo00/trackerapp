import 'app_settings.dart';

/// Resolves the route the app should open on, from raw preference values.
///
/// Pure so it's unit-testable and callable from `main()` BEFORE the
/// provider scope exists (the router's initialLocation is needed at
/// construction time). Rules:
///  - the stored startup tab wins when it's a real tab AND visible;
///  - otherwise the first visible tab (branch/enum order);
///  - with nothing stored, the defaults apply (→ '/home').
String startupLocation({
  required String? storedTab,
  required List<String>? storedVisibleTabs,
}) {
  final Set<AppTab> visible = storedVisibleTabs == null
      ? AppSettings.defaults.visibleTabs
      : storedVisibleTabs
          .map((s) => AppTab.values.where((t) => t.name == s).firstOrNull)
          .whereType<AppTab>()
          .toSet();
  final Set<AppTab> effective =
      visible.isEmpty ? AppSettings.defaults.visibleTabs : visible;

  final AppTab? wanted =
      AppTab.values.where((t) => t.name == storedTab).firstOrNull;

  final AppTab target = (wanted != null && effective.contains(wanted))
      ? wanted
      : AppTab.values.firstWhere(effective.contains);

  return '/${target.name}';
}
