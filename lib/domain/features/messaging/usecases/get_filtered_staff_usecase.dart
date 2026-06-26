import '../repositories/messaging_repository.dart';
import '../../staff/entities/staff_member.dart';

class GetFilteredStaffUseCase {
  final MessagingRepository _repository;

  GetFilteredStaffUseCase(this._repository);

  Future<StaffPage> call({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    String? status,
    String? designation,
    String? search,
    String? classCode,
    String? staffStatus,
  }) async {
    if (staffStatus != null && staffStatus.isNotEmpty) {
      return await _repository.getStaffFromConversationsByStatus(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        page: page,
        size: size,
        staffStatus: staffStatus,
        designation: designation,
        search: search,
        classCode: classCode,
      );
    } else {
      return await _repository.getFilteredStaff(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        page: page,
        size: size,
        status: status,
        designation: designation,
        search: search,
        classCode: classCode,
      );
    }
  }
}
