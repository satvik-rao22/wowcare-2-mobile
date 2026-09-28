import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';

/// Records a "Not now" on the optional update to [latestBuild], so
/// [CheckAppUpdateUseCase] keeps it quiet for a week.
class DismissOptionalUpdateUseCase {
  DismissOptionalUpdateUseCase(this._repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppUpdateRepository _repository;
  final DateTime Function() _now;

  Future<void> call({required int latestBuild}) =>
      _repository.saveOptionalDismissal(latestBuild: latestBuild, at: _now());
}
