import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

Future<void> _pump(WidgetTester tester, Widget preview) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: preview)));
  await tester.pump();
  await tester.pump();
}

Widget _panes() => FoldTwoPane(
  splitWhen: (fold) => fold.isHalfOpen,
  splitWithoutFold: false,
  compact: const SizedBox.expand(key: Key('page')),
  start: const SizedBox.expand(key: Key('start')),
  end: const SizedBox.expand(key: Key('end')),
);

void main() {
  testWidgets('FoldTwoPane splits only while half open', (tester) async {
    await _pump(tester, FoldPreview(child: _panes()));
    expect(tester.getSize(find.byKey(const Key('start'))).width, 455.5);

    await _pump(
      tester,
      FoldPreview(posture: FoldPosture.flat, child: _panes()),
    );
    expect(find.byKey(const Key('start')), findsNothing);
    expect(find.byKey(const Key('page')), findsOneWidget);
  });

  testWidgets('FoldLayoutBuilder maps the fold into the widget', (
    tester,
  ) async {
    late LocalFold local;
    await _pump(
      tester,
      FoldPreview(
        child: Padding(
          padding: const EdgeInsets.only(left: 100),
          child: FoldLayoutBuilder(
            builder: (context, fold) {
              local = fold;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(local.axis, FoldAxis.vertical);
    expect(local.rect!.left, 355.5);
    expect(local.start.width, 355.5);
    expect(local.end.left, 395.5);
  });

  test('FoldAngleController holds the angle from before the tap', () async {
    final angles = StreamController<double?>();
    var now = DateTime(2026);
    final controller = FoldAngleController(
      angles: angles.stream,
      now: () => now,
    );
    angles.add(90);
    await Future<void>.delayed(Duration.zero);
    now = now.add(const Duration(seconds: 1));
    angles.add(97); // the finger moved the hinge while tapping
    await Future<void>.delayed(Duration.zero);
    now = now.add(const Duration(milliseconds: 100));

    expect(controller.angle, 97);
    expect(controller.hold(), 90);
    angles.add(120);
    await Future<void>.delayed(Duration.zero);
    expect(controller.angle, 90);
    controller.release();
    expect(controller.angle, 120);
    controller.dispose();
    await angles.close();
  });

  testWidgets('FoldBarTheme.topInset moves the Duo bar', (tester) async {
    await _pump(
      tester,
      FoldPreview(
        posture: FoldPosture.closed,
        child: const FoldScaffold(
          barTheme: FoldBarTheme(topInset: 40),
          actions: [
            FoldAction(icon: Icon(Icons.add), label: 'Add', onPressed: null),
          ],
          body: SizedBox(),
        ),
      ),
    );
    final window = tester.getRect(find.byType(FoldScaffold));
    final add = tester.getRect(find.byTooltip('Add'));
    final scale = window.height / 678;
    expect((add.top - window.top) / scale, lessThan(170));
  });

  group('vertical bar choice', () {
    Future<void> pumpAt(WidgetTester tester, Size size, Widget child) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: child));
    }

    const tabs = [
      FoldDestination(icon: Icon(Icons.home), label: 'Home'),
      FoldDestination(icon: Icon(Icons.list), label: 'List'),
    ];

    testWidgets(
      'auto: open Android foldable (852 wide, portrait) is vertical',
      (tester) async {
        await pumpAt(
          tester,
          const Size(852, 883),
          const FoldScaffold(destinations: tabs, body: SizedBox()),
        );
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byTooltip('Home'), findsOneWidget);
      },
    );

    testWidgets('verticalWhen overrides the auto rule', (tester) async {
      await pumpAt(
        tester,
        const Size(852, 883),
        FoldScaffold(
          verticalWhen: (_) => false,
          destinations: tabs,
          body: const SizedBox(),
        ),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('verticalBarBuilder draws the bar from its content', (
      tester,
    ) async {
      final taps = <int>[];
      await pumpAt(
        tester,
        const Size(1100, 700),
        FoldScaffold(
          destinations: tabs,
          onDestinationSelected: taps.add,
          verticalBarBuilder: (context, bar) => Column(
            children: [
              for (var i = 0; i < bar.destinations.length; i++)
                TextButton(
                  onPressed: () => bar.onDestinationSelected?.call(i),
                  child: Text('custom ${bar.destinations[i].label}'),
                ),
            ],
          ),
          body: const SizedBox(),
        ),
      );
      await tester.tap(find.text('custom List'));
      expect(taps, [1]);
    });
  });
}
