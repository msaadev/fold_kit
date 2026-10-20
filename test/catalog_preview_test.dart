import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

void main() {
  group('FoldDevices', () {
    test('snapshot has iPhone Duo with its measured sizes', () {
      final duo = FoldDevices.byId('iphone-duo')!;
      expect(duo.outer, const Size(466, 678));
      expect(duo.inner, const Size(951, 669));
      expect(duo.fold, const Rect.fromLTWH(455.5, 0, 40, 669));
    });

    test('parses the remote catalog', () {
      final devices = FoldDevices.parse('''
{"schemaVersion": 1, "devices": [
  {"id": "flip", "name": "Flip", "form": "flip", "platform": "android",
   "inner": {"width": 412, "height": 915},
   "fold": {"axis": "horizontal", "offset": 457, "thickness": 0}}
]}''')!;
      expect(devices.single.form, FoldForm.flip);
      expect(devices.single.fold, const Rect.fromLTWH(0, 457, 412, 0));
    });

    test('rejects a newer schema or broken JSON', () {
      expect(FoldDevices.parse('{"schemaVersion": 2, "devices": []}'), isNull);
      expect(FoldDevices.parse('not json'), isNull);
    });
  });

  group('FoldPreview', () {
    Future<void> pump(WidgetTester tester, Widget preview) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: preview)));
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'half open iPhone Duo: FoldTwoPane splits at the fold even when scaled',
      (tester) async {
        late FoldInfo info;
        await pump(
          tester,
          FoldPreview(
            child: Builder(
              builder: (context) {
                info = FoldInfo.of(context);
                return const FoldTwoPane(
                  start: SizedBox.expand(key: Key('start')),
                  end: SizedBox.expand(key: Key('end')),
                );
              },
            ),
          ),
        );
        expect(info.posture, FoldPosture.halfOpen);
        expect(info.windowSize, const Size(951, 669));
        final start = tester.renderObject<RenderBox>(
          find.byKey(const Key('start')),
        );
        expect(start.size.width, 455.5);
      },
    );

    testWidgets(
      'closed iPhone Duo: outer display, vertical bars, right inset',
      (tester) async {
        late FoldInfo info;
        late EdgeInsets padding;
        await pump(
          tester,
          FoldPreview(
            posture: FoldPosture.closed,
            child: Builder(
              builder: (context) {
                info = FoldInfo.of(context);
                padding = MediaQuery.paddingOf(context);
                return FoldScaffold(
                  destinations: const [
                    FoldDestination(icon: Icons.home, label: 'Home'),
                    FoldDestination(icon: Icons.person, label: 'Me'),
                  ],
                  body: const SizedBox(),
                );
              },
            ),
          ),
        );
        expect(info.posture, FoldPosture.closed);
        expect(info.windowSize, const Size(466, 678));
        expect(padding.right, 84);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Home'), findsOneWidget);
      },
    );

    testWidgets('iPad: no fold, two panes by width', (tester) async {
      late FoldInfo info;
      await pump(
        tester,
        FoldPreview(
          device: FoldDevices.byId('ipad-11'),
          posture: FoldPosture.flat,
          child: Builder(
            builder: (context) {
              info = FoldInfo.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(info.hasFold, isFalse);
      expect(info.windowSizeClass, WindowSizeClass.expanded);
    });

    testWidgets('controls switch the posture', (tester) async {
      late FoldInfo info;
      await pump(
        tester,
        FoldPreview(
          controls: true,
          child: Builder(
            builder: (context) {
              info = FoldInfo.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.tap(find.text('Closed'));
      await tester.pump();
      expect(info.posture, FoldPosture.closed);
    });
  });
}
