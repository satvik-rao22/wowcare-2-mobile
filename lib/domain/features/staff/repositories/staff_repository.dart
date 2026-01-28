import '../entities/staff_member.dart';

abstract class StaffRepository {
  Future<StaffPage> getStaffPage({
    required String schoolCode,
    int page,
    int size,
    String? status,
    String? designation,
    String? search,
  });
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StaffRepositoryWithCache {
  Future<StaffPage?> loadCachedStaffPage(String schoolCode);
}



