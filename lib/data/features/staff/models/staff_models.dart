import 'package:equatable/equatable.dart';

class StaffListItemModel extends Equatable {
  const StaffListItemModel({
    required this.code,
    required this.name,
    required this.classroomCodes,
    required this.designation,
    required this.phoneNumber,
    required this.status,
  });

  final String code;
  final String name;
  final List<String> classroomCodes;
  final String designation;
  final String phoneNumber;
  final String status;

  factory StaffListItemModel.fromJson(Map<String, dynamic> json) {
    return StaffListItemModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      classroomCodes: (json['classroomCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      designation: json['designation'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'classroomCodes': classroomCodes,
      'designation': designation,
      'phoneNumber': phoneNumber,
      'status': status,
    };
  }

  @override
  List<Object?> get props =>
      [code, name, classroomCodes, designation, phoneNumber, status];
}

class StaffPageModel extends Equatable {
  const StaffPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffListItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];

  factory StaffPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map((e) => StaffListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final hasMore = pageNumber + 1 < totalPages;

    return StaffPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'page': page,
      'size': size,
      'totalPages': totalPages,
      'totalElements': totalElements,
      'hasMore': hasMore,
    };
  }

  factory StaffPageModel.fromCacheJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return StaffPageModel(
      items: itemsJson
          .map((e) => StaffListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}


