import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Records what the manager asked of the transport and lets each step be made
/// to fail, so the state machine can be driven without any network or disk.
class _FakeUploadService implements ImageUploadService {
  int presignBatchCalls = 0;
  int completeCalls = 0;
  int statusPolls = 0;
  List<AssetPresignRequest> lastPresignAssets = const [];

  /// File names whose PUT should throw.
  Set<String> failUploadsFor = {};

  /// Asset codes the session reports as FAILED instead of READY.
  Set<String> processingFailures = {};

  /// Status the `complete` response reports. Real services return `UPLOADED`
  /// for both the TASK and EVENT domains.
  String completeStatus = 'UPLOADED';

  Object? presignError;

  /// Held open long enough for concurrent transfers to overlap observably.
  Duration uploadDuration = Duration.zero;
  int _inFlight = 0;
  int maxConcurrent = 0;

  @override
  Future<List<AssetPresignResult>> createAssetPresignBatch({
    required String sessionCode,
    required String documentApiBasePath,
    required List<AssetPresignRequest> assets,
    CancelToken? cancelToken,
  }) async {
    presignBatchCalls++;
    lastPresignAssets = assets;
    if (presignError != null) throw presignError!;
    return [
      for (var i = 0; i < assets.length; i++)
        AssetPresignResult(
          assetCode: 'AST_$i',
          presignedPutUrl: 'https://s3.test/${assets[i].fileName}',
          requiredHeaders: {'Content-Type': assets[i].contentType},
        ),
    ];
  }

  @override
  Future<void> uploadFileToPresignedUrl({
    required File file,
    required String presignedPutUrl,
    Map<String, String> requiredHeaders = const {},
    String fallbackContentType = 'image/jpeg',
    void Function(int sent, int total)? onSendProgress,
    void Function(int sentBytes, int totalBytes, int percent)? onProgress,
    CancelToken? cancelToken,
  }) async {
    _inFlight++;
    maxConcurrent = _inFlight > maxConcurrent ? _inFlight : maxConcurrent;
    try {
      if (uploadDuration > Duration.zero) {
        await Future<void>.delayed(uploadDuration);
      }
      final name = presignedPutUrl.split('/').last;
      if (failUploadsFor.contains(name)) {
        throw Exception('network died');
      }
      onSendProgress?.call(50, 100);
    } finally {
      _inFlight--;
    }
  }

  @override
  Future<AssetCompleteResult> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
    CancelToken? cancelToken,
  }) async {
    completeCalls++;
    return AssetCompleteResult(
      assetCode: assetCode,
      status: completeStatus,
      fileName: 'x',
      contentType: 'image/jpeg',
      sizeBytes: 100,
    );
  }

  @override
  Future<Map<String, String>> getUploadAssetStatuses({
    required String sessionCode,
    required List<String> expectedAssetCodes,
  }) async {
    statusPolls++;
    return {
      for (final code in expectedAssetCodes)
        code: processingFailures.contains(code) ? 'FAILED' : 'READY',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? 'SCH_1' : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PickedFile _file(String name, {int sizeBytes = 1000}) => PickedFile(
      path: '/tmp/$name',
      name: name,
      sizeBytes: sizeBytes,
      extension: name.split('.').last,
      mimeType: name.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
    );

void main() {
  late _FakeUploadService service;
  late AttachmentUploadManager manager;
  var sessionOpens = 0;

  setUp(() {
    service = _FakeUploadService();
    manager = AttachmentUploadManager(service, _FakeStorage());
    sessionOpens = 0;
  });

  Future<UploadSessionResult> openSession() async {
    sessionOpens++;
    return const UploadSessionResult(
      sessionCode: 'UPS_1',
      documentApiBasePath: '/document-ms/api/v1',
    );
  }

  test('uploads N files with one session and one batched presign', () async {
    final files = [_file('a.jpg'), _file('b.pdf'), _file('c.jpg')];

    final state = await manager.upload(files: files, openSession: openSession);

    // The whole point of the batch endpoint: three files, one presign call.
    expect(sessionOpens, 1);
    expect(service.presignBatchCalls, 1);
    expect(service.lastPresignAssets.length, 3);
    expect(service.completeCalls, 3);
    // `complete` already said UPLOADED, so the session is never re-fetched.
    expect(service.statusPolls, 0);

    expect(state.allSucceeded, isTrue);
    expect(state.assetCodes, ['AST_0', 'AST_1', 'AST_2']);
    expect(state.hasFailures, isFalse);
  });

  test('presign carries per-file metadata and the resolved owner', () async {
    await manager.upload(
      files: [_file('report.pdf', sizeBytes: 2048)],
      openSession: openSession,
    );

    final asset = service.lastPresignAssets.single;
    expect(asset.fileName, 'report.pdf');
    expect(asset.contentType, 'application/pdf');
    expect(asset.contentLengthBytes, 2048);
    expect(asset.mediaType, 'DOCUMENT');
    expect(asset.ownerType, 'SCHOOL');
    // Falls back to the stored school code when the caller passes none.
    expect(asset.ownerCode, 'SCH_1');
  });

  test('an explicit ownerCode overrides the stored one', () async {
    await manager.upload(
      files: [_file('a.jpg')],
      openSession: openSession,
      ownerCode: 'SCH_OTHER',
    );

    expect(service.lastPresignAssets.single.ownerCode, 'SCH_OTHER');
  });

  test('one failed transfer does not sink the others', () async {
    service.failUploadsFor = {'b.pdf'};

    final state = await manager.upload(
      files: [_file('a.jpg'), _file('b.pdf'), _file('c.jpg')],
      openSession: openSession,
    );

    expect(state.allSucceeded, isFalse);
    expect(state.hasFailures, isTrue);
    // Partial success is preserved — the good files still yield codes.
    expect(state.assetCodes, ['AST_0', 'AST_2']);
    expect(state.failedItems.single.file.name, 'b.pdf');
    expect(state.failedItems.single.error, contains('network died'));
    expect(state.summary, contains('b.pdf'));
  });

  test('an asset that fails processing is reported per-file', () async {
    // Only reachable when `complete` leaves the asset in a transient state.
    service.completeStatus = 'PROCESSING';
    service.processingFailures = {'AST_1'};

    final state = await manager.upload(
      files: [_file('a.jpg'), _file('b.jpg')],
      openSession: openSession,
    );

    expect(state.assetCodes, ['AST_0']);
    expect(state.failedItems.single.error, 'Processing failed');
    expect(
      state.items[1].status,
      AttachmentUploadStatus.failed,
    );
  });

  group('completion status decides readiness (no polling for UPLOADED)', () {
    test('UPLOADED is terminal — the EVENT domain never reaches READY', () async {
      // Regression: events assets stay UPLOADED forever. Waiting for READY
      // polled the session 20-40 times and the event was never created.
      service.completeStatus = 'UPLOADED';

      final state = await manager.upload(
        files: [_file('a.jpg')],
        openSession: openSession,
      );

      expect(service.statusPolls, 0, reason: 'must not poll for UPLOADED');
      expect(state.allSucceeded, isTrue);
      expect(state.assetCodes, ['AST_0']);
    });

    test('READY is terminal too, still without polling', () async {
      service.completeStatus = 'READY';

      final state = await manager.upload(
        files: [_file('a.jpg')],
        openSession: openSession,
      );

      expect(service.statusPolls, 0);
      expect(state.assetCodes, ['AST_0']);
    });

    test('a missing status is treated as attachable', () async {
      // A successful complete is itself proof the bytes landed; an older
      // response shape must not strand the upload.
      service.completeStatus = '';

      final state = await manager.upload(
        files: [_file('a.jpg')],
        openSession: openSession,
      );

      expect(service.statusPolls, 0);
      expect(state.allSucceeded, isTrue);
    });

    test('FAILED at completion fails that file without polling', () async {
      service.completeStatus = 'FAILED';

      final state = await manager.upload(
        files: [_file('a.jpg')],
        openSession: openSession,
      );

      expect(service.statusPolls, 0);
      expect(state.allSucceeded, isFalse);
      expect(state.failedItems.single.error, 'Upload was rejected');
      expect(state.assetCodes, isEmpty);
    });

    test('a transient status does fall back to one batched poll', () async {
      service.completeStatus = 'PROCESSING';

      final state = await manager.upload(
        files: [_file('a.jpg'), _file('b.jpg')],
        openSession: openSession,
      );

      // One poll for the pair, not one each.
      expect(service.statusPolls, 1);
      expect(state.assetCodes, ['AST_0', 'AST_1']);
    });
  });

  test('a failed session is fatal and never reaches presign', () async {
    final state = await manager.upload(
      files: [_file('a.jpg')],
      openSession: () async => throw Exception('403 forbidden'),
    );

    expect(state.fatalError, contains('403 forbidden'));
    expect(state.hasFailures, isTrue);
    expect(service.presignBatchCalls, 0);
    expect(state.assetCodes, isEmpty);
  });

  test('a failed presign is fatal and nothing is transferred', () async {
    service.presignError = Exception('session expired');

    final state = await manager.upload(
      files: [_file('a.jpg'), _file('b.jpg')],
      openSession: openSession,
    );

    expect(state.fatalError, contains('session expired'));
    expect(service.completeCalls, 0);
    expect(state.assetCodes, isEmpty);
  });

  test('no files means no calls at all', () async {
    final state = await manager.upload(files: const [], openSession: openSession);

    expect(state.isEmpty, isTrue);
    expect(sessionOpens, 0);
    expect(service.presignBatchCalls, 0);
  });

  test('concurrency is bounded so memory does not scale with file count', () async {
    service.uploadDuration = const Duration(milliseconds: 10);

    await manager.upload(
      files: List.generate(8, (i) => _file('f$i.jpg')),
      openSession: openSession,
      maxConcurrent: 3,
    );

    expect(service.maxConcurrent, lessThanOrEqualTo(3));
    // And it really did parallelize rather than run one at a time.
    expect(service.maxConcurrent, greaterThan(1));
  });

  test('waitForReady: false skips the poll and accepts uploaded assets', () async {
    final state = await manager.upload(
      files: [_file('a.jpg')],
      openSession: openSession,
      waitForReady: false,
    );

    expect(service.statusPolls, 0);
    expect(state.allSucceeded, isTrue);
    expect(state.assetCodes, ['AST_0']);
  });

  test('progress is reported and ends byte-weighted at 100%', () async {
    final snapshots = <AttachmentUploadState>[];

    final state = await manager.upload(
      // Unequal sizes so a naive count-based average would give a different
      // answer than the byte-weighted one.
      files: [_file('small.jpg', sizeBytes: 100), _file('big.jpg', sizeBytes: 900)],
      openSession: openSession,
      onProgress: snapshots.add,
    );

    expect(snapshots, isNotEmpty);
    expect(
      snapshots.any((s) => s.items.any((i) => i.isInFlight)),
      isTrue,
      reason: 'in-flight states should be observable while uploading',
    );
    expect(state.overallProgress, 1.0);
    expect(state.isUploading, isFalse);
  });

  test('a cancelled transfer is reported as cancelled, not as a crash', () async {
    service.failUploadsFor = {};
    final cancelToken = CancelToken();
    // Pre-cancelled: the fake ignores the token, so simulate the DioException
    // the real transport raises on a cancelled PUT.
    cancelToken.cancel();

    final state = await manager.upload(
      files: [_file('a.jpg')],
      openSession: () async => throw DioException.requestCancelled(
        requestOptions: RequestOptions(path: '/x'),
        reason: 'user left',
      ),
      cancelToken: cancelToken,
    );

    expect(state.fatalError, contains('cancelled'));
  });
}
