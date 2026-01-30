import '../entities/staff_member.dart';
import '../entities/staff_document.dart';
import '../entities/staff_documents_page.dart';

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
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class StaffRepositoryWithCache {
  Future<StaffPage?> loadCachedStaffPage(String schoolCode);
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode);
}



