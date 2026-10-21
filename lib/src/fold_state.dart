import 'dart:async';

import 'package:flutter/widgets.dart';

import 'fold_device.dart';
import 'fold_info.dart';
import 'fold_kit_scope.dart';

/// Everything about the fold in one value: posture, hinge angle, which
/// device it is, and where the fold is. Read it with [FoldKit.of], rebuild
/// with [FoldBuilder], react with [FoldListener] or [FoldKit.changes].
@immutable
class FoldState {
  /// Fold position and window size class.
  final FoldInfo info;

  /// Hinge status reported by the platform.
  final HingeStatus hinge;

  /// Hinge angle in degrees, or `null` without a hinge sensor.
  final double? angle;

  /// Device model id from the platform (`iPhone19,4`, `SM-F966B`…).
  final String? model;

  /// Creates a state.
  const FoldState({
    required this.info,
    this.hinge = HingeStatus.unknown,
    this.angle,
    this.model,
  });

  /// The catalog entry for [model], or `null` for unknown devices.
  FoldDevice? get device => FoldDevices.byModel(model);

  /// How the device is folded. Android reports no fold on the outer display,
  /// so a hinge angle under 15° also counts as [FoldPosture.closed] there.
  FoldPosture get posture {
    final angle = this.angle;
    if (info.posture == FoldPosture.none && angle != null && angle < 15) {
      return FoldPosture.closed;
    }
    return info.posture;
  }

  /// Folded shut (iPhone Duo outer display).
  bool get isClosed => posture == FoldPosture.closed;

  /// Partly open, like a book or a laptop.
  bool get isHalfOpen => posture == FoldPosture.halfOpen;

  /// Fully open and flat.
  bool get isFlat => posture == FoldPosture.flat;

  /// The big screen of a foldable is in use (half open or flat).
  bool get isOpen => isHalfOpen || isFlat;

  /// This is a foldable: a known foldable model, a reported hinge, or a fold
  /// in the display features.
  bool get isFoldable {
    final form = device?.form;
    return form == FoldForm.book ||
        form == FoldForm.flip ||
        hinge != HingeStatus.unknown ||
        info.hasFold;
  }

  @override
  bool operator ==(Object other) =>
      other is FoldState &&
      other.info == info &&
      other.hinge == hinge &&
      other.angle == angle &&
      other.model == model;

  @override
  int get hashCode => Object.hash(info, hinge, angle, model);

  @override
  String toString() =>
      'FoldState(${posture.name}, angle: $angle, model: $model, ${info.windowSizeClass.name})';
}

/// Entry points for reading and listening to the fold.
abstract final class FoldKit {
  static final StreamController<FoldState> _changes =
      StreamController<FoldState>.broadcast();
  static FoldState? _current;

  /// The fold state for [context]; the caller rebuilds when it changes.
  static FoldState of(BuildContext context) => FoldState(
    info: FoldInfo.of(context),
    hinge: FoldKitScope.statusOf(context),
    angle: FoldKitScope.angleOf(context),
    model: FoldKitScope.modelOf(context),
  );

  /// Every change of the app window's fold state, for code outside widgets
  /// (analytics, controllers). Needs a [FoldKitScope] at the top of the app.
  static Stream<FoldState> get changes => _changes.stream;

  /// Every change of the hinge angle in degrees (`null` when the sensor stops
  /// reporting), for code outside widgets. Needs a [FoldKitScope].
  static Stream<double?> get angles =>
      changes.map((state) => state.angle).distinct();

  /// The latest state published on [changes], or `null` before the first one.
  static FoldState? get current => _current;

  static void _publish(FoldState state) {
    if (state == _current) return;
    _current = state;
    _changes.add(state);
  }
}

/// Rebuilds with the current [FoldState]:
///
/// ```dart
/// FoldBuilder(
///   builder: (context, fold) => fold.isOpen ? const WideBooking() : const PhoneBooking(),
/// )
/// ```
class FoldBuilder extends StatelessWidget {
  /// Builds from the fold state.
  final Widget Function(BuildContext context, FoldState fold) builder;

  /// Creates the builder.
  const FoldBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, FoldKit.of(context));
}

/// Calls [onChanged] when the posture, the hinge angle, the device or the
/// fold changes, and [onAngleChanged] when only the hinge angle matters
/// (not on the first build unless [fireImmediately]).
///
/// ```dart
/// FoldListener(
///   onAngleChanged: (angle) => setState(() => hinge = angle), // degrees, 180 = flat
///   child: page,
/// )
/// ```
class FoldListener extends StatefulWidget {
  /// Called with the new state.
  final ValueChanged<FoldState>? onChanged;

  /// Called with the new hinge angle in degrees (`null` without a sensor).
  final ValueChanged<double?>? onAngleChanged;

  /// Also call [onChanged] once with the first state.
  final bool fireImmediately;

  /// The subtree.
  final Widget child;

  /// Creates the listener.
  const FoldListener({
    super.key,
    this.onChanged,
    this.onAngleChanged,
    required this.child,
    this.fireImmediately = false,
  }) : assert(
         onChanged != null || onAngleChanged != null,
         'Pass onChanged or onAngleChanged.',
       );

  @override
  State<FoldListener> createState() => _FoldListenerState();
}

class _FoldListenerState extends State<FoldListener> {
  FoldState? _last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = FoldKit.of(context);
    final previous = _last;
    _last = state;
    if (state == previous) return;
    if (previous == null && !widget.fireImmediately) return;
    final angleChanged = previous == null || previous.angle != state.angle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChanged?.call(state);
      if (angleChanged) widget.onAngleChanged?.call(state.angle);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Placed inside [FoldKitScope]; publishes the app's state on [FoldKit.changes].
class FoldStatePublisher extends StatefulWidget {
  /// The app.
  final Widget child;

  /// Creates the publisher.
  const FoldStatePublisher({super.key, required this.child});

  @override
  State<FoldStatePublisher> createState() => _FoldStatePublisherState();
}

class _FoldStatePublisherState extends State<FoldStatePublisher> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = FoldKit.of(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FoldKit._publish(state),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
