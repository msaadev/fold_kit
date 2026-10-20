
import 'fold_kit_platform_interface.dart';

class FoldKit {
  Future<String?> getPlatformVersion() {
    return FoldKitPlatform.instance.getPlatformVersion();
  }
}
