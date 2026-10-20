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
      home: const FoldPage(),
    );
  }
}

class FoldPage extends StatelessWidget {
  const FoldPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final rect = fold.rect;
    final Widget body;
    if (rect != null && fold.axis == FoldAxis.vertical) {
      body = Row(
        children: [
          SizedBox(width: rect.left, child: _buildList(context)),
          SizedBox(width: rect.width),
          Expanded(child: _buildInfo(context, fold)),
        ],
      );
    } else if (fold.windowSizeClass != WindowSizeClass.compact) {
      body = Row(
        children: [
          Expanded(child: _buildList(context)),
          const VerticalDivider(width: 1),
          Expanded(child: _buildInfo(context, fold)),
        ],
      );
    } else {
      body = _buildInfo(context, fold);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('fold_kit')),
      body: SafeArea(child: body),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final name in ['Inbox', 'Rides', 'Payments', 'Settings'])
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(name),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, FoldInfo fold) {
    final textTheme = Theme.of(context).textTheme;
    final angle = FoldKitScope.angleOf(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(_title(fold), style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'FoldInfo.of(context) — the same call on every device.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _buildRow('Posture', fold.posture.name),
        _buildRow('Size class', fold.windowSizeClass.name),
        _buildRow(
          'Window',
          '${fold.windowSize.width.round()} × ${fold.windowSize.height.round()}',
        ),
        _buildRow('Fold axis', fold.axis?.name ?? '—'),
        _buildRow(
          'Fold at',
          fold.rect == null
              ? '—'
              : 'x ${fold.rect!.left.round()}, ${fold.rect!.width.round()} wide',
        ),
        _buildRow('Hinge', angle == null ? '—' : '${angle.round()}°'),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value),
    );
  }

  String _title(FoldInfo fold) => switch (fold.posture) {
    FoldPosture.halfOpen => 'Split at the fold',
    FoldPosture.closed => 'Outer display',
    FoldPosture.flat => 'Open and flat',
    FoldPosture.none =>
      fold.windowSizeClass == WindowSizeClass.compact
          ? 'Phone layout'
          : 'Two panes',
  };
}
