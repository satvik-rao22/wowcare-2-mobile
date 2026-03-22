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

  factory StudentClassroomItemModel.fromJson(Map<String, dynamic> json) {
    return StudentClassroomItemModel(
      classroomCode: json['classroomCode'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
      status: json['status'] as String? ?? '',
      expectedToday: json['expectedToday'] as bool? ?? false,
      signedIn: json['signedIn'] as bool? ?? false,
      absent: json['absent'] as bool? ?? false,
      notMarked: json['notMarked'] as bool? ?? false,
      nap: json['nap'] as bool? ?? false,
      photoPermission: json['photoPermission'] as bool? ?? false,
      notes: json['notes'] as bool? ?? false,
      medication: json['medication'] as bool? ?? false,
      allergies: json['allergies'] as bool? ?? false,
      dietaryRestriction: json['dietaryRestriction'] as bool? ?? false,
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
    };
  }
}

class StudentClassroomListModel {
  StudentClassroomListModel({
    required this.items,
  });

  final List<StudentClassroomItemModel> items;

  factory StudentClassroomListModel.fromCacheJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? const [];
    return StudentClassroomListModel(
      items: list
          .map((e) => StudentClassroomItemModel.fromCacheJson(
                (e as Map<String, dynamic>),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
    };
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


