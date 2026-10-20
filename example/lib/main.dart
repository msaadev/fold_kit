import 'package:flutter/material.dart';
import 'package:fold_kit/fold_kit.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fold_kit',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3F51B5)),
      home: const FoldPage(),
    );
  }
}

class FoldPage extends StatelessWidget {
  const FoldPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('fold_kit')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildRow(
            'Window',
            '${fold.windowSize.width.round()} × '
                '${fold.windowSize.height.round()}',
          ),
          _buildRow('Size class', fold.windowSizeClass.name),
          _buildRow('Posture', fold.posture.name),
          _buildRow('Fold axis', fold.axis?.name ?? '—'),
          _buildRow('Fold rect', fold.rect?.toString() ?? '—'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return ListTile(title: Text(label), trailing: Text(value));
  }
}
