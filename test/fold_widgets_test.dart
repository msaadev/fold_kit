import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(951, 669),
    List<DisplayFeature> features = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.displayFeatures = features;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
  }

  const book = DisplayFeature(
    bounds: Rect.fromLTWH(455, 0, 40, 669),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureHalfOpened,
  );

  group('FoldTwoPane', () {
    const panes = FoldTwoPane(
      start: ColoredBox(key: Key('start'), color: Colors.red),
      end: ColoredBox(key: Key('end'), color: Colors.blue),
    );

    testWidgets('splits exactly at a vertical fold', (tester) async {
      await pump(tester, const Scaffold(body: panes), features: [book]);
      expect(tester.getSize(find.byKey(const Key('start'))).width, 455);
      expect(tester.getTopLeft(find.byKey(const Key('end'))).dx, 495);
    });

    testWidgets('splits at a horizontal fold', (tester) async {
      await pump(
        tester,
        panes,
        size: const Size(841, 701),
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(0, 350, 841, 0),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(tester.getSize(find.byKey(const Key('start'))).height, 350);
    });

    testWidgets('no fold: ratio on wide windows, one pane on phones', (
      tester,
    ) async {
      await pump(tester, panes, size: const Size(1000, 700));
      expect(tester.getSize(find.byKey(const Key('start'))).width, 500);

      await pump(tester, panes, size: const Size(390, 844));
      expect(find.byKey(const Key('start')), findsOneWidget);
      expect(find.byKey(const Key('end')), findsNothing);
    });
  });

  testWidgets('FoldAvoid moves a button off the fold', (tester) async {
    await pump(
      tester,
      const Stack(
        children: [
          Positioned(
            left: 450,
            top: 100,
            child: FoldAvoid(
              child: SizedBox(key: Key('fab'), width: 56, height: 56),
            ),
          ),
        ],
      ),
      features: [book],
    );
    final rect = tester.getRect(find.byKey(const Key('fab')));
    expect(rect.overlaps(book.bounds), isFalse);
  });

  group('FoldScaffold', () {
    Widget scaffold({
      FoldBarPlacement placement = FoldBarPlacement.auto,
      int actionCount = 1,
    }) => FoldScaffold(
      title: const Text('Rides'),
      placement: placement,
      actions: [
        for (var i = 0; i < actionCount; i++)
          FoldAction(
            icon: const Icon(Icons.search),
            label: 'Action $i',
            onPressed: () {},
          ),
      ],
      destinations: const [
        FoldDestination(icon: Icon(Icons.home), label: 'Home'),
        FoldDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
      body: const _Counter(),
    );

    testWidgets('phone: app bar on top, tabs at the bottom', (tester) async {
      await pump(tester, scaffold(), size: const Size(390, 844));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('wide landscape: one vertical bar, body keeps its state', (
      tester,
    ) async {
      await pump(tester, scaffold(), size: const Size(390, 844));
      await tester.tap(find.text('0'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await pump(tester, scaffold(), size: const Size(1100, 700));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Action 0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('migration: own bottom bar on phones, no extra app bar', (
      tester,
    ) async {
      const items = [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
      ];
      Widget app() => FoldScaffold(
        body: const SizedBox(),
        bottomNavigationBar: BottomNavigationBar(items: items),
        destinations: [for (final i in items) FoldDestination.fromItem(i)],
        barTheme: const FoldBarTheme(selectedColor: Color(0xFFFFB300)),
      );

      await pump(tester, app(), size: const Size(390, 844));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await pump(tester, app(), size: const Size(1100, 700));
      expect(find.byType(BottomNavigationBar), findsNothing);
      final home = tester.widget<Text>(find.text('Home'));
      expect(home.style?.color, const Color(0xFFFFB300));
    });

    testWidgets('short vertical bar moves actions into the overflow menu', (
      tester,
    ) async {
      await pump(
        tester,
        scaffold(placement: FoldBarPlacement.trailing, actionCount: 8),
        size: const Size(700, 400),
      );
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('$_count'),
    );
  }
}
