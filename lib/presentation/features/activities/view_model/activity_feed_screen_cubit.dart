import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';

/// ViewModel seam for [ActivityFeedScreen] — currently just the staff
/// today-sign-in-status check that gates the Add-activity FAB. `ActivityEditorCubit`
/// doesn't fit here (this isn't an edit screen); this is deliberately small
/// rather than folded into a larger cubit.
class ActivityFeedScreenCubit extends Cubit<ActivityFeedScreenState> {
  ActivityFeedScreenCubit({
    required StorageService storageService,
    required GetStaffTodaySignInStatusUseCase getStaffTodaySignInStatusUseCase,
  }) : _storage = storageService,
       _getStaffTodaySignInStatusUseCase = getStaffTodaySignInStatusUseCase,
       super(const ActivityFeedScreenState());

  final StorageService _storage;
  final GetStaffTodaySignInStatusUseCase _getStaffTodaySignInStatusUseCase;

  /// Today's sign-in status for the logged-in staff member (falls back to
  /// `userCode` when `staffCode` isn't set, mirrors the My Day card's
  /// `_effectiveStaffCode` fallback) — `null`/empty when neither is resolved
  /// or the status check fails (best-effort: caller should treat that as "not
  /// gated" rather than blocking activity creation on a failed check).
  Future<String?> getEffectiveStaffTodaySignInStatus() async {
    final staffCode =
        (await _storage.getString(StorageKeys.staffCode))?.trim() ?? '';
    final userCode =
        (await _storage.getString(StorageKeys.userCode))?.trim() ?? '';
    final effectiveCode = staffCode.isNotEmpty ? staffCode : userCode;
    if (effectiveCode.isEmpty) return null;
    return _getStaffTodaySignInStatusUseCase(staffCode: effectiveCode);
  }
}

/// Stateless marker state — this cubit is a data facade; the screen keeps its
/// own field/UI state.
class ActivityFeedScreenState extends Equatable {
  const ActivityFeedScreenState();

  @override
  List<Object?> get props => const <Object?>[];
}
