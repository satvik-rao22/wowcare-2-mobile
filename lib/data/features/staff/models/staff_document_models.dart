import 'package:equatable/equatable.dart';

class StaffDocumentRequestModel extends Equatable {
  const StaffDocumentRequestModel({
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.documentSizeKb,
    required this.mimeType,
    required this.expiryDate,
  });

  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;
  final String expiryDate; // ISO date string: "2026-01-30"

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'documentName': documentName,
      'documentUrl': documentUrl,
      'documentSizeKb': documentSizeKb,
      'mimeType': mimeType,
      'expiryDate': expiryDate,
    };
  }

  @override
  List<Object?> get props =>
      [documentType, documentName, documentUrl, documentSizeKb, mimeType, expiryDate];
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
    required this.expired,
    required this.createdAt,
  });

  final String documentUuid;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final int documentSizeKb;
  final String mimeType;
  final String expiryDate;
  final bool expired;
  final String createdAt;

  factory StaffDocumentItemModel.fromJson(Map<String, dynamic> json) {
    return StaffDocumentItemModel(
      documentUuid: json['documentUuid'] as String? ?? '',
      documentType: json['documentType'] as String? ?? '',
      documentName: json['documentName'] as String? ?? '',
      documentUrl: json['documentUrl'] as String? ?? '',
      documentSizeKb: json['documentSizeKb'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      expired: json['expired'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
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
      'expired': expired,
      'createdAt': createdAt,
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
        expired,
        createdAt,
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

