import '../entities/missed_signout.dart';
import '../repositories/regularization_repository.dart';

/// Loads the staff's unresolved past day, if any (§9.1) — the gate check.
///
/// Returns `null` when the staff is clear. At most one day can be unresolved
/// (§5.1), so there is no list to page through.
class GetOpenSessionUseCase {
  GetOpenSessionUseCase(this._repository);

  final RegularizationRepository _repository;

  Future<MissedSignout?> call(String staffCode) {
    return _repository.getOpenSession(staffCode);
  }
}
