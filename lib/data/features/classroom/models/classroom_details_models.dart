class ClassroomDetailsDataModel {
  const ClassroomDetailsDataModel({
    required this.code,
    required this.name,
    required this.capacity,
    required this.studentsPerTeacher,
    required this.minAgeYear,
    required this.minAgeMonths,
    required this.maxAgeYear,
    required this.maxAgeMonths,
    required this.type,
    required this.school,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String code;
  final String name;
  final int capacity;
  final int studentsPerTeacher;
  final int minAgeYear;
  final int minAgeMonths;
  final int maxAgeYear;
  final int maxAgeMonths;
  final String type;
  final String school;
  final String status;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  factory ClassroomDetailsDataModel.fromJson(Map<String, dynamic> json) {
    return ClassroomDetailsDataModel(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      studentsPerTeacher: (json['studentsPerTeacher'] as num?)?.toInt() ?? 0,
      minAgeYear: (json['minAgeYear'] as num?)?.toInt() ?? 0,
      minAgeMonths: (json['minAgeMonths'] as num?)?.toInt() ?? 0,
      maxAgeYear: (json['maxAgeYear'] as num?)?.toInt() ?? 0,
      maxAgeMonths: (json['maxAgeMonths'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? '').toString(),
      school: (json['school'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }
}

class ClassroomDetailsResponseModel {
  const ClassroomDetailsResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final ClassroomDetailsDataModel? data;
  final DateTime? timestamp;

  factory ClassroomDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return ClassroomDetailsResponseModel(
      success: json['success'] as bool? ?? false,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? ClassroomDetailsDataModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
    );
  }
}
