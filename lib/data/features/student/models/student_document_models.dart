import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_document_models.g.dart';

/// Request model for POST /api/v1/student-documents.
class StudentDocumentRequestModel extends Equatable {
  const StudentDocumentRequestModel({
    required this.name,
    required this.type,
    required this.expiryDate,
    required this.storagePath,
    required this.mimeType,
    required this.size,
    required this.ownerType,
    required this.ownerId,
    this.assetCode,
    this.uploadedBy,
    this.notes,
  });

  final String name;
  final String type;
  final String expiryDate;
  final String storagePath;
  final String mimeType;
  final int size;
  final String ownerType;
  final String ownerId;
  final String? assetCode;
  final String? uploadedBy;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'expiryDate': expiryDate.trim().isEmpty ? null : expiryDate,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'size': size,
      'ownerType': ownerType,
      'ownerId': ownerId,
      if (assetCode != null && assetCode!.trim().isNotEmpty)
        'assetCode': assetCode!.trim(),
      if (uploadedBy != null && uploadedBy!.trim().isNotEmpty)
        'uploadedBy': uploadedBy!.trim(),
      'notes': notes ?? '',
    };
  }

  @override
  List<Object?> get props => [
        name,
        type,
        expiryDate,
        storagePath,
        mimeType,
        size,
        ownerType,
        ownerId,
        assetCode,
        uploadedBy,
        notes,
      ];
}

/// Response model for POST /api/v1/student-documents.
@JsonSerializable(createToJson: false)
class StudentDocumentResponseModel extends Equatable {
  const StudentDocumentResponseModel({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  @JsonKey(defaultValue: false) final bool success;
  @JsonKey(defaultValue: '') final String message;
  final Map<String, dynamic>? data;
  @JsonKey(defaultValue: '') final String timestamp;

  factory StudentDocumentResponseModel.fromJson(Map<String, dynamic> json) =>
      _$StudentDocumentResponseModelFromJson(json);

  @override
  List<Object?> get props => [success, message, data, timestamp];
}

/// Model for a single student document from GET /api/v1/student-documents.
/// API returns: code, name, type, expiryDate, storagePath, mimeType, size, ownerId, notes, etc.
class StudentDocumentItemModel extends Equatable {
  const StudentDocumentItemModel({
    required this.code,
    required this.name,
    required this.type,
    required this.expiryDate,
    required this.storagePath,
    required this.mimeType,
    required this.size,
    this.assetCode,
    this.ownerId,
    this.notes,
    this.createdAt,
    this.uploadedBy,
  });

  final String code;
  final String name;
  final String type;
  final String expiryDate;
  final String storagePath;
  final String mimeType;
  final int size;

  /// Media-asset code used to resolve a downloadable link.
  final String? assetCode;
  final String? ownerId;
  final String? notes;
  final String? createdAt;
  final String? uploadedBy;

  factory StudentDocumentItemModel.fromJson(Map<String, dynamic> json) {
    return StudentDocumentItemModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      assetCode: (json['assetCode'] as String?)?.trim(),
      ownerId: json['ownerId'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      uploadedBy: (json['uploadedBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type,
      'expiryDate': expiryDate,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'size': size,
      if (assetCode != null && assetCode!.trim().isNotEmpty)
        'assetCode': assetCode,
      'ownerId': ownerId,
      'notes': notes,
      'createdAt': createdAt,
      'uploadedBy': uploadedBy,
    };
  }

  @override
  List<Object?> get props => [
        code,
        name,
        type,
        expiryDate,
        storagePath,
        mimeType,
        size,
        assetCode,
        ownerId,
        notes,
        createdAt,
        uploadedBy,
      ];
}

class StudentDocumentsPageModel extends Equatable {
  const StudentDocumentsPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentDocumentItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  factory StudentDocumentsPageModel.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? [];
    final items = content
        .map((item) => StudentDocumentItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pageable = json['pageable'] as Map<String, dynamic>? ?? {};
    final pageNumber = pageable['pageNumber'] as int? ?? 0;
    final pageSize = pageable['pageSize'] as int? ?? 10;

    return StudentDocumentsPageModel(
      items: items,
      page: json['number'] as int? ?? pageNumber,
      size: json['size'] as int? ?? pageSize,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      hasMore: !(json['last'] as bool? ?? true),
    );
  }

  factory StudentDocumentsPageModel.fromCacheJson(Map<String, dynamic> json) {
    return StudentDocumentsPageModel.fromJson(json);
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
