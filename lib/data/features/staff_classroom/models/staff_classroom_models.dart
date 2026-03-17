class StaffClassroomItemModel {
  StaffClassroomItemModel({
    required this.classroomCode,
    required this.staffCode,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.status,
    required this.designation,
    required this.expectedToday,
    required this.signedIn,
    required this.absent,
    required this.notMarked,
  });

  final String classroomCode;
  final String staffCode;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String status;
  final String designation;
  final bool expectedToday;
  final bool signedIn;
  final bool absent;
  final bool notMarked;

  factory StaffClassroomItemModel.fromJson(Map<String, dynamic> json) {
    return StaffClassroomItemModel(
      classroomCode: json['classroomCode'] as String? ?? '',
      staffCode: json['staffCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
      status: json['status'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      expectedToday: json['expectedToday'] as bool? ?? false,
      signedIn: json['signedIn'] as bool? ?? false,
      absent: json['absent'] as bool? ?? false,
      notMarked: json['notMarked'] as bool? ?? false,
    );
  }

  factory StaffClassroomItemModel.fromCacheJson(Map<String, dynamic> json) {
    return StaffClassroomItemModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'classroomCode': classroomCode,
      'staffCode': staffCode,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'status': status,
      'designation': designation,
      'expectedToday': expectedToday,
      'signedIn': signedIn,
      'absent': absent,
      'notMarked': notMarked,
    };
  }
}

class StaffClassroomListModel {
  StaffClassroomListModel({required this.items});
  final List<StaffClassroomItemModel> items;

  factory StaffClassroomListModel.fromCacheJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? const [];
    return StaffClassroomListModel(
      items: list
          .whereType<Map<String, dynamic>>()
          .map(StaffClassroomItemModel.fromCacheJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {'items': items.map((e) => e.toJson()).toList()};
}

class StaffClassroomAssignResponseModel {
  const StaffClassroomAssignResponseModel({
    required this.success,
    required this.message,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final String timestamp;

  factory StaffClassroomAssignResponseModel.fromJson(Map<String, dynamic> json) {
    return StaffClassroomAssignResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

