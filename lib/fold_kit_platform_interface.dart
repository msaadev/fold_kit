import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fold_kit_method_channel.dart';

abstract class FoldKitPlatform extends PlatformInterface {
  /// Constructs a FoldKitPlatform.
  FoldKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FoldKitPlatform _instance = MethodChannelFoldKit();

  /// The default instance of [FoldKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFoldKit].
  static FoldKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FoldKitPlatform] when
  /// they register themselves.
  static set instance(FoldKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
