import 'dart:io';

/// One problem found by [auditProject].
class AuditFinding {
  /// File path relative to the project.
  final String path;

  /// 1-based line, or 0 for the whole file.
  final int line;

  /// What to change.
  final String message;

  /// Creates a finding.
  const AuditFinding(this.path, this.line, this.message);

  @override
  String toString() => line > 0 ? '$path:$line  $message' : '$path  $message';
}

const _dartRules = <(Pattern, String)>[
  (
    'MediaQuery.of(context).size',
    'Use MediaQuery.sizeOf(context): the window size, and fewer rebuilds.',
  ),
  (
    'setPreferredOrientations',
    'Orientation locks are ignored on iPhone Duo (inner display) and on Android 16+ large screens. Make the layout work in both orientations.',
  ),
  (
    'OrientationBuilder',
    'Branch on window width (FoldInfo.windowSizeClass), not orientation: an open foldable is almost square.',
  ),
  (
    'AppLifecycleState.inactive',
    'In Split View the app is inactive but still visible. Pause work on paused, not inactive.',
  ),
];

final _regexRules = <(RegExp, String)>[
  (
    RegExp(r'\.horizontal\s*/\s*2'),
    'Left and right insets differ on iPhone Duo (status strip on the right). Use left and right separately.',
  ),
  (
    RegExp(r'EdgeInsets\.symmetric\(\s*horizontal:\s*MediaQuery'),
    'Left and right insets differ on iPhone Duo. Use EdgeInsets.only with paddingOf(context).left / .right.',
  ),
  (
    RegExp(r'\bis(Tablet|Ipad|IPad|Foldable)\b'),
    'Avoid device-type checks; decide on window size (FoldInfo.windowSizeClass) so Split View and foldables work.',
  ),
];

/// Scans a Flutter project for code and settings that break on foldables,
/// tablets and in Split View.
List<AuditFinding> auditProject(Directory root) {
  final findings = <AuditFinding>[];
  String rel(File f) => f.path.substring(root.path.length + 1);

  final lib = Directory('${root.path}/lib');
  if (lib.existsSync()) {
    final files =
        lib
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final (pattern, message) in _dartRules) {
          if (line.contains(pattern)) {
            findings.add(AuditFinding(rel(file), i + 1, message));
          }
        }
        for (final (regex, message) in _regexRules) {
          if (regex.hasMatch(line)) {
            findings.add(AuditFinding(rel(file), i + 1, message));
          }
        }
      }
    }
  }

  final plist = File('${root.path}/ios/Runner/Info.plist');
  if (plist.existsSync() &&
      plist.readAsStringSync().contains('UIRequiresFullScreen')) {
    findings.add(
      AuditFinding(
        rel(plist),
        0,
        'Remove UIRequiresFullScreen: it letterboxes the app on iPhone Duo and blocks Split View on iPad.',
      ),
    );
  }
  final manifest = File(
    '${root.path}/android/app/src/main/AndroidManifest.xml',
  );
  if (manifest.existsSync()) {
    final xml = manifest.readAsStringSync();
    if (xml.contains('android:screenOrientation')) {
      findings.add(
        AuditFinding(
          rel(manifest),
          0,
          'android:screenOrientation is ignored on large screens from Android 16; design for both orientations.',
        ),
      );
    }
    if (xml.contains('resizeableActivity="false"')) {
      findings.add(
        AuditFinding(
          rel(manifest),
          0,
          'resizeableActivity="false" is ignored on large screens from Android 16 and blocks multi-window.',
        ),
      );
    }
  }
  return findings;
}
