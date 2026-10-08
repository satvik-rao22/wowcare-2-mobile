class ClassroomAllItemModel {
  const ClassroomAllItemModel({
    required this.code,
    required this.name,
    this.minAgeMonths = 0,
    this.maxAgeMonths = 0,
  });

  final String code;
  final String name;

  /// `GET /classroom/classroom/all` returns `minAge`/`maxAge` as whole months
  /// (same convention as [ClassroomDetailsModel.minAgeTotalMonths] and the web
  /// client). 0 means "unset" — that side of the range isn't enforced.
  final int minAgeMonths;
  final int maxAgeMonths;

  factory ClassroomAllItemModel.fromJson(Map<String, dynamic> json) {
    // Support both 'code' and 'classroomCode' (backend may use either)
    final code = (json['code'] as String? ?? json['classroomCode'] as String?) ??
        (json['id']?.toString() ?? '');
    final name = (json['name'] as String? ?? json['classroomName'] as String?) ?? '';
    return ClassroomAllItemModel(
      code: code,
      name: name,
      minAgeMonths: _months(json['minAge']),
      maxAgeMonths: _months(json['maxAge']),
    );
  }

  /// Tolerates int / num / numeric-string, and clamps negatives to 0 (unset).
  static int _months(dynamic raw) {
    if (raw == null) return 0;
    final n = raw is num ? raw.toInt() : int.tryParse('$raw'.trim()) ?? 0;
    return n < 0 ? 0 : n;
  }
}

// ---------------------------------------------------------------------------
// Ratio Monitoring — paginated classroom list
// ---------------------------------------------------------------------------

/// One item in the paginated ratio-monitoring classroom list
/// (`GET /api/v1/classroom/classroom`).
class RatioClassroomItemModel {
  const RatioClassroomItemModel({
    required this.code,
    required this.name,
    required this.capacity,
    required this.studentsTeacherRatio,
  });

  final String code;
  final String name;
  final int capacity;
  final double studentsTeacherRatio;

  factory RatioClassroomItemModel.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String? ??
            json['classroomCode'] as String? ??
            json['id']?.toString()) ??
        '';
    final name = (json['name'] as String? ??
            json['classroomName'] as String?) ??
        '';
    return RatioClassroomItemModel(
      code: code,
      name: name,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      studentsTeacherRatio: _parseRatio(json),
    );
  }

  /// Tolerates int / double / numeric string / "students:teachers" text.
  /// A strict `as int?` cast threw on any non-int payload, which silently
  /// dropped the whole list to the fallback endpoint (ratio 0 -> always green).
  static double _parseRatio(Map<String, dynamic> json) {
    for (final key in const [
      'studentsTeacherRatio',
      'studentTeacherRatio',
      'studentsPerTeacher',
      'ratio',
    ]) {
      final text = (json[key] ?? '').toString().trim();
      if (text.isEmpty) continue;
      final fraction = RegExp(
        r'^(\d+(?:\.\d+)?)\s*[:/]\s*(\d+(?:\.\d+)?)$',
      ).firstMatch(text);
      if (fraction != null) {
        final students = double.tryParse(fraction.group(1)!);
        final teachers = double.tryParse(fraction.group(2)!);
        if (students != null && teachers != null && teachers > 0) {
          return students / teachers;
        }
      }
      final n = double.tryParse(text);
      if (n != null && n > 0) return n;
    }
    return 0;
  }
}

/// Paginated response wrapping [RatioClassroomItemModel] items.
/// Backend shape: `{ data: { content: [...] } }`.
class RatioClassroomPageResponseModel {
  const RatioClassroomPageResponseModel({required this.items});

  final List<RatioClassroomItemModel> items;

  factory RatioClassroomPageResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    List<dynamic> content = const [];
    if (data is Map<String, dynamic>) {
      final c = data['content'];
      if (c is List) content = c;
    } else if (data is List) {
      content = data;
    }
    return RatioClassroomPageResponseModel(
      items: content
          .map(
            (e) => RatioClassroomItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
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


