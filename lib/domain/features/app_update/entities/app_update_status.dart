import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_version.dart';

/// Which store this copy of the app was installed from, and so which store
/// the update key sends people to.
enum StorePlatform { appStore, playStore }

/// The outcome of one update check: what is installed, what the rule says,
/// and what that means for this install.
class AppUpdateStatus extends Equatable {
  const AppUpdateStatus({
    required this.requirement,
    required this.installed,
    required this.policy,
    required this.store,
  });

  final AppUpdateRequirement requirement;
  final AppVersion installed;
  final AppUpdatePolicy policy;
  final StorePlatform store;

  bool get isRequired => requirement == AppUpdateRequirement.required;
  bool get isOptional => requirement == AppUpdateRequirement.optional;

  @override
  List<Object?> get props => [requirement, installed, policy, store];
}
