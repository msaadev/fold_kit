import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fold_kit_platform_interface.dart';

/// An implementation of [FoldKitPlatform] that uses method channels.
class MethodChannelFoldKit extends FoldKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fold_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
