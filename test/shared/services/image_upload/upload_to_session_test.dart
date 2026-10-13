import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// The real [ImageUploadService.uploadToSession], with each server step
/// recorded instead of sent.
class _RecordingService extends ImageUploadService {
  _RecordingService() : super(ApiClient(baseUrl: 'https://example.invalid'));

  final steps = <String>[];
  Map<String, Object?> presign = {};
  String? completeBasePath;

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
    dynamic cancelToken,
  }) async {
    steps.add('presign');
    presign = {
      'session': sessionCode,
      'basePath': documentApiBasePath,
      'fileName': fileName,
      'contentType': contentType,
      'length': contentLengthBytes,
      'mediaType': mediaType,
      'ownerType': ownerType,
      'ownerCode': ownerCode,
    };
    return const AssetPresignResult(
      assetCode: 'ASSET1',
      presignedPutUrl: 'https://s3.example/put',
      requiredHeaders: {'x-amz-acl': 'private'},
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
    dynamic cancelToken,
  }) async {
    steps.add('put');
    onProgress?.call(50, 100, 50);
    onProgress?.call(100, 100, 120); // clamped to 100
  }

  @override
  Future<void> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
    dynamic cancelToken,
  }) async {
    steps.add('complete');
    completeBasePath = documentApiBasePath;
  }

  @override
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> expectedAssetCodes,
    Duration pollEvery = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    steps.add('wait:${expectedAssetCodes.join(',')}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File pdf;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('upload_');
    pdf = File('${dir.path}/Report.pdf');
    await pdf.writeAsBytes('%PDF-1.7 test'.codeUnits);
  });
  tearDown(() => dir.delete(recursive: true));

  const session = UploadSessionResult(
    sessionCode: 'SESS',
    documentApiBasePath: '/api/v2',
  );

  test('presign → PUT → complete → wait, in that order', () async {
    final service = _RecordingService();
    final asset = await service.uploadToSession(
      session: session,
      file: pdf,
      owner: const AssetOwner.staff('STF1'),
    );

    expect(service.steps, ['presign', 'put', 'complete', 'wait:ASSET1']);
    expect(asset.assetCode, 'ASSET1');
  });

  test('sends the owner, the real type and the matching media type', () async {
    final service = _RecordingService();
    await service.uploadToSession(
      session: session,
      file: pdf,
      owner: const AssetOwner.classroom('CLS1'),
    );

    expect(service.presign, {
      'session': 'SESS',
      'basePath': '/api/v2',
      'fileName': 'Report.pdf',
      'contentType': 'application/pdf', // read from the bytes
      'length': await pdf.length(),
      'mediaType': 'DOCUMENT',
      'ownerType': 'CLASSROOM',
      'ownerCode': 'CLS1',
    });
  });

  test('explicit file name and type win; image type → IMAGE', () async {
    final service = _RecordingService();
    await service.uploadToSession(
      session: session,
      file: pdf,
      owner: const AssetOwner.school('SCH1'),
      fileName: 'logo.png',
      contentType: 'image/png',
    );

    expect(service.presign['fileName'], 'logo.png');
    expect(service.presign['contentType'], 'image/png');
    expect(service.presign['mediaType'], 'IMAGE');
  });

  test('waitUntilReady: false skips the wait', () async {
    final service = _RecordingService();
    await service.uploadToSession(
      session: session,
      file: pdf,
      owner: const AssetOwner.school('SCH1'),
      waitUntilReady: false,
    );

    expect(service.steps, ['presign', 'put', 'complete']);
  });

  test('an empty base path falls back to /api/v1', () async {
    final service = _RecordingService();
    await service.uploadToSession(
      session: const UploadSessionResult(
        sessionCode: 'SESS',
        documentApiBasePath: '',
      ),
      file: pdf,
      owner: const AssetOwner.student('STU1'),
    );

    expect(service.presign['basePath'], '/api/v1');
    expect(service.completeBasePath, '/api/v1');
  });

  test('reports the PUT progress, clamped to 0–100', () async {
    final progress = <int>[];
    await _RecordingService().uploadToSession(
      session: session,
      file: pdf,
      owner: const AssetOwner.staff('STF1'),
      onUploadProgress: progress.add,
    );

    expect(progress, [50, 100]);
  });

  test('AssetOwner carries the server owner types', () {
    expect(const AssetOwner.staff('a').type, 'STAFF');
    expect(const AssetOwner.student('a').type, 'STUDENT');
    expect(const AssetOwner.guardian('a').type, 'GUARDIAN');
    expect(const AssetOwner.classroom('a').type, 'CLASSROOM');
    expect(const AssetOwner.school('a').type, 'SCHOOL');
  });
}
