import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';

/// Sends the user to the store listing named by [policy], or to this app's
/// own listing when the policy names none. False when nothing opened.
class OpenAppStoreUseCase {
  OpenAppStoreUseCase(this._repository);

  final AppUpdateRepository _repository;

  Future<bool> call(AppUpdatePolicy policy) =>
      _repository.openStore(policy.storeUrl);
}
