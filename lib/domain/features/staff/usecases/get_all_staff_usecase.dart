import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

/// Fetches the entire staff list in a single call (no pagination), passing
/// repeated `status` query keys (e.g. `status=ACTIVE&status=UPCOMING`).
///
/// Used by the scheduling feature, which always needs every active/upcoming
/// staff member up-front rather than a paged view.
class GetAllStaffUseCase {
  GetAllStaffUseCase(this._repository);

  final StaffRepository _repository;

  Future<List<StaffMember>> call({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  }) {
    return _repository.getAllStaff(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      statuses: statuses,
      size: size,
    );
  }
}
