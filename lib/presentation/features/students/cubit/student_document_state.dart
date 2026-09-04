part of 'student_document_cubit.dart';

/// Submit (add/update) phase for the document form.
enum DocumentSubmitStatus { idle, submitting, success, error }

/// The file-upload phase (session → presign → PUT → complete → asset-ready).
enum DocumentUploadStatus { idle, uploading, uploaded, failed }

/// Single flat state for the add/edit-document form: the form model, the
/// file-upload progress/result, and the submit phase all live here so the view
/// holds no competing `setState` copies.
class StudentDocumentState extends Equatable {
  static const Object _unset = Object();

  const StudentDocumentState({
    this.submitStatus = DocumentSubmitStatus.idle,
    this.message,
    this.documentType,
    this.expiryDate,
    this.selectedFileName,
    this.selectedFileSize,
    this.selectedFileExtension,
    this.uploadStatus = DocumentUploadStatus.idle,
    this.uploadPercent = 0,
    this.uploadErrorMessage,
    this.uploadedAssetCode,
    this.uploadedStoragePath,
  });

  const StudentDocumentState.initial() : this();

  /// Submit phase.
  final DocumentSubmitStatus submitStatus;

  /// Submit success/error message (surfaced by the screen's BlocListener).
  final String? message;

  /// Form model.
  final String? documentType;
  final DateTime? expiryDate;

  /// Selected-file metadata (kept so submit can build the payload without the
  /// view holding the PlatformFile).
  final String? selectedFileName;
  final int? selectedFileSize;
  final String? selectedFileExtension;

  /// Upload phase + result.
  final DocumentUploadStatus uploadStatus;
  final int uploadPercent;
  final String? uploadErrorMessage;
  final String? uploadedAssetCode;
  final String? uploadedStoragePath;

  // Backward-compatible getters the screen's BlocListener/button already read.
  bool get isLoading => submitStatus == DocumentSubmitStatus.submitting;
  bool get isSuccess => submitStatus == DocumentSubmitStatus.success;
  bool get isError => submitStatus == DocumentSubmitStatus.error;
  bool get isUploading => uploadStatus == DocumentUploadStatus.uploading;

  /// A file has been uploaded and its asset code is ready for submit.
  bool get hasUploadedAsset => (uploadedAssetCode ?? '').trim().isNotEmpty;

  /// A file has been selected in this session (vs. an edit's pre-existing file).
  bool get hasSelectedFile => (selectedFileName ?? '').isNotEmpty;

  StudentDocumentState copyWith({
    DocumentSubmitStatus? submitStatus,
    Object? message = _unset,
    Object? documentType = _unset,
    Object? expiryDate = _unset,
    Object? selectedFileName = _unset,
    Object? selectedFileSize = _unset,
    Object? selectedFileExtension = _unset,
    DocumentUploadStatus? uploadStatus,
    int? uploadPercent,
    Object? uploadErrorMessage = _unset,
    Object? uploadedAssetCode = _unset,
    Object? uploadedStoragePath = _unset,
  }) {
    return StudentDocumentState(
      submitStatus: submitStatus ?? this.submitStatus,
      message: message == _unset ? this.message : message as String?,
      documentType:
          documentType == _unset ? this.documentType : documentType as String?,
      expiryDate:
          expiryDate == _unset ? this.expiryDate : expiryDate as DateTime?,
      selectedFileName: selectedFileName == _unset
          ? this.selectedFileName
          : selectedFileName as String?,
      selectedFileSize: selectedFileSize == _unset
          ? this.selectedFileSize
          : selectedFileSize as int?,
      selectedFileExtension: selectedFileExtension == _unset
          ? this.selectedFileExtension
          : selectedFileExtension as String?,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadPercent: uploadPercent ?? this.uploadPercent,
      uploadErrorMessage: uploadErrorMessage == _unset
          ? this.uploadErrorMessage
          : uploadErrorMessage as String?,
      uploadedAssetCode: uploadedAssetCode == _unset
          ? this.uploadedAssetCode
          : uploadedAssetCode as String?,
      uploadedStoragePath: uploadedStoragePath == _unset
          ? this.uploadedStoragePath
          : uploadedStoragePath as String?,
    );
  }

  @override
  List<Object?> get props => [
        submitStatus,
        message,
        documentType,
        expiryDate,
        selectedFileName,
        selectedFileSize,
        selectedFileExtension,
        uploadStatus,
        uploadPercent,
        uploadErrorMessage,
        uploadedAssetCode,
        uploadedStoragePath,
      ];
}
