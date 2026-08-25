import 'package:equatable/equatable.dart';

class StaffDocument extends Equatable {
  const StaffDocument({
    this.documentUuid,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.documentSizeKb,
    required this.mimeType,
    this.assetCode,
    this.expiryDate,
    this.documentNotes,
    this.expired = false,
    this.createdAt,
    this.uploadedBy,
  });

  final String? documentUuid;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;
  final String? assetCode;

  /// ISO date string (yyyy-MM-dd), or null when document has no expiry.
  final String? expiryDate;
  final String? documentNotes;
  final bool expired;
  final String? createdAt;

  /// Backend field: `updatedBy` (name of staff/admin/system who last uploaded/updated).
  final String? uploadedBy;

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
    documentNotes,
    expired,
    createdAt,
    uploadedBy,
  ];
}
