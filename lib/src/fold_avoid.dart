import 'package:flutter/widgets.dart';

import 'fold_info.dart';
import 'fold_tracker.dart';

/// Keeps [child] off the fold: if it would sit on the hinge, it moves to the
/// closer side (plus [gap]). Use it for buttons, FABs, banners and map
/// controls that are positioned by hand.
class FoldAvoid extends StatelessWidget {
  /// The widget to keep off the fold.
  final Widget child;

  /// Extra space between the fold and the moved child.
  final double gap;

  /// Creates the wrapper.
  const FoldAvoid({super.key, required this.child, this.gap = 8});

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final rect = fold.rect;
    if (rect == null) return child;
    return FoldTracker(
      builder: (context, origin, size) {
        final own = origin & size;
        if (!own.overlaps(rect)) return child;
        final Offset shift;
        if (fold.axis == FoldAxis.vertical) {
          final toLeft = rect.left - own.right - gap;
          final toRight = rect.right - own.left + gap;
          shift = Offset(toLeft.abs() < toRight.abs() ? toLeft : toRight, 0);
        } else {
          final up = rect.top - own.bottom - gap;
          final down = rect.bottom - own.top + gap;
          shift = Offset(0, up.abs() < down.abs() ? up : down);
        }
        return Transform.translate(offset: shift, child: child);
      },
    );
  }
}
