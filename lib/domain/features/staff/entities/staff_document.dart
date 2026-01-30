import 'package:equatable/equatable.dart';

class StaffDocument extends Equatable {
  const StaffDocument({
    this.documentUuid,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.documentSizeKb,
    required this.mimeType,
    required this.expiryDate,
    this.expired = false,
    this.createdAt,
  });

  final String? documentUuid;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;
  final String expiryDate;
  final bool expired;
  final String? createdAt;

  @override
  List<Object?> get props => [
        documentUuid,
        documentType,
        documentName,
        documentUrl,
        documentSizeKb,
        mimeType,
        expiryDate,
        expired,
        createdAt,
      ];
}

