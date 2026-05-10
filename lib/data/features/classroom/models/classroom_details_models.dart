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

  static int _asPositiveInt(dynamic v) {
    if (v is num) {
      final n = v.toInt();
      return n > 0 ? n : 0;
    }
    final s = (v ?? '').toString().trim();
    final n = int.tryParse(s);
    return (n != null && n > 0) ? n : 0;
  }

  static int _parseStudentsPerTeacher(Map<String, dynamic> json) {
    final direct = _asPositiveInt(json['studentsPerTeacher']);
    if (direct > 0) return direct;

    final ratioRawCandidates = <dynamic>[
      json['ratio'],
      json['studentTeacherRatio'],
      json['studentsToTeacherRatio'],
      json['teacherStudentRatio'],
    ];
    for (final raw in ratioRawCandidates) {
      final text = (raw ?? '').toString().trim();
      if (text.isEmpty) continue;
      // Expected formats: "2:1", "2 / 1", "2-1"
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

  static int _parseAgePart(
    Map<String, dynamic> json, {
    required String canonicalKey,
    required List<String> fallbacks,
    String? nestedKey,
  }) {
    final direct = _asPositiveInt(json[canonicalKey]);
    if (direct > 0) return direct;
    for (final k in fallbacks) {
      final v = _asPositiveInt(json[k]);
      if (v > 0) return v;
    }
    if (nestedKey != null) {
      final nested = json[nestedKey];
      if (nested is Map) {
        final m = Map<String, dynamic>.from(nested);
        final v = _asPositiveInt(m[canonicalKey]);
        if (v > 0) return v;
        for (final k in fallbacks) {
          final vv = _asPositiveInt(m[k]);
          if (vv > 0) return vv;
        }
      }
    }
    return 0;
  }

  factory ClassroomDetailsDataModel.fromJson(Map<String, dynamic> json) {
    return ClassroomDetailsDataModel(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      studentsPerTeacher: _parseStudentsPerTeacher(json),
      minAgeYear: _parseAgePart(
        json,
        canonicalKey: 'minAgeYear',
        fallbacks: const ['minAgeYears', 'minAgeY', 'minYear', 'min_age_year'],
        nestedKey: 'minAge',
      ),
      minAgeMonths: _parseAgePart(
        json,
        canonicalKey: 'minAgeMonths',
        fallbacks: const ['minAgeMonth', 'minAgeM', 'minMonth', 'min_age_months'],
        nestedKey: 'minAge',
      ),
      maxAgeYear: _parseAgePart(
        json,
        canonicalKey: 'maxAgeYear',
        fallbacks: const ['maxAgeYears', 'maxAgeY', 'maxYear', 'max_age_year'],
        nestedKey: 'maxAge',
      ),
      maxAgeMonths: _parseAgePart(
        json,
        canonicalKey: 'maxAgeMonths',
        fallbacks: const ['maxAgeMonth', 'maxAgeM', 'maxMonth', 'max_age_months'],
        nestedKey: 'maxAge',
      ),
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
