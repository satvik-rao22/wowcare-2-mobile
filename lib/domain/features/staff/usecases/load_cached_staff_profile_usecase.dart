import '../entities/staff_profile.dart';
import '../repositories/staff_repository.dart';

/// Reads the locally cached staff profile so the profile screen can paint
/// before the network round-trip completes.
///
/// A [StaffRepository] without [StaffRepositoryWithCache] reports a miss, so
/// the cubit never has to type-test the repository — which is what previously
/// forced it to hold one in violation of
/// View → Cubit → UseCase → Repository.
class LoadCachedStaffProfileUseCase {
  LoadCachedStaffProfileUseCase(this._repository);

  final StaffRepository _repository;

  Future<StaffProfile?> call(
    String staffCode, {
    bool forEditStaff = false,
  }) {
    final repository = _repository;
    if (repository is! StaffRepositoryWithCache) return Future.value(null);
    return (repository as StaffRepositoryWithCache).loadCachedStaffProfile(
      staffCode,
      forEditStaff: forEditStaff,
    );
  }
}
