import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

void main() {
  const duoBook = DisplayFeature(
    bounds: Rect.fromLTWH(455.5, 0, 40, 669),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureHalfOpened,
  );

  test('book posture on an open foldable', () {
    final info = FoldInfo.fromFeatures(const Size(951, 669), const [duoBook]);
    expect(info.hasFold, isTrue);
    expect(info.axis, FoldAxis.vertical);
    expect(info.posture, FoldPosture.halfOpen);
    expect(info.windowSizeClass, WindowSizeClass.expanded);
  });

  test('tabletop is a horizontal fold', () {
    final info = FoldInfo.fromFeatures(const Size(841, 701), const [
      DisplayFeature(
        bounds: Rect.fromLTWH(0, 350, 841, 0),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureHalfOpened,
      ),
    ]);
    expect(info.axis, FoldAxis.horizontal);
  });

  test('flat fold, cutouts are ignored', () {
    final info = FoldInfo.fromFeatures(const Size(700, 800), const [
      DisplayFeature(
        bounds: Rect.fromLTWH(300, 0, 20, 20),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      ),
      DisplayFeature(
        bounds: Rect.fromLTWH(350, 0, 0, 800),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
    ]);
    expect(info.posture, FoldPosture.flat);
    expect(info.rect, const Rect.fromLTWH(350, 0, 0, 800));
  });

  test('no fold on a phone', () {
    final info = FoldInfo.fromFeatures(const Size(390, 844), const []);
    expect(info.hasFold, isFalse);
    expect(info.posture, FoldPosture.none);
    expect(info.windowSizeClass, WindowSizeClass.compact);
  });

  test('window size classes', () {
    expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
  });

  testWidgets('FoldInfo.of reads the window', (tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    tester.view.displayFeatures = const [duoBook];
    addTearDown(tester.view.reset);
    late FoldInfo info;
    await tester.pumpWidget(
      MediaQuery.fromView(
        view: tester.view,
        child: Builder(
          builder: (context) {
            info = FoldInfo.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(info.isHalfOpen, isTrue);
    expect(info.rect!.left, 455.5);
  });
}
