import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fold_kit/src/audit.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('fold_kit_audit');
    File('${root.path}/lib/home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
final w = MediaQuery.of(context).size.width;
// MediaQuery.of(context).size in a comment is fine
final pad = MediaQuery.paddingOf(context).horizontal / 2;
if (isTablet) {}
''');
    File('${root.path}/ios/Runner/Info.plist')
      ..createSync(recursive: true)
      ..writeAsStringSync('<key>UIRequiresFullScreen</key><true/>');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('finds layout code and settings that break on foldables', () {
    final findings = auditProject(root);
    expect(findings.map((f) => '${f.path}:${f.line}'), [
      'lib/home.dart:1',
      'lib/home.dart:3',
      'lib/home.dart:4',
      'ios/Runner/Info.plist:0',
    ]);
  });
}
