import 'package:equatable/equatable.dart';

/// Domain entity for a student document.
/// Maps from API: code, name, type, expiryDate, storagePath (→ documentUrl), size (→ documentSizeKb).
class StudentDocument extends Equatable {
  const StudentDocument({
    this.documentUuid,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.documentSizeKb,
    required this.mimeType,
    this.assetCode,
    required this.expiryDate,
    this.expired = false,
    this.createdAt,
    this.uploadedBy,
    this.notes,
  });

  final String? documentUuid;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;

  /// Media-asset code used to resolve a downloadable link (documentUrl is only
  /// the file name).
  final String? assetCode;
  final String expiryDate;
  final bool expired;
  final String? createdAt;
  final String? uploadedBy;
  final String? notes;

  @override
  List<Object?> get props => [
        documentUuid,
        documentType,
        documentName,
        documentUrl,
        documentSizeKb,
        mimeType,
        assetCode,
        expiryDate,
        expired,
        createdAt,
        uploadedBy,
        notes,
      ];
}
