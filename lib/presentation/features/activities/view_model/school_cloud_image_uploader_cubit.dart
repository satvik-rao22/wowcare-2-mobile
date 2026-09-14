import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// ViewModel seam for [SchoolCloudImageUploaderDialog] — a self-contained
/// image-picker/upload dialog unrelated to activity editing, so it gets its
/// own small cubit rather than piggybacking on [ActivityEditorCubit]. Thin
/// pass-throughs to [StorageService]/[ImageUploadService], matching the
/// dialog's existing call shapes exactly (Mandate 5: "Presentation calls
/// cubits only" — the View no longer resolves DI dependencies itself).
class SchoolCloudImageUploaderCubit
    extends Cubit<SchoolCloudImageUploaderState> {
  SchoolCloudImageUploaderCubit({
    required StorageService storageService,
    required ImageUploadService imageUploadService,
  }) : _storage = storageService,
       _uploadService = imageUploadService,
       super(const SchoolCloudImageUploaderState());

  final StorageService _storage;
  final ImageUploadService _uploadService;

  Future<String> getSchoolCode() async =>
      (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

  Future<UploadSessionResult> createSchoolCloudUploadSession({
    required String schoolCode,
  }) => _uploadService.createSchoolCloudUploadSession(schoolCode: schoolCode);

  Future<AssetPresignResult> createAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  }) => _uploadService.createAssetPresign(
    sessionCode: sessionCode,
    documentApiBasePath: documentApiBasePath,
    fileName: fileName,
    contentType: contentType,
    contentLengthBytes: contentLengthBytes,
    mediaType: mediaType,
    ownerType: ownerType,
    ownerCode: ownerCode,
  );

  Future<void> uploadFileToPresignedUrl({
    required File file,
    required String presignedPutUrl,
    required Map<String, String> requiredHeaders,
    required String fallbackContentType,
    void Function(int sentBytes, int totalBytes, int percent)? onProgress,
  }) => _uploadService.uploadFileToPresignedUrl(
    file: file,
    presignedPutUrl: presignedPutUrl,
    requiredHeaders: requiredHeaders,
    fallbackContentType: fallbackContentType,
    onProgress: onProgress,
  );

  Future<void> completeAssetUpload({
    required String sessionCode,
    required String assetCode,
    required String documentApiBasePath,
  }) => _uploadService.completeAssetUpload(
    sessionCode: sessionCode,
    assetCode: assetCode,
    documentApiBasePath: documentApiBasePath,
  );
}

/// Stateless marker state — this cubit is a data facade; the dialog keeps its
/// own field/UI state (selected images, upload progress).
class SchoolCloudImageUploaderState extends Equatable {
  const SchoolCloudImageUploaderState();

  @override
  List<Object?> get props => const <Object?>[];
}
