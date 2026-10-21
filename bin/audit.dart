import 'dart:io';

import 'package:fold_kit/src/audit.dart';

/// `dart run fold_kit:audit [path] [--fatal]`
void main(List<String> args) {
  final fatal = args.contains('--fatal');
  final path = args.firstWhere((a) => !a.startsWith('--'), orElse: () => '.');
  final root = Directory(path).absolute;
  final findings = auditProject(root);
  for (final f in findings) {
    stdout.writeln(f);
  }
  stdout.writeln(
    findings.isEmpty
        ? 'fold_kit audit: no problems found.'
        : 'fold_kit audit: ${findings.length} place(s) to check for foldables, tablets and Split View.',
  );
  if (fatal && findings.isNotEmpty) exitCode = 1;
}
