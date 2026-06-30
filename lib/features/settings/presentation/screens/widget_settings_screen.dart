import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// Lets the user style the home-screen calendar widget: background colour and
/// transparency. Values are saved into the same store the native widget reads
/// (HomeWidgetPreferences), then the widget is asked to refresh.
class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  /// Native provider class — must match UplanMonthWidgetProvider.
  static const String _monthProvider =
      'com.lifetracker.life_tracker.UplanMonthWidgetProvider';

  static const int _defaultBg = 0xFF202024;

  /// Background colour presets (opaque ARGB).
  static const List<int> _bgPresets = [
    0xFF202024, // charcoal
    0xFF000000, // black
    0xFF1E2233, // navy
    0xFF0E3A42, // teal
    0xFF2A1E33, // plum
    0xFF2C3440, // slate
    0xFF3A2A22, // espresso
    0xFFFFFFFF, // light
  ];

  int _bgColor = _defaultBg;
  double _opacity = 1.0; // 0.2 – 1.0

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final int? color =
        await HomeWidget.getWidgetData<int>('widget_bg_color');
    final int? alpha =
        await HomeWidget.getWidgetData<int>('widget_bg_alpha');
    setState(() {
      _bgColor = 0xFF000000 | ((color ?? _defaultBg) & 0xFFFFFF);
      _opacity = ((alpha ?? 255) / 255).clamp(0.2, 1.0);
    });
  }

  Future<void> _apply() async {
    await HomeWidget.saveWidgetData<int>('widget_bg_color', _bgColor);
    await HomeWidget.saveWidgetData<int>(
        'widget_bg_alpha', (_opacity * 255).round());
    await HomeWidget.updateWidget(qualifiedAndroidName: _monthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Widget appearance')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Live preview ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Color(_bgColor).withValues(alpha: _opacity),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Preview',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const _Header(label: 'Background colour'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final int c in _bgPresets)
                  GestureDetector(
                    onTap: () {
                      setState(() => _bgColor = c);
                      _apply();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _bgColor == c
                              ? cs.primary
                              : cs.onSurface.withAlpha(40),
                          width: _bgColor == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const _Header(label: 'Background opacity'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _opacity,
                    min: 0.2,
                    max: 1.0,
                    divisions: 16,
                    label: '${(_opacity * 100).round()}%',
                    onChanged: (v) => setState(() => _opacity = v),
                    onChangeEnd: (_) => _apply(),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(_opacity * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Lower opacity lets your wallpaper show through. Changes apply to '
              'the home-screen calendar widget immediately.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(140),
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
