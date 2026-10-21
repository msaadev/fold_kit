import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

Widget _app(Widget child) => MaterialApp(home: child);

const _tabs = [
  FoldDestination(icon: Icon(Icons.home), label: 'Home'),
  FoldDestination(icon: Icon(Icons.list), label: 'List'),
];

void main() {
  testWidgets('vertical bar buttons expose a tap action', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _app(
        FoldScaffold(
          placement: FoldBarPlacement.trailing,
          body: const SizedBox(),
          actions: [
            FoldAction(
              icon: const Icon(Icons.search),
              label: 'Search',
              onPressed: () => taps++,
            ),
          ],
        ),
      ),
    );
    final data = tester
        .getSemantics(find.bySemanticsLabel('Search'))
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Search'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('own AppBar shows in the vertical layout', (tester) async {
    await tester.pumpWidget(
      _app(
        FoldScaffold(
          placement: FoldBarPlacement.trailing,
          body: const SizedBox(),
          appBar: AppBar(
            title: const Text('Rides'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Rides'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('vertical bar scrolls instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(800, 150);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        FoldScaffold(
          placement: FoldBarPlacement.trailing,
          body: const SizedBox(),
          destinations: _tabs,
          actions: [
            FoldAction(
              icon: const Icon(Icons.check),
              label: 'Done',
              onPressed: () {},
              prominent: true,
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer is passed to the inner Scaffold', (tester) async {
    await tester.pumpWidget(
      _app(
        const FoldScaffold(
          placement: FoldBarPlacement.trailing,
          body: SizedBox(),
          drawer: Drawer(child: Text('Menu')),
        ),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('glass: floating glass tab bar on phones, glass capsules', (
    tester,
  ) async {
    final taps = <int>[];
    Widget app(FoldBarPlacement placement) => _app(
      FoldScaffold(
        placement: placement,
        body: const SizedBox(),
        destinations: _tabs,
        onDestinationSelected: taps.add,
        barTheme: const FoldBarTheme(glass: true),
      ),
    );
    await tester.pumpWidget(app(FoldBarPlacement.bottom));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    await tester.tap(find.text('List'));
    expect(taps, [1]);

    await tester.pumpWidget(app(FoldBarPlacement.trailing));
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byTooltip('List'), findsOneWidget);
  });

  testWidgets('right-to-left: Duo bar stays in the right status strip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: FoldPreview(
            posture: FoldPosture.closed,
            child: const FoldScaffold(
              destinations: _tabs,
              body: SizedBox.expand(key: Key('body')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final body = tester.getRect(find.byKey(const Key('body')));
    expect(
      tester.getCenter(find.byTooltip('Home')).dx,
      greaterThan(body.right),
    );
  });
}
