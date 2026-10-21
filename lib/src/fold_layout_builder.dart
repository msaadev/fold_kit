import 'package:flutter/widgets.dart';

import 'fold_info.dart';
import 'fold_tracker.dart';

/// Where the fold is inside one widget, in that widget's own coordinates.
@immutable
class LocalFold {
  /// The fold inside the widget, `null` when it doesn't cross the widget.
  final Rect? rect;

  /// Direction of the fold, `null` without one.
  final FoldAxis? axis;

  /// Size of the widget.
  final Size size;

  /// Creates a local fold.
  const LocalFold({required this.rect, required this.axis, required this.size});

  /// Whether the fold crosses this widget.
  bool get hasFold => rect != null;

  /// The part before the fold: left of a vertical fold, above a horizontal
  /// one; the whole widget without a fold.
  Rect get start {
    final fold = rect;
    if (fold == null) return Offset.zero & size;
    return axis == FoldAxis.vertical
        ? Rect.fromLTRB(0, 0, fold.left.clamp(0, size.width), size.height)
        : Rect.fromLTRB(0, 0, size.width, fold.top.clamp(0, size.height));
  }

  /// The part after the fold: right of a vertical fold, below a horizontal
  /// one; empty without a fold.
  Rect get end {
    final fold = rect;
    if (fold == null) return Rect.zero;
    return axis == FoldAxis.vertical
        ? Rect.fromLTRB(
            fold.right.clamp(0, size.width),
            0,
            size.width,
            size.height,
          )
        : Rect.fromLTRB(
            0,
            fold.bottom.clamp(0, size.height),
            size.width,
            size.height,
          );
  }
}

/// Builds with the fold mapped into this widget, for layouts that
/// [FoldTwoPane] doesn't cover: keep a canvas above a tabletop fold, put a
/// toolbar right after the hinge, size a list to the left half.
///
/// ```dart
/// FoldLayoutBuilder(
///   builder: (context, fold) => SizedBox(
///     height: fold.axis == FoldAxis.horizontal ? fold.start.height : null,
///     child: const Canvas(),
///   ),
/// )
/// ```
class FoldLayoutBuilder extends StatelessWidget {
  /// Builds from the fold inside this widget.
  final Widget Function(BuildContext context, LocalFold fold) builder;

  /// Creates the builder.
  const FoldLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    return FoldTracker(
      builder: (context, origin, size) {
        final local = fold.rect?.shift(-origin);
        final hit = local != null && local.overlaps(Offset.zero & size);
        return builder(
          context,
          LocalFold(
            rect: hit ? local : null,
            axis: hit ? fold.axis : null,
            size: size,
          ),
        );
      },
    );
  }
}
