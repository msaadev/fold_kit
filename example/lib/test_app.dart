import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fold_kit/fold_kit.dart';

// flutter run -t lib/test_app.dart
// Test app for 1.1.0: native bars moving into the vertical bar, and the hinge angle listener.
void main() => runApp(const FoldKitScope(child: TestApp()));

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fold_kit test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0EA5E9)),
      home: const TestHome(),
    );
  }
}

enum BarKind { navigationBar, bottomNavigationBar, cupertinoTabBar, glass }

class TestHome extends StatefulWidget {
  const TestHome({super.key});

  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  int _tab = 0;
  BarKind _bar = BarKind.navigationBar;
  FoldBarPlacement _placement = FoldBarPlacement.auto;
  final _log = <String>[];

  static const _labels = ['Home', 'Angle', 'Log'];
  static const _icons = [Icons.home, Icons.architecture, Icons.list];

  @override
  Widget build(BuildContext context) {
    return FoldListener(
      onAngleChanged: (angle) =>
          _add('angle → ${angle == null ? 'null' : '${angle.round()}°'}'),
      onChanged: (fold) => _add('state → ${fold.posture.name}'),
      fireImmediately: true,
      child: FoldScaffold(
        appBar: AppBar(
          title: Text(_labels[_tab]),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add',
              onPressed: () => _add('AppBar: Add'),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () => _add('AppBar: Share'),
            ),
          ],
        ),
        bottomNavigationBar: _buildBar(),
        destinations: _bar == BarKind.glass
            ? [
                for (var i = 0; i < _labels.length; i++)
                  FoldDestination(icon: Icon(_icons[i]), label: _labels[i]),
              ]
            : const [],
        selectedIndex: _tab,
        onDestinationSelected: _select,
        barTheme: FoldBarTheme(glass: _bar == BarKind.glass),
        placement: _placement,
        body: IndexedStack(
          index: _tab,
          children: [_buildHome(), _buildAngle(), _buildLog()],
        ),
      ),
    );
  }

  Widget? _buildBar() {
    final items = [
      for (var i = 0; i < _labels.length; i++)
        BottomNavigationBarItem(icon: Icon(_icons[i]), label: _labels[i]),
    ];
    return switch (_bar) {
      BarKind.navigationBar => NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
        ],
      ),
      BarKind.bottomNavigationBar => BottomNavigationBar(
        currentIndex: _tab,
        onTap: _select,
        items: items,
      ),
      BarKind.cupertinoTabBar => CupertinoTabBar(
        currentIndex: _tab,
        onTap: _select,
        items: items,
      ),
      BarKind.glass => null,
    };
  }

  Widget _buildHome() {
    final fold = FoldKit.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bar type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<BarKind>(
          segments: const [
            ButtonSegment(
              value: BarKind.navigationBar,
              label: Text('Navigation'),
            ),
            ButtonSegment(
              value: BarKind.bottomNavigationBar,
              label: Text('Bottom'),
            ),
            ButtonSegment(
              value: BarKind.cupertinoTabBar,
              label: Text('Cupertino'),
            ),
            ButtonSegment(value: BarKind.glass, label: Text('Glass')),
          ],
          selected: {_bar},
          onSelectionChanged: (s) => setState(() => _bar = s.first),
        ),
        const SizedBox(height: 16),
        Text('Bars', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<FoldBarPlacement>(
          segments: const [
            ButtonSegment(value: FoldBarPlacement.auto, label: Text('Auto')),
            ButtonSegment(
              value: FoldBarPlacement.bottom,
              label: Text('Bottom'),
            ),
            ButtonSegment(
              value: FoldBarPlacement.trailing,
              label: Text('Vertical'),
            ),
          ],
          selected: {_placement},
          onSelectionChanged: (s) => setState(() => _placement = s.first),
        ),
        const SizedBox(height: 24),
        Text(
          'Close the Duo or turn it to landscape: the tabs and the Add / Share '
          'buttons should move to a vertical bar on the right, like iOS does '
          'for native apps.',
        ),
        const SizedBox(height: 24),
        _buildRow('Posture', fold.posture.name),
        _buildRow('Hinge', FoldKitScope.statusOf(context).name),
        _buildRow(
          'Vertical bar',
          '${FoldScaffold.isVertical(context, _placement)}',
        ),
        _buildRow('Device', fold.device?.name ?? fold.model ?? '-'),
        _buildRow('Size class', fold.info.windowSizeClass.name),
      ],
    );
  }

  Widget _buildAngle() {
    final angle = FoldKitScope.angleOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            angle == null ? 'No hinge sensor' : '${angle.round()}°',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          const Text('FoldListener.onAngleChanged → see the Log tab'),
        ],
      ),
    );
  }

  Widget _buildLog() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _log.length,
      itemBuilder: (_, i) => Text(_log[_log.length - 1 - i]),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _select(int i) {
    setState(() => _tab = i);
    _add('tab → ${_labels[i]} (${_bar.name})');
  }

  void _add(String line) {
    final t = TimeOfDay.now().format(context);
    setState(() => _log.add('$t  $line'));
  }
}
