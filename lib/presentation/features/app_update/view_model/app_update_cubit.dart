import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/domain/features/app_update/usecases/check_app_update_usecase.dart';
import 'package:wowcare/domain/features/app_update/usecases/dismiss_optional_update_usecase.dart';
import 'package:wowcare/domain/features/app_update/usecases/open_app_store_usecase.dart';

part 'app_update_state.dart';

/// Owns the update check for the whole app. Provided once at the root, so
/// the required overlay covers every route, the kiosk included, and the
/// optional banner can sit in whichever dashboard is showing.
///
/// Fails open: if a check throws, the last state stands, and before the
/// first check completes that means nothing is shown. An update rule that
/// cannot be read must never lock a school out of sign-in.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit({
    required CheckAppUpdateUseCase checkAppUpdate,
    required DismissOptionalUpdateUseCase dismissOptionalUpdate,
    required OpenAppStoreUseCase openAppStore,
  }) : _checkAppUpdate = checkAppUpdate,
       _dismissOptionalUpdate = dismissOptionalUpdate,
       _openAppStore = openAppStore,
       super(const AppUpdateState());

  final CheckAppUpdateUseCase _checkAppUpdate;
  final DismissOptionalUpdateUseCase _dismissOptionalUpdate;
  final OpenAppStoreUseCase _openAppStore;

  Future<void>? _refreshing;

  /// The launch check. The rule fetched last time applies straight away,
  /// with no network, then a fresh fetch replaces it. Nothing about startup
  /// waits on either.
  Future<void> check() async {
    await _evaluate(refresh: false);
    await recheck();
  }

  /// Fetches the rule again, e.g. when the app returns to the foreground.
  /// Calls made while one is running share it.
  Future<void> recheck() => _refreshing ??= _evaluate(
    refresh: true,
  ).whenComplete(() => _refreshing = null);

  Future<void> _evaluate({required bool refresh}) async {
    try {
      final AppUpdateStatus status = await _checkAppUpdate(refresh: refresh);
      if (!isClosed) emit(state.copyWith(status: status));
    } catch (e) {
      AppLogger.w('[AppUpdate] check failed, showing nothing new: $e');
    }
  }

  /// "Not now" or the cross on the optional banner. Quiet for a week.
  Future<void> dismissOptional() async {
    final AppUpdateStatus? status = state.status;
    if (status == null || !status.isOptional) return;
    emit(state.copyWith(optionalDismissed: true, storeUnavailable: false));
    await _dismissOptionalUpdate(latestBuild: status.policy.latestBuild);
  }

  Future<void> openStore() async {
    final AppUpdateStatus? status = state.status;
    if (status == null) return;
    if (state.storeUnavailable) emit(state.copyWith(storeUnavailable: false));
    final bool opened = await _openAppStore(status.policy);
    if (!opened && !isClosed) emit(state.copyWith(storeUnavailable: true));
  }
}
