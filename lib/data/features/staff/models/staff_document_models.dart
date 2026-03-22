import 'package:equatable/equatable.dart';

class StaffDocumentRequestModel extends Equatable {
  const StaffDocumentRequestModel({
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.documentSizeKb,
    required this.mimeType,
    required this.expiryDate,
    this.documentNotes,
    this.updatedBy,
  });

  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;
  final String expiryDate; // ISO date string or empty when optional
  final String? documentNotes;
  /// Name or code of staff/admin who uploaded/last updated the document.
  final String? updatedBy;

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'documentName': documentName,
      'documentUrl': documentUrl,
      'documentSizeKb': documentSizeKb,
      'mimeType': mimeType,
      'expiryDate': expiryDate,
      if (documentNotes != null && documentNotes!.isNotEmpty)
        'documentNotes': documentNotes,
      // Backend contract: field is named "uploadedBy" in the request body.
      if (updatedBy != null && updatedBy!.isNotEmpty) 'uploadedBy': updatedBy,
    };
  }

  @override
  List<Object?> get props =>
      [documentType, documentName, documentUrl, documentSizeKb, mimeType, expiryDate, documentNotes, updatedBy];
}

class StaffDocumentResponseModel extends Equatable {
  const StaffDocumentResponseModel({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String timestamp;

  factory StaffDocumentResponseModel.fromJson(Map<String, dynamic> json) {
    return StaffDocumentResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [success, message, data, timestamp];
}

class StaffDocumentItemModel extends Equatable {
  const StaffDocumentItemModel({
    required this.documentUuid,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.documentSizeKb,
    required this.mimeType,
    required this.expiryDate,
    this.documentNotes,
    required this.expired,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String documentUuid;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;
  final String expiryDate;
  final String? documentNotes;
  final bool expired;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;

  factory StaffDocumentItemModel.fromJson(Map<String, dynamic> json) {
    return StaffDocumentItemModel(
      documentUuid: json['documentUuid'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      documentName: json['documentName'] as String? ?? '',
      documentUrl: json['documentUrl'] as String? ?? '',
      documentSizeKb: json['documentSizeKb'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      documentNotes: json['documentNotes'] as String?,
      expired: json['expired'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedBy: json['updatedBy'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentUuid': documentUuid,
      'documentType': documentType,
      'documentName': documentName,
      'documentUrl': documentUrl,
      'documentSizeKb': documentSizeKb,
      'mimeType': mimeType,
      'expiryDate': expiryDate,
      if (documentNotes != null) 'documentNotes': documentNotes,
      'expired': expired,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        documentUuid,
        documentType,
        documentName,
        documentUrl,
        documentSizeKb,
        mimeType,
        expiryDate,
        documentNotes,
        expired,
        createdAt,
        updatedBy,
        updatedAt,
      ];
}

class StaffDocumentsPageModel extends Equatable {
  const StaffDocumentsPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffDocumentItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  factory StaffDocumentsPageModel.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? [];
    final items = content
        .map((item) => StaffDocumentItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pageable = json['pageable'] as Map<String, dynamic>? ?? {};
    final pageNumber = pageable['pageNumber'] as int? ?? 0;
    final pageSize = pageable['pageSize'] as int? ?? 10;

    return StaffDocumentsPageModel(
      items: items,
      page: json['number'] as int? ?? pageNumber,
      size: json['size'] as int? ?? pageSize,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      hasMore: !(json['last'] as bool? ?? true),
    );
  }

  factory StaffDocumentsPageModel.fromCacheJson(Map<String, dynamic> json) {
    return StaffDocumentsPageModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'content': items.map((item) => item.toJson()).toList(),
      'number': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'last': !hasMore,
      'first': page == 0,
      'numberOfElements': items.length,
      'empty': items.isEmpty,
      'pageable': {
        'pageNumber': page,
        'pageSize': size,
        'offset': page * size,
        'paged': true,
        'unpaged': false,
      },
    };
  }

  @override
  List<Object?> get props => [items, page, size, totalPages, totalElements, hasMore];
}

