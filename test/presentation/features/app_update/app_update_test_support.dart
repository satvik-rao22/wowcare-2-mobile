import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/domain/features/app_update/entities/app_version.dart';
import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';
import 'package:wowcare/domain/features/app_update/usecases/check_app_update_usecase.dart';
import 'package:wowcare/domain/features/app_update/usecases/dismiss_optional_update_usecase.dart';
import 'package:wowcare/domain/features/app_update/usecases/open_app_store_usecase.dart';
import 'package:wowcare/presentation/features/app_update/view_model/app_update_cubit.dart';

/// A scriptable [AppUpdateRepository] for the cubit and widget tests.
class FakeAppUpdateRepository implements AppUpdateRepository {
  FakeAppUpdateRepository({
    this.installedBuild = 25,
    this.cachedPolicy = AppUpdatePolicy.none,
    AppUpdatePolicy? freshPolicy,
    this.opens = true,
  }) : freshPolicy = freshPolicy ?? cachedPolicy;

  int installedBuild;
  AppUpdatePolicy cachedPolicy;
  AppUpdatePolicy freshPolicy;
  bool opens;
  bool throwOnPolicy = false;

  int refreshes = 0;
  final List<String?> openedUrls = <String?>[];
  final List<int> dismissedBuilds = <int>[];

  @override
  StorePlatform get store => StorePlatform.appStore;

  @override
  Future<AppVersion> getInstalledVersion() async =>
      AppVersion(name: '2.2.21', build: installedBuild);

  @override
  Future<AppUpdatePolicy> getPolicy({required bool refresh}) async {
    if (throwOnPolicy) throw StateError('config unreadable');
    if (refresh) refreshes++;
    return refresh ? freshPolicy : cachedPolicy;
  }

  @override
  Future<DateTime?> optionalDismissedAt({required int latestBuild}) async =>
      null;

  @override
  Future<void> saveOptionalDismissal({
    required int latestBuild,
    required DateTime at,
  }) async => dismissedBuilds.add(latestBuild);

  @override
  Future<bool> openStore(String? url) async {
    openedUrls.add(url);
    return opens;
  }
}

AppUpdateCubit cubitOver(AppUpdateRepository repository) => AppUpdateCubit(
  checkAppUpdate: CheckAppUpdateUseCase(repository),
  dismissOptionalUpdate: DismissOptionalUpdateUseCase(repository),
  openAppStore: OpenAppStoreUseCase(repository),
);

const AppUpdatePolicy optionalFor25 = AppUpdatePolicy(
  minimumBuild: 20,
  latestBuild: 26,
  latestVersionName: '2.3.0',
);

const AppUpdatePolicy requiredFor25 = AppUpdatePolicy(
  minimumBuild: 26,
  latestBuild: 26,
  latestVersionName: '3.0.0',
);
