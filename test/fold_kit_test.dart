import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';
import 'package:fold_kit/fold_kit_platform_interface.dart';
import 'package:fold_kit/fold_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFoldKitPlatform
    with MockPlatformInterfaceMixin
    implements FoldKitPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FoldKitPlatform initialPlatform = FoldKitPlatform.instance;

  test('$MethodChannelFoldKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFoldKit>());
  });

  test('getPlatformVersion', () async {
    FoldKit foldKitPlugin = FoldKit();
    MockFoldKitPlatform fakePlatform = MockFoldKitPlatform();
    FoldKitPlatform.instance = fakePlatform;

    expect(await foldKitPlugin.getPlatformVersion(), '42');
  });
}
