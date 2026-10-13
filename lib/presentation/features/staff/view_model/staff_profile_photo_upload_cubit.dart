import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../shared/services/asset/asset_service.dart';
import 'package:wowcare/shared/services/asset/profile_photo_uploader.dart';

/// Owns the multi-step staff profile-photo upload flow (create session,
/// presign, upload with progress, complete, wait-until-ready, finalize) —
/// previously run inline in [StaffProfileScreen]'s `State`.
class StaffProfilePhotoUploadCubit extends Cubit<StaffProfilePhotoUploadState> {
  StaffProfilePhotoUploadCubit({
    required AssetService assetService,
    required StorageService storageService,
  }) : _assetService = assetService,
       _storageService = storageService,
       super(const StaffProfilePhotoUploadState.initial());

  final AssetService _assetService;
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
      final photo = await ProfilePhotoUploader(_assetService).uploadStaffPhoto(
        staffCode: staffCode,
        file: File(imagePath),
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        onPercent: (percent) {
          if (isClosed) return;
          emit(
            StaffProfilePhotoUploadState.uploading(
              progressPercent: percent.toDouble(),
            ),
          );
        },
      );
      if (isClosed) return photo.url;
      emit(StaffProfilePhotoUploadState.done(photo.url));
      return photo.url;
    } catch (e) {
      if (!isClosed) {
        emit(StaffProfilePhotoUploadState.error('$e'));
      }
      rethrow;
    }
  }

  /// Deletes this staff member's profile photo. Throws on failure so the View
  /// can surface the message through its existing error snackbar; the View
  /// runs the post-success reset (clear the photo field, forget the cached
  /// avatar, refetch) exactly as it does after an upload.
  ///
  /// No progress state is emitted: the request is a single small POST, and the
  /// confirmation sheet already owns the in-flight spinner.
  Future<void> deletePhoto({required String staffCode}) async {
    await _assetService.deleteProfilePhoto(
      owner: ProfilePhotoOwner.staff,
      code: staffCode,
    );
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
