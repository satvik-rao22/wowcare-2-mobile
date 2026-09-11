class StudentClassroomEnrolledCountDataModel {
  const StudentClassroomEnrolledCountDataModel({
    required this.activeCount,
    required this.upcomingCount,
    required this.enrolledCount,
  });

  final int activeCount;
  final int upcomingCount;
  final int enrolledCount;

  factory StudentClassroomEnrolledCountDataModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentClassroomEnrolledCountDataModel(
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      upcomingCount: (json['upcomingCount'] as num?)?.toInt() ?? 0,
      enrolledCount: (json['enrolledCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentClassroomEnrolledCountResponseModel {
  const StudentClassroomEnrolledCountResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final StudentClassroomEnrolledCountDataModel? data;

  factory StudentClassroomEnrolledCountResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentClassroomEnrolledCountResponseModel(
      success: json['success'] as bool? ?? true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? StudentClassroomEnrolledCountDataModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
