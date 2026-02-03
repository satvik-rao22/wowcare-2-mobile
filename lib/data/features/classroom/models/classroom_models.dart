class ClassroomModel {
  const ClassroomModel({
    required this.code,
    required this.name,
    this.capacity,
    required this.type,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  final String code;
  final String name;
  final int? capacity;
  final String type;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedBy;
  final String? updatedAt;

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      capacity: json['capacity'] as int?,
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt']?.toString(),
      updatedBy: json['updatedBy'] as String?,
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class ClassroomPageModel {
  const ClassroomPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<ClassroomModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  factory ClassroomPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? const [];

    return ClassroomPageModel(
      items: content
          .map((e) => ClassroomModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: data['number'] as int? ?? 0,
      size: data['size'] as int? ?? content.length,
      totalPages: data['totalPages'] as int? ?? 1,
      totalElements: data['totalElements'] as int? ?? content.length,
      hasMore: !(data['last'] as bool? ?? true),
    );
  }
}


