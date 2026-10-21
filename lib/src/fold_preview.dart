import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';

import 'fold_device.dart';
import 'fold_info.dart';
import 'fold_kit_scope.dart';
import 'fold_tracker.dart';

/// Shows [child] as it would look on [device] in [posture], on any screen:
/// the window size, the fold, the hinge status and the safe area are faked,
/// so `FoldInfo`, `FoldScaffold` and `FoldTwoPane` behave like on the device.
///
/// Use it to build foldable layouts without a foldable, in widget tests, in
/// golden tests and for screenshots. With [controls] you get a small toolbar
/// to switch device, posture and orientation.
class FoldPreview extends StatefulWidget {
  /// The app or screen to preview.
  final Widget child;

  /// The device to fake. Defaults to iPhone Duo.
  final FoldDevice? device;

  /// The posture to fake.
  final FoldPosture posture;

  /// Inner display held in portrait.
  final bool portrait;

  /// Paints the fold in translucent red.
  final bool showFold;

  /// Shows a toolbar to change device, posture and orientation.
  final bool controls;

  /// Creates a preview.
  const FoldPreview({
    super.key,
    required this.child,
    this.device,
    this.posture = FoldPosture.halfOpen,
    this.portrait = false,
    this.showFold = true,
    this.controls = false,
  });

  @override
  State<FoldPreview> createState() => _FoldPreviewState();
}

class _FoldPreviewState extends State<FoldPreview> {
  final _windowKey = GlobalKey();
  late FoldDevice _device;
  late FoldPosture _posture;
  late bool _portrait;

  @override
  void initState() {
    super.initState();
    _device = widget.device ?? FoldDevices.snapshot.first;
    _posture = widget.posture;
    _portrait = widget.portrait;
  }

  @override
  void didUpdateWidget(FoldPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) {
      _device = widget.device ?? FoldDevices.snapshot.first;
    }
    if (oldWidget.posture != widget.posture) _posture = widget.posture;
    if (oldWidget.portrait != widget.portrait) _portrait = widget.portrait;
  }

  @override
  Widget build(BuildContext context) {
    final preview = Center(child: FittedBox(child: _buildWindow(context)));
    if (!widget.controls) return preview;
    return Column(
      children: [
        _buildControls(),
        Expanded(child: preview),
      ],
    );
  }

  Widget _buildWindow(BuildContext context) {
    final closed = _posture == FoldPosture.closed && _device.outer != null;
    var size = closed ? _device.outer! : _device.inner;
    var fold = closed ? null : _device.fold;
    if (_portrait && !closed) {
      size = size.flipped;
      fold = fold == null
          ? null
          : Rect.fromLTWH(fold.top, fold.left, fold.height, fold.width);
    }
    final hasHinge =
        _device.form == FoldForm.book || _device.form == FoldForm.flip;
    final features = <DisplayFeature>[
      if (fold != null && _posture == FoldPosture.halfOpen)
        DisplayFeature(
          bounds: fold,
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureHalfOpened,
        ),
      // Android reports the fold when flat too; iOS does not.
      if (fold != null &&
          _posture == FoldPosture.flat &&
          _device.platform == 'android')
        DisplayFeature(
          bounds: fold,
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
    ];
    final padding = closed
        ? _device.outerPadding
        : _portrait
        ? EdgeInsets.zero
        : _device.innerPadding;
    final base = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return FoldWindowAnchor(
      windowKey: _windowKey,
      child: Container(
        key: _windowKey,
        width: size.width,
        height: size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
        // Drawn on top so the frame never shifts the content off the fold.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x33000000)),
        ),
        child: MediaQuery(
          data: base.copyWith(
            size: size,
            displayFeatures: features,
            padding: padding,
            viewPadding: padding,
            viewInsets: EdgeInsets.zero,
          ),
          child: FoldScopeData(
            model: _device.modelIds.isEmpty ? null : _device.modelIds.first,
            status: !hasHinge
                ? HingeStatus.unknown
                : switch (_posture) {
                    FoldPosture.closed => HingeStatus.closed,
                    FoldPosture.halfOpen => HingeStatus.partiallyOpen,
                    _ => HingeStatus.fullyOpen,
                  },
            angle: !hasHinge
                ? null
                : switch (_posture) {
                    FoldPosture.closed => 0,
                    FoldPosture.halfOpen => 120,
                    _ => 180,
                  },
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                if (widget.showFold && features.isNotEmpty)
                  Positioned.fromRect(
                    rect: fold!.inflate(
                      fold.width == 0 || fold.height == 0 ? 1 : 0,
                    ),
                    child: const IgnorePointer(
                      child: ColoredBox(color: Color(0x55FF1744)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<FoldDevice>(
              value: _device,
              items: [
                for (final d in FoldDevices.all)
                  DropdownMenuItem(value: d, child: Text(d.name)),
              ],
              onChanged: (d) => setState(() => _device = d ?? _device),
            ),
            SegmentedButton<FoldPosture>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: FoldPosture.closed, label: Text('Closed')),
                ButtonSegment(
                  value: FoldPosture.halfOpen,
                  label: Text('Half open'),
                ),
                ButtonSegment(value: FoldPosture.flat, label: Text('Flat')),
              ],
              selected: {
                _posture == FoldPosture.none ? FoldPosture.flat : _posture,
              },
              onSelectionChanged: (v) => setState(() => _posture = v.first),
            ),
            IconButton(
              tooltip: 'Rotate',
              icon: const Icon(Icons.screen_rotation_outlined),
              onPressed: () => setState(() => _portrait = !_portrait),
            ),
          ],
        ),
      ),
    );
  }
}
