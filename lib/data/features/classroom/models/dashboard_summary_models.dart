class SchoolCapacityModel {
  const SchoolCapacityModel({
    required this.capacity,
    required this.minAgeMonths,
    required this.maxAgeMonths,
  });

  final int capacity;
  final int minAgeMonths;
  final int maxAgeMonths;

  factory SchoolCapacityModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return SchoolCapacityModel(
      capacity: data['capacity'] as int? ?? 0,
      minAgeMonths: data['minAgeMonths'] as int? ?? 0,
      maxAgeMonths: data['maxAgeMonths'] as int? ?? 0,
    );
  }
}

class ClassroomCountModel {
  const ClassroomCountModel({
    required this.total,
    required this.adminCount,
    required this.classroomCount,
  });

  final int total;
  final int adminCount;
  final int classroomCount;

  factory ClassroomCountModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return ClassroomCountModel(
      total: data['total'] as int? ?? 0,
      adminCount: data['adminCount'] as int? ?? 0,
      classroomCount: data['classroomCount'] as int? ?? 0,
    );
  }
}

class SchoolFteModel {
  const SchoolFteModel({required this.schoolCode, required this.schoolFte});

  final String schoolCode;
  final double schoolFte;

  factory SchoolFteModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return SchoolFteModel(
      schoolCode: data['schoolCode'] as String? ?? '',
      schoolFte: (data['schoolFte'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
