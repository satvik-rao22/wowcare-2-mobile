import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// MainActivity registers plugins from a hand-kept list instead of Flutter's
/// GeneratedPluginRegistrant (so FFmpegKit's native-init Error can't abort the
/// rest). A plugin missing from that list is never registered, and every call
/// into it throws MissingPluginException at runtime — e.g. sqflite missing made
/// every cached network image load hang forever. This keeps the list honest.
const _generated =
    'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java';
const _mainActivity =
    'android/app/src/main/kotlin/com/example/wowcare/MainActivity.kt';

void main() {
  test(
    'MainActivity.PLUGIN_CLASS_NAMES covers every generated plugin',
    () {
      final expected = RegExp(r'add\(new ([\w.]+)\(\)\)')
          .allMatches(File(_generated).readAsStringSync())
          .map((m) => m[1]!)
          .toSet();
      final listed = RegExp(r'^\s*"([\w.]+)",\s*$', multiLine: true)
          .allMatches(File(_mainActivity).readAsStringSync())
          .map((m) => m[1]!)
          .toSet();

      expect(expected, isNotEmpty, reason: 'Could not parse $_generated');
      final missing = expected.difference(listed).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason:
            'Add to PLUGIN_CLASS_NAMES in $_mainActivity, or these plugins are '
            'never registered on Android:\n${missing.join('\n')}',
      );
    },
    skip: File(_generated).existsSync()
        ? false
        : 'Run `flutter pub get` to generate $_generated',
  );
}
