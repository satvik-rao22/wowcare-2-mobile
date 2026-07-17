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
    this.logoAssetCode = '',
  });

  final String code;
  final String name;
  final int capacity;
  final double studentsPerTeacher;
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
  final String logoAssetCode;

  static int _nonNegativeMonths(dynamic v) {
    if (v is num) {
      return v.toInt().clamp(0, 12000);
    }
    final n = int.tryParse((v ?? '').toString().trim());
    return n == null ? 0 : n.clamp(0, 12000);
  }

  static double _asPositiveDouble(dynamic v) {
    if (v is num) {
      final n = v.toDouble();
      return n > 0 ? n : 0;
    }
    final s = (v ?? '').toString().trim();
    final n = double.tryParse(s);
    return (n != null && n > 0) ? n : 0;
  }

  static double _parseStudentsPerTeacher(Map<String, dynamic> json) {
    final ratioRawCandidates = <dynamic>[
      json['studentTeacherRatio'],
      json['studentsTeacherRatio'],
      json['studentsPerTeacher'],
      json['ratio'],
      json['studentsToTeacherRatio'],
      json['teacherStudentRatio'],
    ];

    for (final raw in ratioRawCandidates) {
      final text = (raw ?? '').toString().trim();
      if (text.isEmpty) continue;

      final fractionMatch =
          RegExp(r'^(\d+(?:\.\d+)?)\s*[:/\-]\s*(\d+(?:\.\d+)?)$')
              .firstMatch(text);
      if (fractionMatch != null) {
        final students = double.tryParse(fractionMatch.group(1) ?? '');
        final teachers = double.tryParse(fractionMatch.group(2) ?? '');
        if (students != null &&
            teachers != null &&
            students > 0 &&
            teachers > 0) {
          return students / teachers;
        }
      }

      final asDouble = _asPositiveDouble(raw);
      if (asDouble > 0) return asDouble;
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
      logoAssetCode: (json['logoAssetCode'] ?? '').toString().trim(),
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
