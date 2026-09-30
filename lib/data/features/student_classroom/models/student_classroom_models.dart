class StudentClassroomItemModel {
  StudentClassroomItemModel({
    required this.classroomCode,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.status,
    required this.expectedToday,
    required this.signedIn,
    required this.absent,
    required this.notMarked,
    required this.nap,
    required this.photoPermission,
    required this.notes,
    required this.medication,
    required this.allergies,
    required this.dietaryRestriction,
    this.dob,
  });

  final String classroomCode;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String status;
  final bool expectedToday;
  final bool signedIn;
  final bool absent;
  final bool notMarked;
  final bool nap;
  final bool photoPermission;
  final bool notes;
  final bool medication;
  final bool allergies;
  final bool dietaryRestriction;
  final String? dob;

  factory StudentClassroomItemModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map<String, dynamic>
        ? json['student'] as Map<String, dynamic>
        : null;
    final classroom = json['classroom'] is Map<String, dynamic>
        ? json['classroom'] as Map<String, dynamic>
        : null;

    String str(dynamic v) => v?.toString().trim() ?? '';

    /// Prefer [a], then [b], for [key].
    String pick(Map<String, dynamic>? a, Map<String, dynamic>? b, String key) {
      for (final m in [a, b]) {
        if (m == null) continue;
        final s = str(m[key]);
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    var firstName = pick(json, student, 'firstName');
    var lastName = pick(json, student, 'lastName');
    final displayName = pick(json, student, 'displayName');

    if (firstName.isEmpty && lastName.isEmpty && displayName.isNotEmpty) {
      final parts = displayName
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    var studentCode = pick(json, student, 'studentCode');
    if (studentCode.isEmpty) {
      studentCode = pick(json, student, 'code');
    }

    var classroomCode = pick(json, classroom, 'classroomCode');
    if (classroomCode.isEmpty) {
      classroomCode = pick(json, classroom, 'code');
    }

    bool asBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return false;
    }

    /// True when a presence-indicator field carries content.
    ///
    /// The student-classroom API returns the health fields (`medication`,
    /// `allergies`, `dietaryRestriction`) as free text — e.g. `"Headache"` —
    /// or `null`, never as booleans. Any non-empty value (other than the
    /// literal `null`/`false`/`0`) therefore means "something is on file".
    bool hasValue(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v?.toString().trim().toLowerCase() ?? '';
      return s.isNotEmpty && s != 'null' && s != 'false' && s != '0';
    }

    final profileRaw = pick(json, student, 'profilePictureUrl');
    final dobRaw = pick(json, student, 'dob');

    return StudentClassroomItemModel(
      classroomCode: classroomCode,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      profilePictureUrl: profileRaw.isEmpty ? null : profileRaw,
      status: pick(json, student, 'status'),
      expectedToday: asBool(json['expectedToday'] ?? student?['expectedToday']),
      signedIn: asBool(json['signedIn'] ?? student?['signedIn']),
      absent: asBool(json['absent'] ?? student?['absent']),
      notMarked: asBool(json['notMarked'] ?? student?['notMarked']),
      nap: asBool(json['nap'] ?? student?['nap']),
      photoPermission: asBool(
        json['photoPermission'] ?? student?['photoPermission'],
      ),
      notes: asBool(json['notes'] ?? student?['notes']),
      medication: hasValue(json['medication'] ?? student?['medication']),
      allergies: hasValue(json['allergies'] ?? student?['allergies']),
      dietaryRestriction: hasValue(
        json['dietaryRestriction'] ?? student?['dietaryRestriction'],
      ),
      dob: dobRaw.isEmpty ? null : dobRaw,
    );
  }

  factory StudentClassroomItemModel.fromCacheJson(Map<String, dynamic> json) {
    return StudentClassroomItemModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'classroomCode': classroomCode,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'status': status,
      'expectedToday': expectedToday,
      'signedIn': signedIn,
      'absent': absent,
      'notMarked': notMarked,
      'nap': nap,
      'photoPermission': photoPermission,
      'notes': notes,
      'medication': medication,
      'allergies': allergies,
      'dietaryRestriction': dietaryRestriction,
      'dob': dob,
    };
  }
}

class StudentClassroomListModel {
  StudentClassroomListModel({required this.items});

  final List<StudentClassroomItemModel> items;

  factory StudentClassroomListModel.fromCacheJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? const [];
    return StudentClassroomListModel(
      items: list
          .map(
            (e) => StudentClassroomItemModel.fromCacheJson(
              (e as Map<String, dynamic>),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'items': items.map((e) => e.toJson()).toList()};
  }
}

class StudentClassroomAssignResponseModel {
  const StudentClassroomAssignResponseModel({
    required this.success,
    required this.message,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final String timestamp;

  factory StudentClassroomAssignResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentClassroomAssignResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}
