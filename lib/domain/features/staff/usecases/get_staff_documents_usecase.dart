import '../../../../domain/features/staff/entities/staff_documents_page.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

class GetStaffDocumentsUseCase {
  GetStaffDocumentsUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffDocumentsPage> call({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  }) {
    return _repository.getStaffDocuments(
      staffCode: staffCode,
      page: page,
      size: size,
      expired: expired,
    );
  }
}

