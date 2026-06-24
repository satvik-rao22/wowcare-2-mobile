import '../entities/ledger_entity.dart';
import '../repositories/ledger_repository.dart';

class GetLedgersUseCase {
  GetLedgersUseCase(this._repository);

  final LedgerRepository _repository;

  Future<LedgerPageEntity> call({
    required String organizationCode,
    required String school,
    String? search,
    String? category,
    String? status,
    int page = 0,
    int size = 10,
  }) =>
      _repository.getLedgers(
        organizationCode: organizationCode,
        school: school,
        search: search,
        category: category,
        status: status,
        page: page,
        size: size,
      );
}
