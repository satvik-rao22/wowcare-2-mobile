import '../entities/staff_documents_page.dart';
import '../repositories/staff_repository.dart';

/// Reads the locally cached first page of a staff member's documents.
///
/// See [LoadCachedStaffProfileUseCase] for why the cache-capability test lives
/// here rather than in the cubit.
class LoadCachedStaffDocumentsUseCase {
  LoadCachedStaffDocumentsUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffDocumentsPage?> call(String staffCode) {
    final repository = _repository;
    if (repository is! StaffRepositoryWithCache) return Future.value(null);
    return (repository as StaffRepositoryWithCache).loadCachedStaffDocuments(
      staffCode,
    );
  }
}
