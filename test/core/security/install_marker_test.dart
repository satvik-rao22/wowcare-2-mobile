import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/security/install_marker.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wowcare_marker_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('InstallMarker', () {
    test(
      'is absent until created, then present, and create() is idempotent',
      () async {
        final marker = InstallMarker(directory: () async => tempDir);
        expect(await marker.exists(), isFalse);

        await marker.create();
        expect(await marker.exists(), isTrue);
        final file = File('${tempDir.path}/${InstallMarker.fileName}');
        final firstContents = await file.readAsString();
        expect(firstContents, isNotEmpty);

        await marker.create();
        expect(
          await file.readAsString(),
          firstContents,
          reason: 'a second create() must not rewrite the marker',
        );
      },
    );

    test(
      'creates intermediate directories when the support dir is missing',
      () async {
        final nested = Directory('${tempDir.path}/a/b');
        final marker = InstallMarker(directory: () async => nested);
        await marker.create();
        expect(await marker.exists(), isTrue);
      },
    );
  });
}
