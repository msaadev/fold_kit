import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Builds with the widget's own size and its position in the window, so a
/// fold given in window coordinates can be mapped onto it. The position is
/// measured after layout; a change costs one extra frame.
class FoldTracker extends StatefulWidget {
  /// Builds the content from the window [origin] and [size] of this widget.
  final Widget Function(BuildContext context, Offset origin, Size size) builder;

  /// Creates a tracker.
  const FoldTracker({super.key, required this.builder});

  @override
  State<FoldTracker> createState() => _FoldTrackerState();
}

class _FoldTrackerState extends State<FoldTracker> {
  Offset _origin = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
        return widget.builder(context, _origin, constraints.biggest);
      },
    );
  }

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = context
        .getInheritedWidgetOfExactType<FoldWindowAnchor>()
        ?.windowKey
        .currentContext
        ?.findRenderObject();
    final origin = box.localToGlobal(Offset.zero, ancestor: anchor);
    if (origin != _origin) setState(() => _origin = origin);
  }
}

/// Marks the box that plays the role of the window (used by `FoldPreview`),
/// so fold rects are mapped in its coordinates instead of the screen's.
class FoldWindowAnchor extends InheritedWidget {
  /// Key of the window box.
  final GlobalKey windowKey;

  /// Creates the anchor.
  const FoldWindowAnchor({
    super.key,
    required this.windowKey,
    required super.child,
  });

  @override
  bool updateShouldNotify(FoldWindowAnchor old) => old.windowKey != windowKey;
}
