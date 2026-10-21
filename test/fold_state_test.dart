import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

void main() {
  test('model ids map to catalog devices', () {
    expect(FoldDevices.byModel('iPhone19,4')?.name, 'iPhone Duo');
    expect(FoldDevices.byModel('SM-F966B')?.name, 'Galaxy Z Fold7');
    expect(FoldDevices.byModel('iPhone18,1'), isNull);
    expect(FoldDevices.byModel(null), isNull);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
  }

  testWidgets('FoldBuilder: open vs normal page, angle and device', (
    tester,
  ) async {
    late FoldState fold;
    Widget page(FoldPosture posture) => FoldPreview(
      posture: posture,
      child: FoldBuilder(
        builder: (context, state) {
          fold = state;
          return Text(state.isOpen ? 'fold layout' : 'normal page');
        },
      ),
    );

    await pump(tester, page(FoldPosture.halfOpen));
    expect(find.text('fold layout'), findsOneWidget);
    expect(fold.isHalfOpen, isTrue);
    expect(fold.angle, 120);
    expect(fold.model, 'iPhone19,4');
    expect(fold.device?.name, 'iPhone Duo');
    expect(fold.isFoldable, isTrue);

    await pump(tester, page(FoldPosture.closed));
    expect(find.text('normal page'), findsOneWidget);
    expect(fold.isClosed, isTrue);
    expect(fold.angle, 0);
  });

  testWidgets('a phone without a hinge is not a foldable', (tester) async {
    late FoldState fold;
    await pump(
      tester,
      FoldPreview(
        device: FoldDevices.byId('iphone-17-pro'),
        posture: FoldPosture.flat,
        child: FoldBuilder(
          builder: (context, state) {
            fold = state;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(fold.isFoldable, isFalse);
    expect(fold.angle, isNull);
  });

  testWidgets('FoldListener reports posture changes', (tester) async {
    final seen = <FoldPosture>[];
    Widget page(FoldPosture posture) => FoldPreview(
      posture: posture,
      child: FoldListener(
        onChanged: (state) => seen.add(state.posture),
        child: const SizedBox(),
      ),
    );

    await pump(tester, page(FoldPosture.closed));
    await pump(tester, page(FoldPosture.halfOpen));
    await pump(tester, page(FoldPosture.flat));
    expect(seen, [FoldPosture.halfOpen, FoldPosture.flat]);
  });

  testWidgets('FoldListener.onAngleChanged reports only angle changes', (
    tester,
  ) async {
    final angles = <double?>[];
    Widget page(FoldPosture posture) => FoldPreview(
      posture: posture,
      child: FoldListener(
        onAngleChanged: angles.add,
        fireImmediately: true,
        child: const SizedBox(),
      ),
    );

    await pump(tester, page(FoldPosture.closed));
    await pump(tester, page(FoldPosture.closed));
    await pump(tester, page(FoldPosture.halfOpen));
    expect(angles, [0, 120]);
  });

  test('Android outer display: small hinge angle means closed', () {
    const info = FoldInfo(
      posture: FoldPosture.none,
      windowSize: Size(412, 915),
    );
    expect(const FoldState(info: info, angle: 0).isClosed, isTrue);
    expect(const FoldState(info: info, angle: 90).posture, FoldPosture.none);
    expect(const FoldState(info: info).posture, FoldPosture.none);
  });
}
