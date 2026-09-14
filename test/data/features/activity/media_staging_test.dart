import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wowcare/data/features/activity/datasources/media_staging_local_datasource.dart';
import 'package:wowcare/domain/features/activity/entities/staged_media.dart';

/// Points getApplicationDocumentsDirectory() at a real temp dir so the
/// datasource does genuine filesystem work.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.docsPath);
  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

void main() {
  late Directory root;
  late Directory docs;
  late Directory cache;
  late FileMediaStagingLocalDataSource sut;

  String stagingDirPath() =>
      '${docs.path}${Platform.pathSeparator}pending_media_uploads';

  setUp(() async {
    root = await Directory.systemTemp.createTemp('staging_test');
    docs = Directory('${root.path}/docs')..createSync(recursive: true);
    cache = Directory('${root.path}/cache')..createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(docs.path);
    sut = FileMediaStagingLocalDataSource();
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File writeCacheFile(String name, List<int> bytes) {
    final f = File('${cache.path}${Platform.pathSeparator}$name');
    f.writeAsBytesSync(bytes);
    return f;
  }

  group('stage', () {
    test(
      'COPIES rather than moves — the source can be a read-only content:// URI '
      'the app does not own, and the picker may still hold a reference to it',
      () async {
        final source = writeCacheFile('REC_1.mp4', List<int>.filled(2048, 7));

        final staged = await sut.stage(source.path);

        expect(source.existsSync(), isTrue, reason: 'source must survive');
        expect(File(staged.path).existsSync(), isTrue);
        expect(File(staged.path).readAsBytesSync().length, 2048);
        expect(staged.sizeBytes, 2048);
      },
    );

    test('lands inside the dedicated staging directory, not loose in docs', () async {
      final source = writeCacheFile('REC_1.mp4', <int>[1, 2, 3]);
      final staged = await sut.stage(source.path);
      expect(staged.path.startsWith(stagingDirPath()), isTrue);
    });

    test('preserves the original extension', () async {
      for (final ext in <String>['mp4', 'mov', 'webm', 'jpg']) {
        final source = writeCacheFile('clip.$ext', <int>[1]);
        final staged = await sut.stage(source.path);
        expect(staged.path.endsWith('.$ext'), isTrue, reason: ext);
      }
    });

    test(
      'normalises an unrecognised extension to .bin rather than echoing it — '
      'the source name is user-controlled text',
      () async {
        final source = writeCacheFile('weird.PleaseRunMe', <int>[1]);
        final staged = await sut.stage(source.path);
        expect(staged.path.endsWith('.bin'), isTrue);
        expect(staged.path.toLowerCase(), isNot(contains('pleaserunme')));
      },
    );

    test(
      'is collision-proof: staging the SAME source name many times produces '
      'distinct files, so one capture can never overwrite another',
      () async {
        final paths = <String>{};
        for (var i = 0; i < 50; i++) {
          final source = writeCacheFile('REC.mp4', <int>[i]);
          paths.add((await sut.stage(source.path)).path);
        }
        expect(paths.length, 50);
        expect(Directory(stagingDirPath()).listSync().length, 50);
      },
    );

    test('does not leak the original filename into the staged name', () async {
      final source = writeCacheFile('Emma_Watson_birthday.mp4', <int>[1]);
      final staged = await sut.stage(source.path);
      expect(staged.path, isNot(contains('Emma')));
      expect(staged.path, isNot(contains('birthday')));
    });

    test('throws MediaStagingException (ioError) when the source is gone', () async {
      await expectLater(
        sut.stage('${cache.path}${Platform.pathSeparator}nope.mp4'),
        throwsA(
          isA<MediaStagingException>().having(
            (e) => e.failure,
            'failure',
            MediaStagingFailure.ioError,
          ),
        ),
      );
    });
  });

  group('discard', () {
    test('deletes a staged copy', () async {
      final source = writeCacheFile('REC_1.mp4', <int>[1, 2, 3]);
      final staged = await sut.stage(source.path);
      await sut.discard(staged.path);
      expect(File(staged.path).existsSync(), isFalse);
    });

    test(
      'REFUSES to delete anything outside the staging directory — discard() '
      'takes a path, and must not become an arbitrary-delete primitive',
      () async {
        final outsider = writeCacheFile('precious.mp4', <int>[1]);
        await sut.discard(outsider.path);
        expect(
          outsider.existsSync(),
          isTrue,
          reason: 'a cache path must be ignored, not deleted',
        );
      },
    );

    test('is silent when the file is already gone', () async {
      await expectLater(
        sut.discard('${stagingDirPath()}${Platform.pathSeparator}ghost.mp4'),
        completes,
      );
    });
  });

  group('sweepOrphans', () {
    test('deletes files older than maxAge and keeps newer ones', () async {
      final oldStaged = await sut.stage(
        writeCacheFile('old.mp4', <int>[1]).path,
      );
      final freshStaged = await sut.stage(
        writeCacheFile('fresh.mp4', <int>[1]).path,
      );
      File(
        oldStaged.path,
      ).setLastModifiedSync(DateTime.now().subtract(const Duration(days: 8)));

      final deleted = await sut.sweepOrphans(maxAge: const Duration(days: 7));

      expect(deleted, 1);
      expect(File(oldStaged.path).existsSync(), isFalse);
      expect(
        File(freshStaged.path).existsSync(),
        isTrue,
        reason: 'a file still in its 7-day window may be an in-flight upload',
      );
    });

    test('returns 0 on a clean directory', () async {
      expect(await sut.sweepOrphans(maxAge: const Duration(days: 7)), 0);
    });
  });
}
