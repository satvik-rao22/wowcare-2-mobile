import '../entities/staff_classroom_item.dart';

abstract class StaffClassroomRepository {
  Future<List<StaffClassroomItem>> getStaffClassrooms({
    required String schoolCode,
    List<String>? classCodes,
    List<String>? primaryClassroomCodes,
    String? excludeClassroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
    String? organizationCode,
    String? firstName,
    String? phoneNumber,
    String? code,
    bool refresh,
  });

  Future<String> assignStaffToClassroom({
    required String schoolCode,
    required String classroomCode,
    required List<String> staffCodes,
  });

  /// Fetches the staff assignable to a classroom (manage-staff list),
  /// excluding [excludeClassroomCode]. [primaryClassroomCodes] and
  /// [designation] filter server-side.
  Future<List<StaffClassroomItem>> getManageStaffList({
    required String schoolCode,
    required String excludeClassroomCode,
    List<String>? primaryClassroomCodes,
    List<String>? designation,
  });
}

