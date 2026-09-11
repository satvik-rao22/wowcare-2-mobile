import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/activity/datasources/lost_media_local_datasource.dart';
import 'package:wowcare/data/features/activity/repositories/lost_media_repository_impl.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';

/// Hands back whatever the test wants, including a throw.
class _StubDataSource implements LostMediaLocalDataSource {
  _StubDataSource(this._result);
  _StubDataSource.throwing(this._error) : _result = null;

  final RecoveredMedia? _result;
  Object? _error;

  @override
  Future<RecoveredMedia> retrieveLostMedia() async {
    if (_error != null) throw _error!;
    return _result!;
  }
}

void main() {
  group('RecoveredMedia distinguishes all three outcomes', () {
    test('a recovered file is neither "nothing" nor "failed capture"', () {
      const recovered = RecoveredMedia(
        type: RecoveredMediaType.video,
        filePaths: <String>['/cache/REC_1.mp4'],
      );
      expect(recovered.isNotEmpty, isTrue);
      expect(recovered.hasFailedCapture, isFalse);
      expect(recovered.isNothingToRecover, isFalse);
    });

    test(
      'a recovered EXCEPTION is its own outcome — something was pending and is '
      'now claimed and gone, there is just no file to restore',
      () {
        const failed = RecoveredMedia(
          type: RecoveredMediaType.video,
          filePaths: <String>[],
          errorMessage: 'camera died',
        );
        expect(failed.hasFailedCapture, isTrue);
        expect(failed.isNothingToRecover, isFalse);
        expect(failed.isNotEmpty, isFalse);
      },
    );

    test('nothing pending is distinct from a failed capture', () {
      expect(RecoveredMedia.none.isNothingToRecover, isTrue);
      expect(RecoveredMedia.none.hasFailedCapture, isFalse);
    });
  });

  group('LostMediaRepositoryImpl', () {
    test('passes a recovered file straight through', () async {
      const expected = RecoveredMedia(
        type: RecoveredMediaType.video,
        filePaths: <String>['/cache/REC_1.mp4'],
      );
      final repo = LostMediaRepositoryImpl(_StubDataSource(expected));
      final result = await repo.retrieveLostMedia();
      expect(result.filePaths, expected.filePaths);
      expect(result.type, RecoveredMediaType.video);
    });

    test(
      'NEVER throws — a platform failure degrades to "nothing to recover", '
      'because recovery is best-effort and must not break the screen that '
      'asked for it',
      () async {
        final repo = LostMediaRepositoryImpl(
          _StubDataSource.throwing(StateError('channel blew up')),
        );
        // Awaited directly: `returnsNormally` on an async closure only checks
        // the synchronous prefix and would pass even if the future rejected,
        // which is exactly the contract under test.
        await expectLater(repo.retrieveLostMedia(), completes);
        final result = await repo.retrieveLostMedia();
        expect(result.isNothingToRecover, isTrue);
      },
    );
  });
}
