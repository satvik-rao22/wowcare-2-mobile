import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_document_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_document_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_document_cubit.dart';
import 'package:wowcare/shared/services/asset/asset_models.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeAddUseCase extends AddStudentDocumentUseCase {
  _FakeAddUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<Map<String, dynamic>> args = <Map<String, dynamic>>[];
  Either<Failure, String> result = const Right('Document added');

  @override
  Future<Either<Failure, String>> call({
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? assetCode,
    String? uploadedBy,
    String? notes,
  }) async {
    calls++;
    args.add({
      'studentCode': studentCode,
      'name': name,
      'type': type,
      'expiryDate': expiryDate,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'size': size,
      'assetCode': assetCode,
      'uploadedBy': uploadedBy,
      'notes': notes,
    });
    return result;
  }
}

class _FakeUpdateUseCase extends UpdateStudentDocumentUseCase {
  _FakeUpdateUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<Map<String, dynamic>> args = <Map<String, dynamic>>[];
  Either<Failure, String> result = const Right('Document updated');

  @override
  Future<Either<Failure, String>> call({
    required String documentUuid,
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? assetCode,
    String? uploadedBy,
    String? notes,
  }) async {
    calls++;
    args.add({
      'documentUuid': documentUuid,
      'storagePath': storagePath,
      'size': size,
      'assetCode': assetCode,
    });
    return result;
  }
}

class _FakeStorage implements StorageService {
  final Map<String, String?> values = <String, String?>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeUploadService implements AssetService {
  Object? sessionError;
  Object? putError;
  int progressTo = 0;
  String assetUrl = '';
  int completeCalls = 0;
  int waitReadyCalls = 0;

  @override
  Future<UploadSessionResult> createStudentDocumentUploadSession({
    required String studentCode,
    required String schoolCode,
    required String organizationCode,
  }) async {
    if (sessionError != null) throw sessionError!;
    return const UploadSessionResult(
      sessionCode: 'SESS',
      documentApiBasePath: '/base',
    );
  }

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
    return const AssetPresignResult(
      assetCode: 'ASSET1',
      presignedPutUrl: 'https://put',
      requiredHeaders: <String, String>{},
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
    if (putError != null) throw putError!;
    if (progressTo > 0) onProgress?.call(progressTo, 100, progressTo);
  }

  @override
  Future<AssetCompleteResult> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
    dynamic cancelToken,
  }) async {
    completeCalls++;
    return AssetCompleteResult(assetCode: assetCode, status: 'UPLOADED');
  }

  @override
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> expectedAssetCodes,
    Duration pollEvery = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    waitReadyCalls++;
  }

  /// The whole upload in one call, as the cubit now uses it: the same
  /// switches and counters as the step-by-step fakes above.
  @override
  Future<UploadedAsset> uploadToSession({
    required UploadSessionResult session,
    required File file,
    required AssetOwner owner,
    String? fileName,
    String? contentType,
    bool waitUntilReady = true,
    void Function(int percent)? onUploadProgress,
    dynamic cancelToken,
  }) async {
    lastOwner = owner;
    if (putError != null) throw putError!;
    if (progressTo > 0) onUploadProgress?.call(progressTo);
    completeCalls++;
    if (waitUntilReady) waitReadyCalls++;
    return const UploadedAsset(assetCode: 'ASSET1');
  }

  AssetOwner? lastOwner;

  @override
  Future<String> getMediaAssetUrlByCode({required String assetCode}) async =>
      assetUrl;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _Fakes {
  final add = _FakeAddUseCase();
  final update = _FakeUpdateUseCase();
  final storage = _FakeStorage();
  final upload = _FakeUploadService();

  StudentDocumentCubit build() => StudentDocumentCubit(
        addStudentDocumentUseCase: add,
        updateStudentDocumentUseCase: update,
        assetService: upload,
        storageService: storage,
      );
}

void main() {
  late File tempFile;

  setUp(() async {
    tempFile = File(
      '${Directory.systemTemp.path}/doc_test_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    await tempFile.writeAsString('hello');
  });

  tearDown(() async {
    if (await tempFile.exists()) await tempFile.delete();
  });

  PickedFile pickedFile() => PickedFile(
    name: 'report.pdf',
    size: 5,
    path: tempFile.path,
    mimeType: 'application/pdf',
  );

  void seedSchool(_Fakes fakes) {
    fakes.storage.values[StorageKeys.schoolCode] = 'SCH';
    fakes.storage.values[StorageKeys.organizationCode] = 'ORG';
  }

  group('form model', () {
    test('setDocumentType / setExpiryDate update state', () {
      final cubit = _Fakes().build();
      cubit.setDocumentType('Health Forms');
      cubit.setExpiryDate(DateTime(2027, 1, 1));
      expect(cubit.state.documentType, 'Health Forms');
      expect(cubit.state.expiryDate, DateTime(2027, 1, 1));
    });

    test('initializeForEdit seeds type/expiry/asset', () {
      final cubit = _Fakes().build()
        ..initializeForEdit(
          documentType: 'Other',
          expiryDate: DateTime(2027, 5, 5),
          assetCode: 'A9',
        );
      expect(cubit.state.documentType, 'Other');
      expect(cubit.state.expiryDate, DateTime(2027, 5, 5));
      expect(cubit.state.uploadedAssetCode, 'A9');
    });
  });

  group('uploadFile', () {
    test('happy path: uploading → uploaded with asset code + progress + bg url',
        () async {
      final fakes = _Fakes();
      seedSchool(fakes);
      fakes.upload.progressTo = 42;
      fakes.upload.assetUrl = 'https://cdn/report.pdf';
      final cubit = fakes.build();

      final emitted = <StudentDocumentState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.uploadFile(studentCode: 'S1', file: pickedFile());
      // let the background URL resolution microtask run
      await Future<void>.delayed(Duration.zero);

      expect(emitted.any((s) => s.isUploading), isTrue);
      expect(emitted.any((s) => s.uploadPercent == 42), isTrue);
      expect(fakes.upload.completeCalls, 1);
      expect(fakes.upload.waitReadyCalls, 1);
      expect(cubit.state.uploadStatus, DocumentUploadStatus.uploaded);
      expect(cubit.state.uploadedAssetCode, 'ASSET1');
      expect(cubit.state.hasUploadedAsset, isTrue);
      // background resolve replaced the storage path with the delivery URL
      expect(cubit.state.uploadedStoragePath, 'https://cdn/report.pdf');
      expect(cubit.state.selectedFileName, 'report.pdf');

      await sub.cancel();
    });

    test('missing school/org context fails the upload', () async {
      final fakes = _Fakes(); // storage empty
      final cubit = fakes.build();

      await cubit.uploadFile(studentCode: 'S1', file: pickedFile());

      expect(cubit.state.uploadStatus, DocumentUploadStatus.failed);
      expect(cubit.state.uploadErrorMessage, contains('Missing school'));
      expect(cubit.state.hasUploadedAsset, isFalse);
    });

    test('a service error fails the upload (not a throw to the caller)',
        () async {
      final fakes = _Fakes();
      seedSchool(fakes);
      fakes.upload.sessionError = Exception('network down');
      final cubit = fakes.build();

      await cubit.uploadFile(studentCode: 'S1', file: pickedFile());

      expect(cubit.state.uploadStatus, DocumentUploadStatus.failed);
      expect(cubit.state.uploadErrorMessage, contains('Failed to upload'));
    });
  });

  group('submit', () {
    test('add: builds payload from uploaded state and reports success',
        () async {
      final fakes = _Fakes();
      seedSchool(fakes);
      fakes.upload.assetUrl = '';
      final cubit = fakes.build();
      cubit.setDocumentType('Health Forms');
      cubit.setExpiryDate(DateTime(2027, 3, 4));
      await cubit.uploadFile(studentCode: 'S1', file: pickedFile());

      await cubit.submit(
        studentCode: 'S1',
        name: 'Vaccination Card',
        notes: 'n',
        uploadedBy: 'STAFF1',
        isEdit: false,
      );

      expect(fakes.add.calls, 1);
      final a = fakes.add.args.single;
      expect(a['type'], 'HEALTH_FORM');
      expect(a['expiryDate'], '2027-03-04');
      expect(a['assetCode'], 'ASSET1');
      expect(a['size'], 5);
      expect(a['storagePath'], 'report.pdf');
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.message, 'Document added');
    });

    test('add: surfaces failure message', () async {
      final fakes = _Fakes();
      seedSchool(fakes);
      fakes.add.result = const Left(ServerFailure('server said no'));
      final cubit = fakes.build();
      cubit.setDocumentType('Other');
      await cubit.uploadFile(studentCode: 'S1', file: pickedFile());

      await cubit.submit(
        studentCode: 'S1',
        name: 'Doc',
        isEdit: false,
      );

      expect(cubit.state.isError, isTrue);
      expect(cubit.state.message, 'server said no');
    });

    test('edit with no new file uses the initial file metadata', () async {
      final fakes = _Fakes();
      final cubit = fakes.build()
        ..initializeForEdit(documentType: 'Other', assetCode: 'OLD');

      await cubit.submit(
        studentCode: 'S1',
        name: 'Doc',
        isEdit: true,
        documentUuid: 'UUID1',
        initialFilePath: 'existing/path.pdf',
        initialFileSizeKb: 10,
        initialMimeType: 'application/pdf',
      );

      expect(fakes.update.calls, 1);
      final u = fakes.update.args.single;
      expect(u['documentUuid'], 'UUID1');
      expect(u['storagePath'], 'existing/path.pdf');
      expect(u['size'], 10 * 1024);
      expect(u['assetCode'], 'OLD');
      expect(cubit.state.isSuccess, isTrue);
    });

    test('no file and not edit → error without calling a use case', () async {
      final fakes = _Fakes();
      final cubit = fakes.build()..setDocumentType('Other');

      await cubit.submit(studentCode: 'S1', name: 'Doc', isEdit: false);

      expect(fakes.add.calls, 0);
      expect(fakes.update.calls, 0);
      expect(cubit.state.isError, isTrue);
      expect(cubit.state.message, 'Please upload a document');
    });
  });
}
