class ClassroomAllItemModel {
  const ClassroomAllItemModel({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory ClassroomAllItemModel.fromJson(Map<String, dynamic> json) {
    return ClassroomAllItemModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ClassroomAllResponseModel {
  const ClassroomAllResponseModel({
    required this.success,
    required this.message,
    required this.items,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final List<ClassroomAllItemModel> items;
  final String? timestamp;

  factory ClassroomAllResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final list = data is List ? data : const [];
    return ClassroomAllResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      items: list
          .map((e) => ClassroomAllItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp']?.toString(),
    );
  }
}


