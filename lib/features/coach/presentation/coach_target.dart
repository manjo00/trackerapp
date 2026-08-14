import 'package:flutter/material.dart';

/// Live map of coach-mark target id → the widget currently rendering it.
///
/// A plain registry (not an InheritedWidget) so any screen can wrap a widget
/// without threading context down: [CoachTarget] adds itself on mount and
/// removes itself on dispose, so an id only resolves while it is on screen.
class CoachRegistry {
  CoachRegistry._();

  static final Map<String, GlobalKey> _keys = {};

  static void register(String id, GlobalKey key) => _keys[id] = key;

  static void unregister(String id, GlobalKey key) {
    // Guard against a rebuild registering the new key before the old one is
    // disposed — only drop the entry if it is still ours.
    if (_keys[id] == key) _keys.remove(id);
  }

  /// Where [id] currently sits on screen, or null when it is not mounted,
  /// not laid out, or off-screen.
  static Rect? rectOf(String id) {
    final BuildContext? ctx = _keys[id]?.currentContext;
    if (ctx == null) return null;
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) return null;
    final Offset topLeft = ro.localToGlobal(Offset.zero);
    return topLeft & ro.size;
  }
}

/// Marks a widget as spotlightable by a coach tip. Purely a wrapper — it
/// changes nothing about how the child looks or behaves.
class CoachTarget extends StatefulWidget {
  const CoachTarget({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<CoachTarget> createState() => _CoachTargetState();
}

class _CoachTargetState extends State<CoachTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    CoachRegistry.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(CoachTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      CoachRegistry.unregister(old.id, _key);
      CoachRegistry.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    CoachRegistry.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
