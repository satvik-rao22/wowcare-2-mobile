import '../entities/staff_member.dart';
import '../entities/staff_document.dart';
import '../entities/staff_documents_page.dart';
import '../entities/staff_profile.dart';

abstract class StaffRepository {
  Future<StaffPage> getStaffPage({
    required String schoolCode,
    int page,
    int size,
    String? status,
    String? designation,
    String? search,
  });

  Future<String> addStaffDocument({
    required String staffCode,
    required StaffDocument document,
  });

  Future<StaffDocumentsPage> getStaffDocuments({
    required String staffCode,
    int page,
    int size,
    bool? expired,
  });

  Future<StaffProfile> getStaffProfile({
    required String staffCode,
  });
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StaffRepositoryWithCache {
  Future<StaffPage?> loadCachedStaffPage(String schoolCode);
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode);
  Future<StaffProfile?> loadCachedStaffProfile(String staffCode);
}



