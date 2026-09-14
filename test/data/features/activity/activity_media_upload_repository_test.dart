import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/activity/repositories/activity_media_upload_repository_impl.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Captures every call the repository makes so we can assert it opens ONE
/// session and runs presign → PUT → complete for each item, in order.
class _CapturingUploadService implements ImageUploadService {
  int sessionCalls = 0;
  final List<String> calls = <String>[];
  final List<String> presignFileNames = <String>[];
  final List<String> presignMediaTypes = <String>[];
  int _presignSeq = 0;

  @override
  Future<UploadSessionResult> createActivityUploadSession({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
    CancelToken? cancelToken,
  }) async {
    sessionCalls++;
    calls.add('session');
    return const UploadSessionResult(
      sessionCode: 'SESSION-1',
      documentApiBasePath: '/api/v1',
    );
  }

  @override
  Future<String> computeFileChecksumSha256(File file) async => 'checksum';

  @override
  Future<AssetPresignResult> createAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    String? checksumSha256,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
    CancelToken? cancelToken,
  }) async {
    calls.add('presign');
    presignFileNames.add(fileName);
    presignMediaTypes.add(mediaType);
    _presignSeq++;
    return AssetPresignResult(
      assetCode: 'ASSET-$_presignSeq',
      presignedPutUrl: 'https://s3.example/put/$_presignSeq',
      requiredHeaders: const {},
    );
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
    calls.add('put');
    // Emit a progress tick so the bridge is exercised.
    onProgress?.call(1, 1, 100);
  }

  @override
  Future<void> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
    CancelToken? cancelToken,
  }) async {
    calls.add('complete:$assetCode');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

Future<File> _tempFile(String name, String contents) async {
  final dir = await Directory.systemTemp.createTemp('activity_media_upload');
  final f = File('${dir.path}/$name');
  await f.writeAsString(contents);
  return f;
}

void main() {
  test(
    'uploadAssets opens ONE session and runs presign → PUT → complete per item, '
    'returning the path→assetCode map',
    () async {
      final svc = _CapturingUploadService();
      final ActivityMediaUploadRepository repo =
          ActivityMediaUploadRepositoryImpl(svc);

      final fileA = await _tempFile('a.jpg', 'aaa');
      final fileB = await _tempFile('b.jpg', 'bbbb');

      final progress = <int>[];
      final completes = <int>[];

      final result = await repo.uploadAssets(
        organizationCode: 'ORG',
        schoolCode: 'SCH',
        classroomCode: 'CLS',
        activityTypeCode: 'TYPE',
        bindingMode: 'PER_STUDENT',
        studentCodes: const ['STU-1'],
        ownerType: 'STUDENT',
        ownerCode: 'STU-1',
        items: [
          ActivityUploadItem(
            file: fileA,
            fileName: 'a.jpg',
            contentType: 'image/jpeg',
            mediaType: 'IMAGE',
          ),
          ActivityUploadItem(
            file: fileB,
            fileName: 'b.mp4',
            contentType: 'video/mp4',
            mediaType: 'VIDEO',
          ),
        ],
        onItemProgress: (itemIndex, totalItems, percent) =>
            progress.add(percent),
        onItemComplete: (completed, total) => completes.add(completed),
      );

      // Exactly one session for the whole batch.
      expect(svc.sessionCalls, 1);

      // Strict per-item ordering: session, then presign→put→complete twice.
      expect(svc.calls, [
        'session',
        'presign',
        'put',
        'complete:ASSET-1',
        'presign',
        'put',
        'complete:ASSET-2',
      ]);

      // Each item's caller-computed fileName/mediaType flowed through verbatim.
      expect(svc.presignFileNames, ['a.jpg', 'b.mp4']);
      expect(svc.presignMediaTypes, ['IMAGE', 'VIDEO']);

      // Result maps every local path to its new asset code, in item order.
      expect(result.sessionCode, 'SESSION-1');
      expect(result.newAssetCodes, ['ASSET-1', 'ASSET-2']);
      expect(result.assetCodeByPath, {
        fileA.path: 'ASSET-1',
        fileB.path: 'ASSET-2',
      });

      // Progress + completion callbacks bridged for every item.
      expect(progress, [100, 100]);
      expect(completes, [1, 2]);
    },
  );

  test('waitUntilAssetsReady / getUploadAssetStatuses delegate to the service',
      () async {
    final svc = _DelegationSpyService();
    final ActivityMediaUploadRepository repo =
        ActivityMediaUploadRepositoryImpl(svc);

    await repo.waitUntilAssetsReady(
      sessionCode: 'S1',
      assetCodes: const ['A1', 'A2'],
    );
    expect(svc.waitSession, 'S1');
    expect(svc.waitCodes, ['A1', 'A2']);

    final statuses = await repo.getUploadAssetStatuses(
      sessionCode: 'S2',
      assetCodes: const ['A3'],
    );
    expect(svc.statusSession, 'S2');
    expect(svc.statusCodes, ['A3']);
    expect(statuses, {'A3': 'READY'});
  });
}

class _DelegationSpyService implements ImageUploadService {
  String? waitSession;
  List<String>? waitCodes;
  String? statusSession;
  List<String>? statusCodes;

  @override
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> expectedAssetCodes,
    Duration pollEvery = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    waitSession = sessionCode;
    waitCodes = expectedAssetCodes;
  }

  @override
  Future<Map<String, String>> getUploadAssetStatuses({
    required String sessionCode,
    required List<String> expectedAssetCodes,
  }) async {
    statusSession = sessionCode;
    statusCodes = expectedAssetCodes;
    return {for (final c in expectedAssetCodes) c: 'READY'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}
