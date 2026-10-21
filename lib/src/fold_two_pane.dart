import 'package:flutter/widgets.dart';

import 'fold_info.dart';
import 'fold_layout_builder.dart';
import 'fold_state.dart';

/// Two panes that split exactly at the fold, on any device.
///
/// - Vertical fold (book posture): [start] left of the fold, [end] right of it.
/// - Horizontal fold (tabletop): [start] above, [end] below.
/// - No fold, wide window: split by [ratio] with a [divider].
/// - Narrow window: only [compact] (defaults to [start]).
///
/// Split only when the device is partly open, like a book (the rest of the
/// time the page stays one piece):
///
/// ```dart
/// FoldTwoPane(
///   splitWhen: (fold) => fold.isHalfOpen,
///   splitWithoutFold: false,
///   compact: const NormalPage(),   // shown when not split
///   start: const Inputs(),
///   end: const Results(),
/// )
/// ```
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

  /// Fills the space of the fold itself (a hinge you can see, a shadow).
  /// Empty by default.
  final Widget? hinge;

  /// Whether to split at the fold for this state. Defaults to any fold in
  /// view; `(fold) => fold.isHalfOpen` splits only while partly open.
  final bool Function(FoldState fold)? splitWhen;

  /// Whether wide windows without a fold (tablets) also split by [ratio].
  final bool splitWithoutFold;

  /// Creates two panes.
  const FoldTwoPane({
    super.key,
    required this.start,
    required this.end,
    this.compact,
    this.ratio = 0.5,
    this.minSplitWidth = 600,
    this.divider,
    this.hinge,
    this.splitWhen,
    this.splitWithoutFold = true,
  });

  @override
  State<FoldTwoPane> createState() => _FoldTwoPaneState();
}

class _FoldTwoPaneState extends State<FoldTwoPane> {
  final _startKey = GlobalKey();
  final _endKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final split = widget.splitWhen?.call(FoldKit.of(context)) ?? true;
    return FoldLayoutBuilder(
      builder: (context, fold) {
        final start = KeyedSubtree(key: _startKey, child: widget.start);
        final end = KeyedSubtree(key: _endKey, child: widget.end);
        final rect = fold.rect;
        final hinge = widget.hinge ?? const SizedBox.shrink();
        if (split && rect != null && fold.axis == FoldAxis.vertical) {
          return Row(
            children: [
              SizedBox(width: fold.start.width, child: start),
              SizedBox(width: rect.width, child: hinge),
              Expanded(child: end),
            ],
          );
        }
        if (split && rect != null && fold.axis == FoldAxis.horizontal) {
          return Column(
            children: [
              SizedBox(height: fold.start.height, child: start),
              SizedBox(height: rect.height, child: hinge),
              Expanded(child: end),
            ],
          );
        }
        if (!widget.splitWithoutFold ||
            fold.size.width < widget.minSplitWidth) {
          return widget.compact ?? start;
        }
        return Row(
          children: [
            SizedBox(width: fold.size.width * widget.ratio, child: start),
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
