import '../../../../domain/features/classroom/entities/classroom_logo_upload_session.dart';
import '../../../../domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import '../../../../domain/features/classroom/entities/student_classroom_enrolled_count.dart';
import '../models/classroom_attendance_summary_model.dart';
import '../models/classroom_enrollment_models.dart';
import '../models/classroom_logo_models.dart';

class ClassroomMapper {
  const ClassroomMapper._();

  static ClassroomAttendanceSummaryEntry toAttendanceSummaryEntity(
    ClassroomAttendanceSummaryDataModel model,
  ) {
    return ClassroomAttendanceSummaryEntry(
      expected: model.expected,
      present: model.present,
      absent: model.absent,
      signout: model.signout,
      notMarked: model.notMarked,
    );
  }

  static StudentClassroomEnrolledCount toEnrolledCountEntity(
    StudentClassroomEnrolledCountDataModel model,
  ) {
    return StudentClassroomEnrolledCount(
      activeCount: model.activeCount,
      upcomingCount: model.upcomingCount,
      enrolledCount: model.enrolledCount,
    );
  }

  static ClassroomLogoUploadSession toLogoUploadSessionEntity(
    ClassroomLogoUploadSessionDataModel model,
  ) {
    return ClassroomLogoUploadSession(
      sessionCode: model.sessionCode,
      documentApiBasePath: model.documentApiBasePath,
    );
  }
}
