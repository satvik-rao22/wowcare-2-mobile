import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../core/utils/file_picker_utils.dart';
import '../../../../shared/services/image_upload/image_upload_service.dart';
import 'staff_profile_cubit.dart';

/// Owns the multi-step staff-document upload flow (create session, presign,
/// upload to the presigned URL with progress, complete, wait-until-ready) —
/// previously run inline in [AddDocumentScreen]'s `State`.
class StaffDocumentUploadCubit extends Cubit<StaffDocumentUploadState> {
  StaffDocumentUploadCubit({
    required StorageService storageService,
    required ImageUploadService imageUploadService,
    required StaffProfileCubit staffProfileCubit,
  }) : _storageService = storageService,
       _imageUploadService = imageUploadService,
       _staffProfileCubit = staffProfileCubit,
       super(const StaffDocumentUploadState.initial());

  final StorageService _storageService;
  final ImageUploadService _imageUploadService;
  final StaffProfileCubit _staffProfileCubit;

  Future<void> uploadFile({
    required String staffCode,
    required PlatformFile selectedFile,
  }) async {
    emit(const StaffDocumentUploadState.uploading(progressPercent: 0));
    try {
      // Use the document owner's own school/organization rather than the
      // device's currently active school: an admin/staff can view a staff
      // member whose home school differs from the active one (e.g. after a
      // school switch, org-wide search, or a notification deep-link), and
      // the upload-session endpoint 500s if the school doesn't own the staff
      // code. Fall back to the active-school context if the profile lookup
      // fails.
      String schoolCode = '';
      String organizationCode = '';
      try {
        // forEditStaff:true — this must read the document OWNER's own
        // record (`staffCode`), not fall back to the cubit's default
        // my-profile endpoint, which resolves to the CALLER's own profile
        // and would silently defeat the whole point of this lookup whenever
        // an admin uploads on behalf of a staff member from another school.
        final profile = await _staffProfileCubit.fetchProfile(
          staffCode: staffCode,
          forEditStaff: true,
        );
        schoolCode = profile.schoolCode.trim();
        organizationCode = profile.organizationCode.trim();
      } catch (_) {
        // Fall back below.
      }
      if (schoolCode.isEmpty) {
        schoolCode =
            (await _storageService.getString(StorageKeys.schoolCode) ?? '')
                .trim();
      }
      if (organizationCode.isEmpty) {
        organizationCode =
            (await _storageService.getString(StorageKeys.organizationCode) ??
                    '')
                .trim();
      }
      if (isClosed) return;
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        emit(
          const StaffDocumentUploadState.error(
            'Missing school or organization context',
          ),
        );
        return;
      }

      final selectedPath = selectedFile.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        emit(
          const StaffDocumentUploadState.error(
            'Selected file path is not available',
          ),
        );
        return;
      }
      final file = File(selectedPath);
      final fileExists = await file.exists();
      if (isClosed) return;
      if (!fileExists) {
        emit(
          const StaffDocumentUploadState.error(
            'Selected file is not accessible',
          ),
        );
        return;
      }

      // lookupMimeType checks the real file name/bytes first, falling back to
      // the extension-only map only when it can't tell - a bare-extension
      // lookup alone sends 'application/octet-stream' for anything it
      // doesn't recognize (e.g. an audio file slipped past the picker's
      // extension filter), which surfaces as a meaningless "Content type
      // 'application/octet-stream' is not allowed" instead of the backend's
      // actual, specific rejection reason.
      final mimeType =
          lookupMimeType(selectedPath) ??
          FilePickerUtils.getMimeType(selectedFile.extension);
      final uploadSession = await _imageUploadService
          .createStaffDocumentUploadSession(
            staffCode: staffCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
          );
      final mediaType = mimeType.startsWith('image/')
          ? 'IMAGE'
          : mimeType.startsWith('video/')
          ? 'VIDEO'
          : 'DOCUMENT';
      final presign = await _imageUploadService.createAssetPresign(
        sessionCode: uploadSession.sessionCode,
        documentApiBasePath: uploadSession.documentApiBasePath,
        fileName: selectedFile.name,
        contentType: mimeType,
        contentLengthBytes: selectedFile.size,
        mediaType: mediaType,
        ownerType: 'STAFF',
        ownerCode: staffCode,
      );
      await _imageUploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: mimeType,
        onProgress: (_, __, percent) {
          if (isClosed) return;
          emit(
            StaffDocumentUploadState.uploading(
              progressPercent: percent.clamp(0, 100),
            ),
          );
        },
      );
      await _imageUploadService.completeAssetUpload(
        sessionCode: uploadSession.sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: uploadSession.documentApiBasePath,
      );
      await _imageUploadService.waitUntilAssetsReady(
        sessionCode: uploadSession.sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
      if (isClosed) return;
      // Asset is processed & READY — finish the upload now so the loader stops
      // and the "Add" button is enabled immediately. The delivery URL is only
      // used for display and falls back to the file name, so resolve it in the
      // background instead of keeping the spinner up.
      emit(
        StaffDocumentUploadState.done(
          assetCode: presign.assetCode,
          documentUrl: selectedFile.name,
        ),
      );
      _imageUploadService
          .getMediaAssetUrlByCode(assetCode: presign.assetCode)
          .then((resolvedUrl) {
            if (isClosed) return;
            final url = resolvedUrl.trim();
            final current = state;
            if (url.isNotEmpty && current is _DoneState) {
              emit(
                StaffDocumentUploadState.done(
                  assetCode: current.assetCode,
                  documentUrl: url,
                ),
              );
            }
          })
          .catchError((_) {});
    } catch (e) {
      if (isClosed) return;
      // Was raw '$e' - a DioException's toString() dump instead of the
      // actual backend reason (e.g. "Content type 'application/octet-stream'
      // is not allowed for DOCUMENT.") the {success, message, data} envelope
      // already carries. extractErrorMessage pulls that out.
      emit(
        StaffDocumentUploadState.error(
          'Failed to upload file: ${ApiErrorHandler.extractErrorMessage(e)}',
        ),
      );
    }
  }

  void reset() {
    emit(const StaffDocumentUploadState.initial());
  }
}

class StaffDocumentUploadState extends Equatable {
  const StaffDocumentUploadState._();

  const factory StaffDocumentUploadState.initial() = _InitialState;
  const factory StaffDocumentUploadState.uploading({
    required int progressPercent,
  }) = _UploadingState;
  const factory StaffDocumentUploadState.done({
    required String assetCode,
    required String documentUrl,
  }) = _DoneState;
  const factory StaffDocumentUploadState.error(String message) = _ErrorState;

  bool get isUploading => this is _UploadingState;
  bool get isDone => this is _DoneState;
  bool get isError => this is _ErrorState;

  int get progressPercent =>
      this is _UploadingState ? (this as _UploadingState).progressPercent : 0;
  String? get assetCode =>
      this is _DoneState ? (this as _DoneState).assetCode : null;
  String? get documentUrl =>
      this is _DoneState ? (this as _DoneState).documentUrl : null;
  String? get errorMessage =>
      this is _ErrorState ? (this as _ErrorState).message : null;

  @override
  List<Object?> get props => [];
}

class _InitialState extends StaffDocumentUploadState {
  const _InitialState() : super._();
}

class _UploadingState extends StaffDocumentUploadState {
  const _UploadingState({required this.progressPercent}) : super._();
  final int progressPercent;

  @override
  List<Object?> get props => [progressPercent];
}

class _DoneState extends StaffDocumentUploadState {
  const _DoneState({required this.assetCode, required this.documentUrl})
    : super._();
  final String assetCode;
  final String documentUrl;

  @override
  List<Object?> get props => [assetCode, documentUrl];
}

class _ErrorState extends StaffDocumentUploadState {
  const _ErrorState(this.message) : super._();
  final String message;

  @override
  List<Object?> get props => [message];
}
