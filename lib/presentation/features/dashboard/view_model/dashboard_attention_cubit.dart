import 'package:bloc/bloc.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/modules/attendance_regularization/regularization.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_overview_usecase.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
part 'dashboard_attention_state.dart';

/// Aggregates six "Need your attention" summary APIs:
///
/// 1. `GET /api/v2/activities/admin/activities/pending-incident-count`
/// 2. `GET /api/v1/individual-movements/status-counts`
/// 3. `GET /api/v1/staff-documents/expiry-summary`
/// 4. `GET /api/v1/staff-dates/physical-checkup-summary`
/// 5. `GET /api/v1/student/student-documents/expiry-count`
/// 6. `GET /api/v1/student/student/physical-checkup-count/{schoolCode}`
/// 7. `GET /invoices/overview` (no date range — all-time outstanding balance)
///
/// All seven are fetched in parallel via [Future.wait]. A failure in any one
/// API does not block the others — partial results are emitted as
/// [DashboardAttentionStatus.partialFailure] so the dashboard stays useful.
class DashboardAttentionCubit extends Cubit<DashboardAttentionState> {
  DashboardAttentionCubit({
    required ActivityRepository activityRepository,
    required AvailabilityRepository availabilityRepository,
    required StaffRepository staffRepository,
    required StudentRepository studentRepository,
    required StorageService storageService,
    required GetInvoiceOverviewUseCase getInvoiceOverview,
  }) : _activityRepository = activityRepository,
       _availabilityRepository = availabilityRepository,
       _staffRepository = staffRepository,
       _studentRepository = studentRepository,
       _storageService = storageService,
       _getInvoiceOverview = getInvoiceOverview,
       super(const DashboardAttentionState());

  final ActivityRepository _activityRepository;
  final AvailabilityRepository _availabilityRepository;
  final StaffRepository _staffRepository;
  final StudentRepository _studentRepository;
  final StorageService _storageService;
  final GetInvoiceOverviewUseCase _getInvoiceOverview;

  bool _isFetching = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// First open: shows shimmer while loading.
  /// Background revisit: silent update, no shimmer.
  ///
  /// When [isSilent] is true and data is already loaded, the call is a no-op
  /// — prevents redundant API calls on every dashboard re-entry.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    // Silent revisit: skip entirely if we already have fresh data.
    if (isSilent && state.isLoaded) return;

    _isFetching = true;

    final schoolCode = await _storageService.getString(StorageKeys.schoolCode);
    if (schoolCode == null || schoolCode.trim().isEmpty) {
      // Not `loaded` — that would permanently block future silent retries
      // (see `isLoaded`'s silent-revisit guard above) once the school code
      // actually becomes available.
      emit(
        state.copyWith(status: DashboardAttentionStatus.awaitingSchoolContext),
      );
      _isFetching = false;
      return;
    }

    final wasNotYetLoaded =
        state.isInitial ||
        state.status == DashboardAttentionStatus.awaitingSchoolContext;
    if (!isSilent && wasNotYetLoaded) {
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
    final now = AppTime.now();
    final fromDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    // Last day of current month: day-0 of the next month = last day of this month.
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final toDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDayOfMonth.toString().padLeft(2, '0')}';
    final organizationCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();

    // Run all seven in parallel; capture individual errors so one failure
    // does not suppress the other results.
    final results = await Future.wait([
      _activityRepository
          .getPendingIncidentCount()
          .then<Object?>((v) => v)
          .onError((_, __) => null),
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
      _studentRepository
          .getStudentDocumentExpiryCount(schoolCode: schoolCode)
          .then<Object?>((v) => v)
          .onError((_, __) => null),
      _studentRepository
          .getStudentPhysicalCheckupCount(schoolCode: schoolCode)
          .then<Object?>((v) => v)
          .onError((_, __) => null),
      organizationCode.isEmpty
          ? Future<Object?>.value(null)
          : _getInvoiceOverview(
              organizationCode: organizationCode,
              school: schoolCode,
            ).then<Object?>((v) => v).onError((_, __) => null),
    ], eagerError: false);

    final regularizationCount =
        await Regularization.pendingApprovalCount(serviceLocator);

    final incidentResult = results[0] as int?;
    final movementResult =
        results[1] as ({int pendingCount, int overdueCount})?;
    final staffDocResult =
        results[2]
            as ({int expiredDocumentCount, int expiringWithinWeekCount})?;
    final staffCheckupResult =
        results[3]
            as ({
              int overduePhysicalCheckupCount,
              int staffWithoutActivePhysicalCheckupCount,
            })?;
    final studentDocResult =
        results[4]
            as ({
              int expiredDocumentCount,
              int expiringWithinWeekCount,
              int totalDocumentsWithExpiry,
            })?;
    final studentCheckupResult =
        results[5]
            as ({int overdueExamCount, int studentsWithoutActiveExamCount})?;
    final invoiceOverviewResult = results[6] as InvoiceOverviewEntity?;

    final anyFailed =
        incidentResult == null ||
        movementResult == null ||
        staffDocResult == null ||
        staffCheckupResult == null ||
        studentDocResult == null ||
        studentCheckupResult == null ||
        invoiceOverviewResult == null;

    emit(
      state.copyWith(
        status: anyFailed
            ? DashboardAttentionStatus.partialFailure
            : DashboardAttentionStatus.loaded,
        pendingIncidents: incidentResult ?? state.pendingIncidents,
        pendingRegularizations: regularizationCount,
        pendingMovements:
            movementResult?.pendingCount ?? state.pendingMovements,
        overdueMovements:
            movementResult?.overdueCount ?? state.overdueMovements,
        expiredDocuments:
            staffDocResult?.expiredDocumentCount ?? state.expiredDocuments,
        expiringDocuments:
            staffDocResult?.expiringWithinWeekCount ?? state.expiringDocuments,
        expiredStudentDocuments:
            studentDocResult?.expiredDocumentCount ??
            state.expiredStudentDocuments,
        expiringStudentDocuments:
            studentDocResult?.expiringWithinWeekCount ??
            state.expiringStudentDocuments,
        overdueCheckups:
            staffCheckupResult?.overduePhysicalCheckupCount ??
            state.overdueCheckups,
        missingCheckups:
            staffCheckupResult?.staffWithoutActivePhysicalCheckupCount ??
            state.missingCheckups,
        overdueStudentCheckups:
            studentCheckupResult?.overdueExamCount ??
            state.overdueStudentCheckups,
        missingStudentCheckups:
            studentCheckupResult?.studentsWithoutActiveExamCount ??
            state.missingStudentCheckups,
        outstandingAmount:
            invoiceOverviewResult?.outstanding ?? state.outstandingAmount,
      ),
    );
  }
}
