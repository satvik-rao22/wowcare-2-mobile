import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/app_time.dart';
import '../../../../core/utils/file_picker_utils.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../shared/services/image_upload/image_upload_service.dart';

/// Owns the multi-step staff profile-photo upload flow (create session,
/// presign, upload with progress, complete, wait-until-ready, finalize) —
/// previously run inline in [StaffProfileScreen]'s `State`.
class StaffProfilePhotoUploadCubit extends Cubit<StaffProfilePhotoUploadState> {
  StaffProfilePhotoUploadCubit({
    required ImageUploadService imageUploadService,
    required StorageService storageService,
  }) : _imageUploadService = imageUploadService,
       _storageService = storageService,
       super(const StaffProfilePhotoUploadState.initial());

  final ImageUploadService _imageUploadService;
  final StorageService _storageService;

  /// The org/school the upload runs under, read from the active selection.
  ///
  /// The profile screen resolved these from a [StorageService] it fetched
  /// itself; the cubit that needs them owns the read instead. Either value is
  /// null when nothing is selected, which the screen treats as "cannot upload".
  Future<({String? schoolCode, String? organizationCode})>
  loadUploadContext() async {
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    final organizationCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();
    return (
      schoolCode: schoolCode.isEmpty ? null : schoolCode,
      organizationCode: organizationCode.isEmpty ? null : organizationCode,
    );
  }

  /// Runs the upload and returns the finalized photo URL. Progress is also
  /// emitted via cubit state for the View to render a percent indicator.
  Future<String> uploadPhoto({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String imagePath,
  }) async {
    emit(const StaffProfilePhotoUploadState.uploading(progressPercent: 0));
    try {
      final file = File(imagePath);
      final sessionCode = await _imageUploadService
          .createStaffProfilePhotoUploadSession(
            staffCode: staffCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
          );
      if (isClosed) return '';
      emit(const StaffProfilePhotoUploadState.uploading(progressPercent: 15));

      final lowerPath = imagePath.toLowerCase();
      final fileName = lowerPath.split(Platform.pathSeparator).last;
      final mime = FilePickerUtils.getMimeType(
        fileName.contains('.') ? fileName.split('.').last : '',
      );
      final contentType = mime.startsWith('image/') ? mime : 'image/jpeg';
      final presign = await _imageUploadService.createAssetPresign(
        sessionCode: sessionCode,
        documentApiBasePath: '/api/v1',
        fileName: fileName.isNotEmpty
            ? fileName
            : 'staff-profile-photo-${AppTime.nowUtc().millisecondsSinceEpoch}.jpg',
        contentType: contentType,
        contentLengthBytes: await file.length(),
        mediaType: 'IMAGE',
        ownerType: 'STAFF',
        ownerCode: staffCode,
      );
      if (isClosed) return '';
      emit(const StaffProfilePhotoUploadState.uploading(progressPercent: 25));

      await _imageUploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: contentType,
        onSendProgress: (int sent, int total) {
          if (isClosed || total <= 0) return;
          final uploadPhasePercent = (sent / total).clamp(0.0, 1.0);
          emit(
            StaffProfilePhotoUploadState.uploading(
              progressPercent: 25 + (uploadPhasePercent * 55),
            ),
          );
        },
      );
      if (isClosed) return '';
      emit(const StaffProfilePhotoUploadState.uploading(progressPercent: 84));

      await _imageUploadService.completeAssetUpload(
        sessionCode: sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: '/api/v1',
      );
      if (isClosed) return '';
      emit(const StaffProfilePhotoUploadState.uploading(progressPercent: 90));

      await _imageUploadService.waitUntilAssetsReady(
        sessionCode: sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
      if (isClosed) return '';
      emit(const StaffProfilePhotoUploadState.uploading(progressPercent: 100));

      final finalizedUrl = await _imageUploadService.finalizeStaffProfilePhoto(
        staffCode: staffCode,
        assetCode: presign.assetCode,
      );
      if (isClosed) return finalizedUrl;
      emit(StaffProfilePhotoUploadState.done(finalizedUrl));
      return finalizedUrl;
    } catch (e) {
      if (!isClosed) {
        emit(StaffProfilePhotoUploadState.error('$e'));
      }
      rethrow;
    }
  }

  /// Resets to initial — called by the View once it has finished reacting to
  /// a `.done`/`.error` terminal state (e.g. after showing a snackbar), so a
  /// later re-render doesn't see a stale progress bar.
  void reset() {
    if (!isClosed) emit(const StaffProfilePhotoUploadState.initial());
  }
}

class StaffProfilePhotoUploadState extends Equatable {
  const StaffProfilePhotoUploadState._({
    this.isUploading = false,
    this.progressPercent = 0,
    this.finalizedUrl,
    this.errorMessage,
  });

  const StaffProfilePhotoUploadState.initial() : this._();
  const StaffProfilePhotoUploadState.uploading({
    required double progressPercent,
  }) : this._(isUploading: true, progressPercent: progressPercent);
  const StaffProfilePhotoUploadState.done(String finalizedUrl)
    : this._(finalizedUrl: finalizedUrl);
  const StaffProfilePhotoUploadState.error(String message)
    : this._(errorMessage: message);

  final bool isUploading;
  final double progressPercent;
  final String? finalizedUrl;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    isUploading,
    progressPercent,
    finalizedUrl,
    errorMessage,
  ];
}
