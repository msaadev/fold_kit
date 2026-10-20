import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

void main() {
  late StreamController<Object?> events;

  setUp(() {
    events = StreamController<Object?>(sync: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          FoldKitScope.channel,
          MockStreamHandler.inline(
            onListen: (_, sink) {
              events.stream.listen(sink.success);
            },
          ),
        );
  });

  // Not awaited: close() never completes on a stream nobody listened to.
  tearDown(() {
    events.close();
  });

  Future<FoldInfo Function()> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late FoldInfo info;
    await tester.pumpWidget(
      FoldKitScope(
        child: Builder(
          builder: (context) {
            info = FoldInfo.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return () => info;
  }

  Map<String, Object?> event(String status) => {
    'status': status,
    'angle': 130.0,
    'model': 'iPhone19,4',
    'folds': [
      {'x': 455.5, 'y': 0.0, 'width': 40.0, 'height': 669.0},
    ],
  };

  // Platform messages complete outside the fake clock, so let them run for real.
  Future<void> send(WidgetTester tester, String status) async {
    await tester.runAsync(() async {
      events.add(event(status));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
  }

  testWidgets('half open iPhone Duo reports the fold', (tester) async {
    final info = await pump(tester);
    await send(tester, 'partiallyOpen');
    expect(info().posture, FoldPosture.halfOpen);
    expect(info().axis, FoldAxis.vertical);
    expect(info().rect, const Rect.fromLTWH(455.5, 0, 40, 669));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('FoldKit.changes streams posture, angle and device', (
    tester,
  ) async {
    final seen = <FoldState>[];
    final sub = FoldKit.changes.listen(seen.add);
    addTearDown(sub.cancel);
    await pump(tester);
    await send(tester, 'partiallyOpen');
    await tester.pump();
    final last = seen.last;
    expect(last.isHalfOpen, isTrue);
    expect(last.angle, 130);
    expect(last.device?.name, 'iPhone Duo');
    expect(FoldKit.current, last);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('flat and closed do not split layouts', (tester) async {
    final info = await pump(tester);
    await send(tester, 'fullyOpen');
    expect(info().hasFold, isFalse);
    expect(info().posture, FoldPosture.flat);

    await send(tester, 'closed');
    expect(info().posture, FoldPosture.closed);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('other platforms pass through', (tester) async {
    late FoldInfo info;
    await tester.pumpWidget(
      FoldKitScope(
        child: Builder(
          builder: (context) {
            info = FoldInfo.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(info.posture, FoldPosture.none);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
