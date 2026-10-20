import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/fold_kit.dart';

void main() {
  test('a refreshed copy of a device equals the snapshot one', () {
    final copy = FoldDevices.parse(
      '{"schemaVersion":1,"devices":[{"id":"iphone-duo","name":"iPhone Duo",'
      '"form":"book","inner":{"width":800,"height":600}}]}',
    )!.first;
    final original = FoldDevices.byId('iphone-duo')!;
    expect(copy, original);
    expect(copy.hashCode, original.hashCode);
    expect({copy, original}, hasLength(1));
  });
}
