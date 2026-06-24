import '../../staff/entities/staff_member.dart';

abstract class MessagingRepository {
  Future<StaffPage> getFilteredStaff({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    String? status,
    String? designation,
    String? search,
    String? classCode,
  });

  Future<StaffPage> getStaffFromConversationsByStatus({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    required String staffStatus,
    String? designation,
    String? search,
    String? classCode,
  });
}
