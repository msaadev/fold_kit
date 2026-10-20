import 'package:flutter/material.dart';
import 'package:fold_kit/fold_kit.dart';

void main() => runApp(const FoldKitScope(child: ExampleApp()));

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8B5CF6);
    return MaterialApp(
      title: 'fold_kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  int _selected = 0;

  static const _items = [
    'Airport transfer',
    'City tour',
    'Night ride',
    'Shuttle',
  ];

  @override
  Widget build(BuildContext context) {
    return FoldScaffold(
      title: const Text('fold_kit'),
      actions: [
        FoldAction(
          icon: Icons.add,
          label: 'New',
          prominent: true,
          onPressed: () {},
        ),
        FoldAction(icon: Icons.search, label: 'Search', onPressed: () {}),
        FoldAction(
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: () {},
        ),
      ],
      destinations: const [
        FoldDestination(
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt,
          label: 'Rides',
        ),
        FoldDestination(
          icon: Icons.map_outlined,
          selectedIcon: Icons.map,
          label: 'Map',
        ),
        FoldDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'Profile',
        ),
      ],
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      body: FoldTwoPane(start: _buildList(context), end: _buildDetail(context)),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < _items.length; i++)
          Card(
            child: ListTile(
              selected: i == _selected,
              leading: const Icon(Icons.local_taxi_outlined),
              title: Text(_items[i]),
              onTap: () => setState(() => _selected = i),
            ),
          ),
      ],
    );
  }

  Widget _buildDetail(BuildContext context) {
    final fold = FoldInfo.of(context);
    final angle = FoldKitScope.angleOf(context);
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(_items[_selected], style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(_headline(fold), style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        _buildRow('Posture', fold.posture.name),
        _buildRow('Size class', fold.windowSizeClass.name),
        _buildRow(
          'Window',
          '${fold.windowSize.width.round()} × ${fold.windowSize.height.round()}',
        ),
        _buildRow(
          'Fold',
          fold.rect == null
              ? '—'
              : '${fold.axis!.name}, x ${fold.rect!.left.round()}',
        ),
        _buildRow('Hinge', angle == null ? '—' : '${angle.round()}°'),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value),
    );
  }

  String _headline(FoldInfo fold) => switch (fold.posture) {
    FoldPosture.halfOpen => 'FoldTwoPane splits exactly at the fold.',
    FoldPosture.closed => 'Outer display: bars move to the right, like iOS.',
    FoldPosture.flat => 'Open and flat: two panes, no hinge to avoid.',
    FoldPosture.none => 'Same code on phones, tablets, web and desktop.',
  };
}
