import '../entities/staff_classroom_item.dart';
import '../repositories/staff_classroom_repository.dart';

/// Staff assignable to a classroom (manage-staff list), excluding whichever
/// classroom the caller passes as [excludeClassroomCode].
class GetManageStaffListUseCase {
  GetManageStaffListUseCase(this._repository);

  final StaffClassroomRepository _repository;

  Future<List<StaffClassroomItem>> call({
    required String schoolCode,
    required String excludeClassroomCode,
    List<String>? primaryClassroomCodes,
    List<String>? designation,
  }) {
    return _repository.getManageStaffList(
      schoolCode: schoolCode,
      excludeClassroomCode: excludeClassroomCode,
      primaryClassroomCodes: primaryClassroomCodes,
      designation: designation,
    );
  }
}
