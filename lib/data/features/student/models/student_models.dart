import 'package:equatable/equatable.dart';

class StudentListItemModel extends Equatable {
  const StudentListItemModel({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.classroom = '',
    this.dob = '',
    this.movementDate = '',
  });

  final String code;
  final String firstName;
  final String lastName;
  final String status;
  final String classroom;
  final String dob;
  final String movementDate;

  String get fullName => '$firstName $lastName'.trim();

  factory StudentListItemModel.fromJson(Map<String, dynamic> json) {
    return StudentListItemModel(
      code: json['code'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      classroom: json['classroom'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      movementDate: json['movementDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'firstName': firstName,
      'lastName': lastName,
      'status': status,
      'classroom': classroom,
      'dob': dob,
      'movementDate': movementDate,
    };
  }

  @override
  List<Object?> get props => [
        code,
        firstName,
        lastName,
        status,
        classroom,
        dob,
        movementDate,
      ];
}

class StudentPageModel extends Equatable {
  const StudentPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentListItemModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];

  factory StudentPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map((e) => StudentListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final hasMore = pageNumber + 1 < totalPages;

    return StudentPageModel(
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

  factory StudentPageModel.fromCacheJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return StudentPageModel(
      items: itemsJson
          .map((e) => StudentListItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

