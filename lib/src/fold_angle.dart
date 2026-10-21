import 'dart:async';

import 'package:flutter/foundation.dart';

import 'fold_state.dart';

/// The hinge angle for protractor-style features: [angle] follows the
/// hinge live, and [hold] freezes the value from [lookBack] ago, so the
/// finger that taps "Hold" doesn't move the reading.
///
/// ```dart
/// final protractor = FoldAngleController();
/// ListenableBuilder(
///   listenable: protractor,
///   builder: (context, _) => Text('${protractor.angle?.round() ?? '--'}°'),
/// );
/// FilledButton(onPressed: protractor.hold, child: const Text('Hold'));
/// ```
///
/// Needs a `FoldKitScope` (or pass your own [angles] stream).
class FoldAngleController extends ChangeNotifier {
  /// How far back [hold] looks.
  final Duration lookBack;

  final DateTime Function() _now;
  final _samples = <(DateTime, double)>[];
  late final StreamSubscription<double?> _subscription;
  double? _live;
  double? _held;

  /// Starts listening to [angles] (defaults to [FoldKit.angles]).
  FoldAngleController({
    this.lookBack = const Duration(milliseconds: 400),
    Stream<double?>? angles,
    @visibleForTesting DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _live = FoldKit.current?.angle;
    _subscription = (angles ?? FoldKit.angles).listen(_add);
  }

  /// The held angle, else the live one; degrees, 180 = flat, `null` without
  /// a hinge sensor.
  double? get angle => _held ?? _live;

  /// Whether [hold] froze the reading.
  bool get isHeld => _held != null;

  /// Freezes the angle from [lookBack] ago and returns it.
  double? hold() {
    final before = _now().subtract(lookBack);
    final older = _samples.where((s) => !s.$1.isAfter(before));
    _held = older.isNotEmpty
        ? older.last.$2
        : _samples.isNotEmpty
        ? _samples.first.$2
        : _live;
    notifyListeners();
    return _held;
  }

  /// Follows the hinge again.
  void release() {
    _held = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _add(double? angle) {
    final now = _now();
    _live = angle;
    if (angle != null) _samples.add((now, angle));
    _samples.removeWhere((s) => now.difference(s.$1) > lookBack * 3);
    if (_held == null) notifyListeners();
  }
}
