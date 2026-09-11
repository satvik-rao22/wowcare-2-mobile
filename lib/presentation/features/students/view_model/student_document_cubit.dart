import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_document_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_document_usecase.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

part 'student_document_state.dart';

/// Owns the whole add/edit-document flow: the form model, the multi-step file
/// upload (session → presign → PUT → complete → asset-ready), and the add/update
/// submit. The screen only picks the file and renders [state].
class StudentDocumentCubit extends Cubit<StudentDocumentState> {
  StudentDocumentCubit({
    required AddStudentDocumentUseCase addStudentDocumentUseCase,
    required UpdateStudentDocumentUseCase updateStudentDocumentUseCase,
    required ImageUploadService imageUploadService,
    required StorageService storageService,
  }) : _addStudentDocumentUseCase = addStudentDocumentUseCase,
       _updateStudentDocumentUseCase = updateStudentDocumentUseCase,
       _imageUploadService = imageUploadService,
       _storageService = storageService,
       super(const StudentDocumentState.initial());

  final AddStudentDocumentUseCase _addStudentDocumentUseCase;
  final UpdateStudentDocumentUseCase _updateStudentDocumentUseCase;
  final ImageUploadService _imageUploadService;
  final StorageService _storageService;

  // --- form model ---

  /// Seed the form for edit mode (the pre-existing document's fields).
  void initializeForEdit({
    String? documentType,
    DateTime? expiryDate,
    String? assetCode,
  }) {
    emit(
      state.copyWith(
        documentType: documentType,
        expiryDate: expiryDate,
        uploadedAssetCode: assetCode,
      ),
    );
  }

  void setDocumentType(String? type) {
    emit(state.copyWith(documentType: type));
  }

  void setExpiryDate(DateTime? date) {
    emit(state.copyWith(expiryDate: date));
  }

  // --- file upload ---

  /// Upload the picked file end-to-end, emitting progress and the resulting
  /// asset code. On any guard/failure it flips [uploadStatus] to `failed` and
  /// sets [uploadErrorMessage] (the screen surfaces it as a warning). The
  /// delivery URL resolves in the background so the button isn't gated on it.
  Future<void> uploadFile({
    required String studentCode,
    required PlatformFile file,
  }) async {
    emit(
      state.copyWith(
        selectedFileName: file.name,
        selectedFileSize: file.size,
        selectedFileExtension: file.extension,
        uploadStatus: DocumentUploadStatus.uploading,
        uploadPercent: 0,
        uploadErrorMessage: null,
        uploadedAssetCode: null,
        uploadedStoragePath: null,
      ),
    );

    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      final organizationCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        _failUpload(StudentStrings.missingSchoolOrOrganizationContext);
        return;
      }

      final selectedPath = file.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        _failUpload(StudentStrings.selectedFilePathIsNotAvailable);
        return;
      }
      final ioFile = File(selectedPath);
      if (!await ioFile.exists()) {
        _failUpload(StudentStrings.selectedFileIsNotAccessible);
        return;
      }

      final mimeType = FilePickerUtils.getMimeType(file.extension);
      final uploadSession = await _imageUploadService
          .createStudentDocumentUploadSession(
            studentCode: studentCode,
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
        fileName: file.name,
        contentType: mimeType,
        contentLengthBytes: file.size,
        mediaType: mediaType,
        ownerType: 'STUDENT',
        ownerCode: studentCode,
      );
      await _imageUploadService.uploadFileToPresignedUrl(
        file: ioFile,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: mimeType,
        onProgress: (_, __, percent) {
          if (isClosed) return;
          emit(state.copyWith(uploadPercent: percent.clamp(0, 100)));
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
      // Asset is READY — finish now so the loader stops and the button enables.
      // The delivery URL is display-only (falls back to the file name), so
      // resolve it in the background rather than keeping the spinner up.
      emit(
        state.copyWith(
          uploadStatus: DocumentUploadStatus.uploaded,
          uploadedAssetCode: presign.assetCode,
          uploadedStoragePath: file.name,
          uploadPercent: 0,
        ),
      );

      _imageUploadService
          .getMediaAssetUrlByCode(assetCode: presign.assetCode)
          .then((resolvedUrl) {
            final url = resolvedUrl.trim();
            if (!isClosed && url.isNotEmpty) {
              emit(state.copyWith(uploadedStoragePath: url));
            }
          })
          .catchError((_) {});
    } catch (e) {
      _failUpload('Failed to upload file: ${e.toString()}');
    }
  }

  void _failUpload(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        uploadStatus: DocumentUploadStatus.failed,
        uploadPercent: 0,
        uploadErrorMessage: message,
      ),
    );
  }

  // --- submit ---

  static String _toDocumentTypeEnum(String uiValue) {
    switch (uiValue.trim()) {
      case 'Birth Certificate':
        return 'BIRTH_CERTIFICATE';
      case 'Registration Forms':
        return 'REGISTRATION_FORM';
      case 'Special Program Forms':
        return 'SPECIAL_PROGRAM_FORM';
      case 'Health Forms':
        return 'HEALTH_FORM';
      case 'Other':
      default:
        return 'OTHER';
    }
  }

  /// Build the payload from the current form/upload state (the caller supplies
  /// only the controller-backed name/notes + who's uploading) and add or update.
  Future<void> submit({
    required String studentCode,
    required String name,
    String? notes,
    String? uploadedBy,
    required bool isEdit,
    String? documentUuid,
    String? initialFilePath,
    int? initialFileSizeKb,
    String? initialMimeType,
  }) async {
    final String storagePath;
    final int sizeBytes;
    final String mimeType;
    if (state.hasSelectedFile) {
      storagePath = state.uploadedStoragePath ?? state.selectedFileName!;
      sizeBytes = state.selectedFileSize ?? 0;
      mimeType = FilePickerUtils.getMimeType(state.selectedFileExtension);
    } else if (isEdit && initialFilePath != null) {
      storagePath = initialFilePath;
      sizeBytes = (initialFileSizeKb ?? 0) * 1024;
      mimeType = initialMimeType ?? 'application/pdf';
    } else {
      emit(
        state.copyWith(
          submitStatus: DocumentSubmitStatus.error,
          message: StudentStrings.pleaseUploadADocument,
        ),
      );
      return;
    }

    final documentType = _toDocumentTypeEnum(state.documentType ?? '');
    final expiryDate = state.expiryDate != null
        ? DateFormat('yyyy-MM-dd').format(state.expiryDate!)
        : '';

    emit(
      state.copyWith(
        submitStatus: DocumentSubmitStatus.submitting,
        message: null,
      ),
    );

    final result = isEdit && (documentUuid ?? '').isNotEmpty
        ? await _updateStudentDocumentUseCase(
            documentUuid: documentUuid!,
            studentCode: studentCode,
            name: name,
            type: documentType,
            expiryDate: expiryDate,
            storagePath: storagePath,
            mimeType: mimeType,
            size: sizeBytes,
            assetCode: state.uploadedAssetCode,
            uploadedBy: uploadedBy,
            notes: notes,
          )
        : await _addStudentDocumentUseCase(
            studentCode: studentCode,
            name: name,
            type: documentType,
            expiryDate: expiryDate,
            storagePath: storagePath,
            mimeType: mimeType,
            size: sizeBytes,
            assetCode: state.uploadedAssetCode,
            uploadedBy: uploadedBy,
            notes: notes,
          );

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          submitStatus: DocumentSubmitStatus.error,
          message:
              failure.message ??
              (isEdit
                  ? StudentStrings.failedToUpdateDocument
                  : StudentStrings.failedToAddDocument),
        ),
      ),
      (message) => emit(
        state.copyWith(
          submitStatus: DocumentSubmitStatus.success,
          message: message,
        ),
      ),
    );
  }

  void reset() {
    emit(const StudentDocumentState.initial());
  }
}
