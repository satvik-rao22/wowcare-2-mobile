class ClassroomDetailsDataModel {
  const ClassroomDetailsDataModel({
    required this.code,
    required this.name,
    required this.capacity,
    required this.studentsPerTeacher,
    required this.minAgeTotalMonths,
    required this.maxAgeTotalMonths,
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
  /// API `minAge`: inclusive lower bound in whole months (0 = unset / from birth UI side).
  final int minAgeTotalMonths;
  /// API `maxAge`: inclusive upper bound in whole months (0 = unset).
  final int maxAgeTotalMonths;
  final String type;
  final String school;
  final String status;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  static int _asPositiveInt(dynamic v) {
    if (v is num) {
      final n = v.toInt();
      return n > 0 ? n : 0;
    }
    final s = (v ?? '').toString().trim();
    final n = int.tryParse(s);
    return (n != null && n > 0) ? n : 0;
  }

  static int _nonNegativeMonths(dynamic v) {
    if (v is num) {
      return v.toInt().clamp(0, 12000);
    }
    final n = int.tryParse((v ?? '').toString().trim());
    return n == null ? 0 : n.clamp(0, 12000);
  }

  static int _parseStudentsPerTeacher(Map<String, dynamic> json) {
    final direct = _asPositiveInt(json['studentsPerTeacher']);
    if (direct > 0) return direct;

    final fromApiRatio = _asPositiveInt(json['studentsTeacherRatio']);
    if (fromApiRatio > 0) return fromApiRatio;

    final ratioRawCandidates = <dynamic>[
      json['ratio'],
      json['studentTeacherRatio'],
      json['studentsTeacherRatio'],
      json['studentsToTeacherRatio'],
      json['teacherStudentRatio'],
    ];
    for (final raw in ratioRawCandidates) {
      final text = (raw ?? '').toString().trim();
      if (text.isEmpty) continue;
      final match = RegExp(r'(\d+)\s*[:/\-]\s*(\d+)').firstMatch(text);
      if (match != null) {
        final students = int.tryParse(match.group(1) ?? '');
        final teachers = int.tryParse(match.group(2) ?? '');
        if (students != null &&
            teachers != null &&
            students > 0 &&
            teachers > 0) {
          return (students / teachers).round();
        }
      }
      final maybeInt = int.tryParse(text);
      if (maybeInt != null && maybeInt > 0) return maybeInt;
    }
    return 0;
  }

  factory ClassroomDetailsDataModel.fromJson(Map<String, dynamic> json) {
    return ClassroomDetailsDataModel(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      studentsPerTeacher: _parseStudentsPerTeacher(json),
      minAgeTotalMonths: _nonNegativeMonths(json['minAge']),
      maxAgeTotalMonths: _nonNegativeMonths(json['maxAge']),
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
