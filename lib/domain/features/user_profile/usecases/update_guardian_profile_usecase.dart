import '../entities/guardian_profile_update.dart';
import '../repositories/user_profile_repository.dart';

class UpdateGuardianProfileUseCase {
  UpdateGuardianProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<String> call(GuardianProfileUpdate update) {
    return _repository.updateGuardianProfile(update);
  }
}
