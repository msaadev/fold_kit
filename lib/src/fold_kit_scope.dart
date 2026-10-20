import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Hinge status reported by the platform (iPhone Duo; Android reports only the angle).
enum HingeStatus {
  /// Not reported (no hinge, or an older OS).
  unknown,

  /// Folded shut; the app is on the outer display.
  closed,

  /// Partly open, like a book or a laptop.
  partiallyOpen,

  /// Fully open and flat.
  fullyOpen,
}

/// Puts the fold of iPhone Duo into `MediaQuery.displayFeatures`, the same
/// place Flutter already reports Android folds, so `FoldInfo`, `TwoPane`,
/// dialogs and sheets work the same on both platforms.
///
/// Place it above `MaterialApp`:
///
/// ```dart
/// runApp(const FoldKitScope(child: MyApp()));
/// ```
///
/// On other platforms it passes its child through unchanged.
class FoldKitScope extends StatefulWidget {
  /// The app.
  final Widget child;

  /// Creates the scope.
  const FoldKitScope({super.key, required this.child});

  /// Channel the iOS plugin streams on.
  static const EventChannel channel = EventChannel('fold_kit/fold');

  /// The latest hinge status, or [HingeStatus.unknown] without a scope.
  static HingeStatus statusOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FoldScopeData>()?.status ??
      HingeStatus.unknown;

  /// The latest hinge angle in degrees (iPhone Duo, Android foldables with a
  /// hinge sensor), `null` when not reported. Use it for interaction, not layout.
  static double? angleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FoldScopeData>()?.angle;

  @override
  State<FoldKitScope> createState() => _FoldKitScopeState();
}

class _FoldKitScopeState extends State<FoldKitScope> {
  StreamSubscription<dynamic>? _subscription;
  HingeStatus _status = HingeStatus.unknown;
  double? _angle;
  List<Rect> _folds = const [];

  @override
  void initState() {
    super.initState();
    final native =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    if (!native || kIsWeb) return;
    _subscription = FoldKitScope.channel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final base = MediaQueryData.fromView(view);
    final features = base.displayFeatures.isNotEmpty || _folds.isEmpty
        ? base.displayFeatures
        : [
            for (final rect in _folds)
              DisplayFeature(
                bounds: rect,
                type: DisplayFeatureType.fold,
                state: DisplayFeatureState.postureHalfOpened,
              ),
          ];
    return FoldScopeData(
      status: _status,
      angle: _angle,
      child: MediaQuery(
        data: base.copyWith(displayFeatures: features),
        child: widget.child,
      ),
    );
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final folds = <Rect>[
      for (final f in (event['folds'] as List? ?? const []))
        if (f is Map)
          Rect.fromLTWH(
            (f['x'] as num).toDouble(),
            (f['y'] as num).toDouble(),
            (f['width'] as num).toDouble(),
            (f['height'] as num).toDouble(),
          ),
    ];
    final status = HingeStatus.values.firstWhere(
      (s) => s.name == event['status'],
      orElse: () => HingeStatus.unknown,
    );
    setState(() {
      _status = status;
      _angle = (event['angle'] as num?)?.toDouble();
      // Same rule as Flutter's Android behaviour: a fold splits layouts only while half open.
      _folds = status == HingeStatus.partiallyOpen ? folds : const [];
    });
  }
}

/// Hinge data for the subtree; used by `FoldKitScope` and `FoldPreview`.
class FoldScopeData extends InheritedWidget {
  /// Hinge status.
  final HingeStatus status;

  /// Hinge angle in degrees.
  final double? angle;

  /// Creates the data.
  const FoldScopeData({
    super.key,
    required this.status,
    required this.angle,
    required super.child,
  });

  @override
  bool updateShouldNotify(FoldScopeData old) =>
      old.status != status || old.angle != angle;
}
