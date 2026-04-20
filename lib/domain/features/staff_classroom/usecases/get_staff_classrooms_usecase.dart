import '../entities/staff_classroom_item.dart';
import '../repositories/staff_classroom_repository.dart';

class GetStaffClassroomsUseCase {
  GetStaffClassroomsUseCase(this._repository);

  final StaffClassroomRepository _repository;

  Future<List<StaffClassroomItem>> call({
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
    bool refresh = false,
  }) {
    return _repository.getStaffClassrooms(
      schoolCode: schoolCode,
      classCodes: classCodes,
      primaryClassroomCodes: primaryClassroomCodes,
      excludeClassroomCode: excludeClassroomCode,
      search: search,
      status: status,
      designation: designation,
      organizationCode: organizationCode,
      firstName: firstName,
      phoneNumber: phoneNumber,
      code: code,
      refresh: refresh,
    );
  }
}

