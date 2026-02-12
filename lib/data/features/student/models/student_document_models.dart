import 'package:equatable/equatable.dart';

class StudentDocumentItemModel extends Equatable {
  const StudentDocumentItemModel({
    required this.name,
    required this.type,
    required this.expiryDate,
    required this.storagePath,
    required this.mimeType,
    required this.size,
    required this.ownerType,
    required this.ownerId,
  });

  final String name;
  final String type;
  final String expiryDate;
  final String storagePath;
  final String mimeType;
  final int size;
  final String ownerType;
  final String ownerId;

  factory StudentDocumentItemModel.fromJson(Map<String, dynamic> json) {
    return StudentDocumentItemModel(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      ownerType: json['ownerType'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'expiryDate': expiryDate,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'size': size,
      'ownerType': ownerType,
      'ownerId': ownerId,
    };
  }

  @override
  List<Object?> get props =>
      [name, type, expiryDate, storagePath, mimeType, size, ownerType, ownerId];
}

class StudentDocumentPageModel extends Equatable {
  const StudentDocumentPageModel({
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

  factory StudentDocumentPageModel.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>? ?? [];

    final items = content
        .map((item) =>
        StudentDocumentItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    final pageable = json['pageable'] as Map<String, dynamic>? ?? {};
    final pageNumber = pageable['pageNumber'] as int? ?? 0;
    final pageSize = pageable['pageSize'] as int? ?? 10;

    return StudentDocumentPageModel(
      items: items,
      page: json['number'] as int? ?? pageNumber,
      size: json['size'] as int? ?? pageSize,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      hasMore: !(json['last'] as bool? ?? true),
    );
  }

  factory StudentDocumentPageModel.fromCacheJson(
      Map<String, dynamic> json) {
    return StudentDocumentPageModel.fromJson(json);
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
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}
