import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/domain/features/app_update/entities/app_version.dart';
import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';

/// Decides whether this install must update, may update, or is fine.
///
/// A dismissed optional update stays quiet for [dismissalWindow]. A newer
/// build is a new offer and shows again straight away, and a required
/// update is never snoozed.
class CheckAppUpdateUseCase {
  CheckAppUpdateUseCase(this._repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppUpdateRepository _repository;
  final DateTime Function() _now;

  static const Duration dismissalWindow = Duration(days: 7);

  Future<AppUpdateStatus> call({bool refresh = false}) async {
    final AppVersion installed = await _repository.getInstalledVersion();
    final AppUpdatePolicy policy = await _repository.getPolicy(
      refresh: refresh,
    );

    AppUpdateRequirement requirement = policy.requirementFor(installed.build);
    if (requirement == AppUpdateRequirement.optional &&
        await _isDismissed(policy.latestBuild)) {
      requirement = AppUpdateRequirement.none;
    }

    return AppUpdateStatus(
      requirement: requirement,
      installed: installed,
      policy: policy,
      store: _repository.store,
    );
  }

  Future<bool> _isDismissed(int latestBuild) async {
    final DateTime? at = await _repository.optionalDismissedAt(
      latestBuild: latestBuild,
    );
    return at != null && _now().difference(at) < dismissalWindow;
  }
}
