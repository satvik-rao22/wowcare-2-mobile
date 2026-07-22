class ClassroomAllItemModel {
  const ClassroomAllItemModel({
    required this.code,
    required this.name,
    this.minAgeYears = 0,
    this.maxAgeYears = 0,
  });

  final String code;
  final String name;

  /// `GET /classroom/classroom/all` returns `minAge`/`maxAge` as whole YEARS
  /// (e.g. `minAge: 2, maxAge: 4` = a 2–4 year room). 0 means "unset" — that
  /// side of the range isn't enforced.
  final int minAgeYears;
  final int maxAgeYears;

  factory ClassroomAllItemModel.fromJson(Map<String, dynamic> json) {
    // Support both 'code' and 'classroomCode' (backend may use either)
    final code = (json['code'] as String? ?? json['classroomCode'] as String?) ??
        (json['id']?.toString() ?? '');
    final name = (json['name'] as String? ?? json['classroomName'] as String?) ?? '';
    return ClassroomAllItemModel(
      code: code,
      name: name,
      minAgeYears: _years(json['minAge']),
      maxAgeYears: _years(json['maxAge']),
    );
  }

  /// Tolerates int / num / numeric-string, and clamps negatives to 0 (unset).
  static int _years(dynamic raw) {
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
  final int studentsTeacherRatio;

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
      capacity: json['capacity'] as int? ?? 0,
      studentsTeacherRatio: json['studentsTeacherRatio'] as int? ?? 0,
    );
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


