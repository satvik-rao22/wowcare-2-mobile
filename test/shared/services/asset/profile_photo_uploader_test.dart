import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/asset/asset_models.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';
import 'package:wowcare/shared/services/asset/profile_photo_uploader.dart';

/// Records every server call the uploader makes instead of sending it.
class _RecordingService extends AssetService {
  _RecordingService() : super(ApiClient(baseUrl: 'https://example.invalid'));

  final calls = <String>[];
  UploadSessionResult? uploadedSession;
  AssetOwner? uploadedOwner;
  String? uploadedName;
  String? uploadedType;

  @override
  Future<String> createStaffProfilePhotoUploadSession({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    calls.add('session:staff:$staffCode:$schoolCode:$organizationCode');
    return 'SESS';
  }

  @override
  Future<String> createStudentProfilePhotoUploadSession({
    required String studentCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    calls.add('session:student:$studentCode:$schoolCode:$organizationCode');
    return 'SESS';
  }

  @override
  Future<String> createGuardianProfilePhotoUploadSession({
    required String guardianCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    calls.add('session:guardian:$guardianCode:$schoolCode:$organizationCode');
    return 'SESS';
  }

  @override
  Future<UploadedAsset> uploadToSession({
    required UploadSessionResult session,
    required File file,
    required AssetOwner owner,
    String? fileName,
    String? contentType,
    bool waitUntilReady = true,
    void Function(int percent)? onUploadProgress,
    CancelToken? cancelToken,
  }) async {
    calls.add('upload');
    uploadedSession = session;
    uploadedOwner = owner;
    uploadedName = fileName;
    uploadedType = contentType;
    onUploadProgress?.call(0);
    onUploadProgress?.call(100);
    return const UploadedAsset(assetCode: 'ASSET1');
  }

  @override
  Future<String> finalizeStaffProfilePhoto({
    required String staffCode,
    required String assetCode,
  }) async {
    calls.add('finalize:staff:$staffCode:$assetCode');
    return 'https://cdn/staff.jpg';
  }

  @override
  Future<String> finalizeStudentProfilePhoto({
    required String studentCode,
    required String sessionCode,
    required String assetCode,
    required String schoolCode,
  }) async {
    calls.add(
      'finalize:student:$studentCode:$sessionCode:$assetCode:$schoolCode',
    );
    return 'https://cdn/student.jpg';
  }

  @override
  Future<String> finalizeGuardianProfilePhoto({
    required String guardianCode,
    required String assetCode,
    required String schoolCode,
    required String userCode,
  }) async {
    calls.add(
      'finalize:guardian:$guardianCode:$assetCode:$schoolCode:$userCode',
    );
    return 'https://cdn/guardian.jpg';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File photo;
  late _RecordingService service;
  late ProfilePhotoUploader uploader;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('photo_');
    photo = File('${dir.path}/IMG_1.PNG');
    await photo.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    service = _RecordingService();
    uploader = ProfilePhotoUploader(service);
  });
  tearDown(() => dir.delete(recursive: true));

  test('staff: session → upload → finalize, returns code and URL', () async {
    final result = await uploader.uploadStaffPhoto(
      staffCode: 'STF1',
      file: photo,
      schoolCode: 'SCH',
      organizationCode: 'ORG',
    );

    expect(service.calls, [
      'session:staff:STF1:SCH:ORG',
      'upload',
      'finalize:staff:STF1:ASSET1',
    ]);
    expect(result.assetCode, 'ASSET1');
    expect(result.url, 'https://cdn/staff.jpg');
    expect(service.uploadedOwner?.type, 'STAFF');
    expect(service.uploadedOwner?.code, 'STF1');
  });

  test('student: finalize gets the session and school', () async {
    final result = await uploader.uploadStudentPhoto(
      studentCode: 'STU1',
      file: photo,
      schoolCode: 'SCH',
      organizationCode: 'ORG',
    );

    expect(service.calls.last, 'finalize:student:STU1:SESS:ASSET1:SCH');
    expect(service.uploadedOwner?.type, 'STUDENT');
    expect(result.url, 'https://cdn/student.jpg');
  });

  test(
    'guardian: finalize gets the school and user, code is returned',
    () async {
      final result = await uploader.uploadGuardianPhoto(
        guardianCode: 'GRD1',
        file: photo,
        schoolCode: 'SCH',
        organizationCode: 'ORG',
        userCode: 'USR1',
      );

      expect(service.calls.last, 'finalize:guardian:GRD1:ASSET1:SCH:USR1');
      expect(service.uploadedOwner?.type, 'GUARDIAN');
      expect(result.assetCode, 'ASSET1');
    },
  );

  test(
    'uploads under /api/v1 with the lowercase name and the real type',
    () async {
      await uploader.uploadStaffPhoto(
        staffCode: 'STF1',
        file: photo,
        schoolCode: 'SCH',
        organizationCode: 'ORG',
      );

      expect(service.uploadedSession?.sessionCode, 'SESS');
      expect(service.uploadedSession?.documentApiBasePath, '/api/v1');
      expect(service.uploadedName, 'img_1.png');
      expect(service.uploadedType, 'image/png'); // from the bytes
    },
  );

  test('progress: 5 → 15 → 25…80 → 100', () async {
    final progress = <int>[];
    await uploader.uploadStaffPhoto(
      staffCode: 'STF1',
      file: photo,
      schoolCode: 'SCH',
      organizationCode: 'ORG',
      onPercent: progress.add,
    );

    expect(progress, [5, 15, 25, 80, 100]);
  });
}
