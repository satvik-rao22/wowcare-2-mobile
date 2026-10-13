import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// ViewModel seam for [SchoolCloudImageUploaderDialog] — a self-contained
/// image-picker/upload dialog unrelated to activity editing, so it gets its
/// own small cubit rather than piggybacking on [ActivityEditorCubit]. It owns
/// the server steps; the dialog only drives the per-image loop and progress
/// (Mandate 5: "Presentation calls cubits only").
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

  /// Uploads one image to the school's cloud gallery: a fresh session, then
  /// presign → PUT → complete. Doesn't wait for server processing — the
  /// gallery shows the image once it's ready. [onUploadProgress] reports the
  /// PUT's 0–100 %.
  Future<void> uploadImage(
    File image, {
    required String schoolCode,
    void Function(int percent)? onUploadProgress,
  }) async {
    final session = await _uploadService.createSchoolCloudUploadSession(
      schoolCode: schoolCode,
    );
    await _uploadService.uploadToSession(
      session: session,
      file: image,
      owner: AssetOwner.school(schoolCode),
      fileName: image.uri.pathSegments.isNotEmpty
          ? image.uri.pathSegments.last
          : 'image-${AppTime.nowUtc().millisecondsSinceEpoch}.jpg',
      contentType: await FileUtils.imageMimeTypeOfFile(image.path),
      waitUntilReady: false,
      onUploadProgress: onUploadProgress,
    );
  }
}

/// Stateless marker state — this cubit is a data facade; the dialog keeps its
/// own field/UI state (selected images, upload progress).
class SchoolCloudImageUploaderState extends Equatable {
  const SchoolCloudImageUploaderState();

  @override
  List<Object?> get props => const <Object?>[];
}
