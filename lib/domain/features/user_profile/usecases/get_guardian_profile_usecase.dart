import '../entities/guardian_profile.dart';
import '../repositories/user_profile_repository.dart';

class GetGuardianProfileUseCase {
  GetGuardianProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<GuardianProfile> call({
    required String schoolCode,
    required String userCode,
  }) {
    return _repository.getGuardianProfile(
      schoolCode: schoolCode,
      userCode: userCode,
    );
  }
}
