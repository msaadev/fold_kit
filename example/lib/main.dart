import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fold_kit/fold_kit.dart';

// flutter run --dart-define=FOLD_PREVIEW=true  → try every foldable on any screen.
const _preview = bool.fromEnvironment('FOLD_PREVIEW');

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
      home: _preview
          ? const FoldPreview(controls: true, child: HomePage())
          : const HomePage(),
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

  static const _tabs = [
    FoldDestination(
      icon: Icons.vertical_split_outlined,
      selectedIcon: Icons.vertical_split,
      label: 'Panes',
    ),
    FoldDestination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'Hinge',
    ),
    FoldDestination(
      icon: Icons.ads_click_outlined,
      selectedIcon: Icons.ads_click,
      label: 'Avoid',
    ),
    FoldDestination(
      icon: Icons.info_outline,
      selectedIcon: Icons.info,
      label: 'Info',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FoldScaffold(
      title: Text(_tabs[_tab].label),
      actions: [
        FoldAction(
          icon: Icons.add,
          label: 'New',
          prominent: true,
          onPressed: () => _toast('FoldAction: New'),
        ),
        FoldAction(
          icon: Icons.search,
          label: 'Search',
          onPressed: () => _toast('FoldAction: Search'),
        ),
        FoldAction(
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: () => _toast('FoldAction: Share'),
        ),
      ],
      destinations: _tabs,
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      body: IndexedStack(
        index: _tab,
        children: const [PanesPage(), HingePage(), AvoidPage(), InfoPage()],
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

/// FoldTwoPane: list | detail, split exactly at the hinge.
class PanesPage extends StatefulWidget {
  const PanesPage({super.key});

  @override
  State<PanesPage> createState() => _PanesPageState();
}

class _PanesPageState extends State<PanesPage> {
  int _selected = 0;

  static const _rides = [
    ('Airport transfer', 'BER → Mitte', Icons.flight_takeoff),
    ('City tour', 'Brandenburg Gate, 2 h', Icons.location_city),
    ('Night ride', 'Kreuzberg → Prenzlauer Berg', Icons.nightlight_round),
    ('Shuttle', 'Messe Berlin, every 20 min', Icons.airport_shuttle),
  ];

  @override
  Widget build(BuildContext context) {
    return FoldTwoPane(start: _buildList(), end: _buildDetail(context));
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < _rides.length; i++)
          Card(
            child: ListTile(
              selected: i == _selected,
              leading: Icon(_rides[i].$3),
              title: Text(_rides[i].$1),
              subtitle: Text(_rides[i].$2),
              onTap: () => setState(() => _selected = i),
            ),
          ),
      ],
    );
  }

  Widget _buildDetail(BuildContext context) {
    final (title, route, icon) = _rides[_selected];
    final fold = FoldInfo.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(title, style: textTheme.headlineSmall),
        Text(route, style: textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text(switch (fold.posture) {
          FoldPosture.halfOpen => 'FoldTwoPane puts the list and the detail on either side of the hinge.',
          FoldPosture.closed =>
            'Outer display: one pane, bars on the right like iOS.',
          _ =>
            'Wide window: side by side. Fold the device to split at the hinge.',
        }, style: textTheme.bodyMedium),
      ],
    );
  }
}

/// The hinge angle and posture, live.
class HingePage extends StatelessWidget {
  const HingePage({super.key});

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final angle = FoldKitScope.angleOf(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 140,
              child: CustomPaint(
                painter: _GaugePainter(
                  angle: angle,
                  color: scheme.primary,
                  track: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              angle == null ? 'No hinge sensor' : '≈ ${angle.round()}°',
              style: textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Chip(label: Text('Posture: ${fold.posture.name}')),
            const SizedBox(height: 16),
            Text(
              'FoldKitScope.angleOf(context) — iPhone Duo and Android '
              'foldables. Use it for interaction, not for layout.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double? angle;
  final Color color;
  final Color track;

  const _GaugePainter({
    required this.angle,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height - 10),
      radius: size.width / 2 - 14,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, stroke..color = track);
    if (angle == null) return;
    final value = angle!.clamp(0, 180) / 180;
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * value,
      false,
      stroke..color = color,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.angle != angle || old.color != color;
}

/// FoldAvoid: a button placed in the middle would sit on the hinge.
class AvoidPage extends StatelessWidget {
  const AvoidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'The button below is centred. On a half-open foldable that is the '
            'hinge — FoldAvoid moves it to the nearer side.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.4),
          child: FoldAvoid(
            child: FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.local_taxi),
              label: const Text('Book a ride'),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  const _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

/// Everything fold_kit and MediaQuery know about the window.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fold = FoldInfo.of(context);
    final padding = MediaQuery.paddingOf(context);
    final features = MediaQuery.displayFeaturesOf(context);
    final angle = FoldKitScope.angleOf(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRow('Posture', fold.posture.name),
        _buildRow('Hinge status', FoldKitScope.statusOf(context).name),
        _buildRow('Hinge angle', angle == null ? '—' : '${angle.round()}°'),
        _buildRow('Size class', fold.windowSizeClass.name),
        _buildRow(
          'Window',
          '${fold.windowSize.width.round()} × ${fold.windowSize.height.round()}',
        ),
        _buildRow('Fold axis', fold.axis?.name ?? '—'),
        _buildRow('Fold rect', fold.rect == null ? '—' : _rect(fold.rect!)),
        _buildRow(
          'Safe area',
          'L ${padding.left.round()} · T ${padding.top.round()} · '
              'R ${padding.right.round()} · B ${padding.bottom.round()}',
        ),
        _buildRow(
          'Vertical bars',
          FoldScaffold.isVertical(context, FoldBarPlacement.auto)
              ? 'yes'
              : 'no',
        ),
        const Divider(),
        for (final f in features)
          _buildRow(
            'displayFeature',
            '${f.type.name} · ${f.state.name} · ${_rect(f.bounds)}',
          ),
        if (features.isEmpty) _buildRow('displayFeatures', 'none'),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return ListTile(dense: true, title: Text(label), trailing: Text(value));
  }

  String _rect(Rect r) =>
      'x ${r.left.round()}, y ${r.top.round()}, '
      '${r.width.round()}×${r.height.round()}';
}
