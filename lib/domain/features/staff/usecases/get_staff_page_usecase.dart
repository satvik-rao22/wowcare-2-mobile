import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class GetStaffPageUseCase {
  GetStaffPageUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffPage> call({
    required String schoolCode,
    String? code,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
  }) {
    return _repository.getStaffPage(
      schoolCode: schoolCode,
      code: code,
      page: page,
      size: size,
      status: status,
      designation: designation,
      search: search,
      primaryClassroomCodes: primaryClassroomCodes,
      classCodes: classCodes,
      sortBy: sortBy,
    );
  }
}


