import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// How a foldable is folded.
enum FoldPosture {
  /// No fold in view: a normal phone, a tablet, or a foldable lying flat
  /// that does not report its fold.
  none,

  /// Folded shut, app on the outer display (iPhone Duo, from 0.1).
  closed,

  /// Partly open, like a book or a laptop ("tabletop").
  halfOpen,

  /// Fully open; the fold is reported but the screen is one flat surface.
  flat,
}

/// Direction of the fold line.
enum FoldAxis {
  /// The fold runs top to bottom (book style: Galaxy Z Fold, iPhone Duo).
  vertical,

  /// The fold runs left to right (tabletop, flip phones).
  horizontal,
}

/// Material 3 window size classes by width.
enum WindowSizeClass {
  /// Narrower than 600: phones, folded foldables.
  compact,

  /// 600 to 839: open foldables, small tablets, Split View.
  medium,

  /// 840 and wider: tablets, open foldables in landscape, desktop.
  expanded;

  /// The class for a window [width] in logical pixels.
  static WindowSizeClass fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    return expanded;
  }
}

/// Where the fold is and how the device is held, for the current window.
@immutable
class FoldInfo {
  /// The fold or hinge in logical pixels of the window, `null` without one.
  final Rect? rect;

  /// Direction of the fold, `null` without one.
  final FoldAxis? axis;

  /// How the device is folded.
  final FoldPosture posture;

  /// Size of the window.
  final Size windowSize;

  /// Creates fold information; most code uses [FoldInfo.of].
  const FoldInfo({
    required this.windowSize,
    this.rect,
    this.axis,
    this.posture = FoldPosture.none,
  });

  /// Fold information for the window [context] is in. Rebuilds the caller
  /// when the window size or the fold changes.
  static FoldInfo of(BuildContext context) => FoldInfo.fromFeatures(
    MediaQuery.sizeOf(context),
    MediaQuery.displayFeaturesOf(context),
  );

  /// Fold information from a window [size] and its display [features].
  factory FoldInfo.fromFeatures(Size size, List<DisplayFeature> features) {
    for (final feature in features) {
      if (feature.type == DisplayFeatureType.cutout) continue;
      final bounds = feature.bounds;
      return FoldInfo(
        windowSize: size,
        rect: bounds,
        axis: bounds.height >= bounds.width
            ? FoldAxis.vertical
            : FoldAxis.horizontal,
        posture: switch (feature.state) {
          DisplayFeatureState.postureHalfOpened => FoldPosture.halfOpen,
          _ => FoldPosture.flat,
        },
      );
    }
    return FoldInfo(windowSize: size);
  }

  /// Whether a fold or hinge is in view.
  bool get hasFold => rect != null;

  /// Whether the device is partly open (book or tabletop).
  bool get isHalfOpen => posture == FoldPosture.halfOpen;

  /// Window size class by width.
  WindowSizeClass get windowSizeClass =>
      WindowSizeClass.fromWidth(windowSize.width);

  @override
  bool operator ==(Object other) =>
      other is FoldInfo &&
      other.rect == rect &&
      other.axis == axis &&
      other.posture == posture &&
      other.windowSize == windowSize;

  @override
  int get hashCode => Object.hash(rect, axis, posture, windowSize);

  @override
  String toString() =>
      'FoldInfo($posture, $axis, $rect, ${windowSizeClass.name} $windowSize)';
}
