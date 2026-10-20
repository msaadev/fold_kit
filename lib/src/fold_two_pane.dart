import 'package:flutter/widgets.dart';

import 'fold_info.dart';
import 'fold_tracker.dart';

/// Two panes that split exactly at the fold, on any device.
///
/// - Vertical fold (book posture): [start] left of the fold, [end] right of it.
/// - Horizontal fold (tabletop): [start] above, [end] below.
/// - No fold, wide window: split by [ratio] with a [divider].
/// - Narrow window: only [compact] (defaults to [start]).
///
/// Both panes keep their state when the layout changes.
class FoldTwoPane extends StatefulWidget {
  /// The first pane (left, or top on a horizontal fold).
  final Widget start;

  /// The second pane (right, or bottom on a horizontal fold).
  final Widget end;

  /// Shown alone below [minSplitWidth]. Defaults to [start].
  final Widget? compact;

  /// Share of the width given to [start] when there is no fold.
  final double ratio;

  /// Narrower than this and without a fold, only one pane is shown.
  final double minSplitWidth;

  /// Drawn between the panes when there is no fold. Defaults to a hairline.
  final Widget? divider;

  /// Creates two panes.
  const FoldTwoPane({
    super.key,
    required this.start,
    required this.end,
    this.compact,
    this.ratio = 0.5,
    this.minSplitWidth = 600,
    this.divider,
  });

  @override
  State<FoldTwoPane> createState() => _FoldTwoPaneState();
}

class _FoldTwoPaneState extends State<FoldTwoPane> {
  final _startKey = GlobalKey();
  final _endKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    return FoldTracker(
      builder: (context, origin, size) {
        final start = KeyedSubtree(key: _startKey, child: widget.start);
        final end = KeyedSubtree(key: _endKey, child: widget.end);
        final local = fold.rect?.shift(-origin);
        final hit = local != null && local.overlaps(Offset.zero & size);
        if (hit && fold.axis == FoldAxis.vertical) {
          return Row(
            children: [
              SizedBox(width: local.left.clamp(0, size.width), child: start),
              SizedBox(width: local.width),
              Expanded(child: end),
            ],
          );
        }
        if (hit && fold.axis == FoldAxis.horizontal) {
          return Column(
            children: [
              SizedBox(height: local.top.clamp(0, size.height), child: start),
              SizedBox(height: local.height),
              Expanded(child: end),
            ],
          );
        }
        if (size.width < widget.minSplitWidth) {
          return widget.compact ?? start;
        }
        return Row(
          children: [
            SizedBox(width: size.width * widget.ratio, child: start),
            widget.divider ?? const _Hairline(),
            Expanded(child: end),
          ],
        );
      },
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    final color =
        DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return SizedBox(
      width: 1,
      child: ColoredBox(color: color.withValues(alpha: 0.12)),
    );
  }
}
