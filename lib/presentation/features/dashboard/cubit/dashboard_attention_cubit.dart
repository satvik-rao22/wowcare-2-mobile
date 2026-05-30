import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

part 'dashboard_attention_state.dart';

/// Aggregates the three "Need your attention" summary APIs:
///
/// 1. `GET /api/v1/individual-movements/status-counts`
/// 2. `GET /api/v1/staff-documents/expiry-summary`
/// 3. `GET /api/v1/staff-dates/physical-checkup-summary`
///
/// All three are fetched in parallel via [Future.wait]. A failure in any one
/// API does not block the others — partial results are emitted as
/// [DashboardAttentionStatus.partialFailure] so the dashboard stays useful.
class DashboardAttentionCubit extends Cubit<DashboardAttentionState> {
  DashboardAttentionCubit({
    required AvailabilityRepository availabilityRepository,
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _availabilityRepository = availabilityRepository,
        _staffRepository = staffRepository,
        _storageService = storageService,
        super(const DashboardAttentionState());

  final AvailabilityRepository _availabilityRepository;
  final StaffRepository _staffRepository;
  final StorageService _storageService;

  bool _isFetching = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// First open: shows shimmer while loading.
  /// Background revisit: silent update, no shimmer.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    final schoolCode = await _storageService.getString(StorageKeys.schoolCode);
    if (schoolCode == null || schoolCode.trim().isEmpty) {
      emit(state.copyWith(status: DashboardAttentionStatus.loaded));
      _isFetching = false;
      return;
    }

    if (!isSilent && state.isInitial) {
      emit(state.copyWith(status: DashboardAttentionStatus.loading));
    }

    await _fetch(schoolCode.trim());
    _isFetching = false;
  }

  /// Pull-to-refresh: keeps existing data visible while re-fetching.
  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;

    final schoolCode = await _storageService.getString(StorageKeys.schoolCode);
    if (schoolCode == null || schoolCode.trim().isEmpty) {
      _isFetching = false;
      return;
    }

    if (state.isLoaded) {
      emit(state.copyWith(status: DashboardAttentionStatus.refreshing));
    }

    await _fetch(schoolCode.trim());
    _isFetching = false;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _fetch(String schoolCode) async {
    final now = DateTime.now();
    final fromDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final toDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Run all three in parallel; capture individual errors so one failure
    // does not suppress the other two results.
    final results = await Future.wait(
      [
        _availabilityRepository
            .getMovementStatusCounts(
              schoolCode: schoolCode,
              fromDate: fromDate,
              toDate: toDate,
            )
            .then<Object?>((v) => v)
            .onError((_, __) => null),
        _staffRepository
            .getStaffDocumentExpirySummary(schoolCode: schoolCode)
            .then<Object?>((v) => v)
            .onError((_, __) => null),
        _staffRepository
            .getPhysicalCheckupSummary(schoolCode: schoolCode)
            .then<Object?>((v) => v)
            .onError((_, __) => null),
      ],
      eagerError: false,
    );

    final movementResult =
        results[0] as ({int pendingCount, int overdueCount})?;
    final docResult = results[1]
        as ({int expiredDocumentCount, int expiringWithinWeekCount})?;
    final checkupResult = results[2] as ({
      int overduePhysicalCheckupCount,
      int staffWithoutActivePhysicalCheckupCount
    })?;

    final anyFailed =
        movementResult == null || docResult == null || checkupResult == null;

    emit(state.copyWith(
      status: anyFailed
          ? DashboardAttentionStatus.partialFailure
          : DashboardAttentionStatus.loaded,
      pendingMovements: movementResult?.pendingCount ?? state.pendingMovements,
      overdueMovements: movementResult?.overdueCount ?? state.overdueMovements,
      expiredDocuments:
          docResult?.expiredDocumentCount ?? state.expiredDocuments,
      expiringDocuments:
          docResult?.expiringWithinWeekCount ?? state.expiringDocuments,
      overdueCheckups:
          checkupResult?.overduePhysicalCheckupCount ?? state.overdueCheckups,
      missingCheckups:
          checkupResult?.staffWithoutActivePhysicalCheckupCount ??
              state.missingCheckups,
    ));
  }
}
