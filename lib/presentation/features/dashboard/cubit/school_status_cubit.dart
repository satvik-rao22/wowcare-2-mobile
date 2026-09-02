import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_school_capacity_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_count_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_school_fte_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_counts_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_expected_summary.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom_count.dart';
import 'package:wowcare/domain/features/classroom/entities/school_fte.dart';

part 'school_status_state.dart';

class SchoolStatusCubit extends Cubit<SchoolStatusState> {
  SchoolStatusCubit({
    required GetStudentCountsUseCase getStudentCountsUseCase,
    required GetSchoolCapacityUseCase getSchoolCapacityUseCase,
    required GetClassroomCountUseCase getClassroomCountUseCase,
    required GetSchoolFteUseCase getSchoolFteUseCase,
    required GetStaffAttendanceExpectedSummaryUseCase
    getStaffAttendanceExpectedSummaryUseCase,
    required GetStudentAttendanceExpectedSummaryUseCase
    getStudentAttendanceExpectedSummaryUseCase,
    required CacheManager cacheManager,
  }) : _getStudentCountsUseCase = getStudentCountsUseCase,
       _getSchoolCapacityUseCase = getSchoolCapacityUseCase,
       _getClassroomCountUseCase = getClassroomCountUseCase,
       _getSchoolFteUseCase = getSchoolFteUseCase,
       _getStaffAttendanceExpectedSummaryUseCase =
           getStaffAttendanceExpectedSummaryUseCase,
       _getStudentAttendanceExpectedSummaryUseCase =
           getStudentAttendanceExpectedSummaryUseCase,
       _cacheManager = cacheManager,
       super(const SchoolStatusState.initial());

  final GetStudentCountsUseCase _getStudentCountsUseCase;
  final GetSchoolCapacityUseCase _getSchoolCapacityUseCase;
  final GetClassroomCountUseCase _getClassroomCountUseCase;
  final GetSchoolFteUseCase _getSchoolFteUseCase;
  final GetStaffAttendanceExpectedSummaryUseCase
  _getStaffAttendanceExpectedSummaryUseCase;
  final GetStudentAttendanceExpectedSummaryUseCase
  _getStudentAttendanceExpectedSummaryUseCase;
  final CacheManager _cacheManager;

  bool _isFetching = false;

  Future<void> loadSchoolStatus({
    required String schoolCode,
    bool forceRefresh = false,
    bool isSilent = false,
  }) async {
    final code = schoolCode.trim();
    if (code.isEmpty) {
      emit(const SchoolStatusState.initial());
      return;
    }

    // Prevent concurrent requests
    if (_isFetching) return;
    _isFetching = true;

    // Show visual loading only if we do not already have data and are NOT doing a silent update
    // If it's a forceRefresh, we want to clear everything and show the shimmer
    if (!isSilent && (!state.isLoaded || forceRefresh)) {
      emit(
        SchoolStatusState(
          status: SchoolStatusEnum.loading,
          schoolCode: forceRefresh ? '' : state.schoolCode,
          activeCount: forceRefresh ? 0 : state.activeCount,
          upcomingCount: forceRefresh ? 0 : state.upcomingCount,
          enrolledCount: forceRefresh ? 0 : state.enrolledCount,
          capacity: forceRefresh ? 0 : state.capacity,
          minAgeMonths: forceRefresh ? 0 : state.minAgeMonths,
          maxAgeMonths: forceRefresh ? 0 : state.maxAgeMonths,
          totalClassrooms: forceRefresh ? 0 : state.totalClassrooms,
          adminClassrooms: forceRefresh ? 0 : state.adminClassrooms,
          classroomClassrooms: forceRefresh ? 0 : state.classroomClassrooms,
          schoolFte: forceRefresh ? 0.0 : state.schoolFte,
          staffExpected: forceRefresh ? 0 : state.staffExpected,
          staffPresent: forceRefresh ? 0 : state.staffPresent,
          staffAbsent: forceRefresh ? 0 : state.staffAbsent,
          staffSignOut: forceRefresh ? 0 : state.staffSignOut,
          staffNotMarked: forceRefresh ? 0 : state.staffNotMarked,
          studentExpected: forceRefresh ? 0 : state.studentExpected,
          studentPresent: forceRefresh ? 0 : state.studentPresent,
          studentAbsent: forceRefresh ? 0 : state.studentAbsent,
          studentSignOut: forceRefresh ? 0 : state.studentSignOut,
          studentNotMarked: forceRefresh ? 0 : state.studentNotMarked,
          errorMessage: null,
        ),
      );
    }

    try {
      // If we are forcing a refresh, invalidate the cache keys first
      if (forceRefresh) {
        final keys = [
          CacheManager.buildCacheKey(
            feature: 'student',
            resource: 'counts',
            identifier: code,
          ),
          CacheManager.buildCacheKey(
            feature: 'classroom',
            resource: 'school_capacity',
            identifier: code,
          ),
          CacheManager.buildCacheKey(
            feature: 'classroom',
            resource: 'classroom_count',
            identifier: '${code}_ACTIVE',
          ),
          CacheManager.buildCacheKey(
            feature: 'attendance',
            resource: 'student_summary',
            identifier: 'school_wide',
          ),
          CacheManager.buildCacheKey(
            feature: 'attendance',
            resource: 'staff_summary',
            identifier: 'school_wide',
          ),
        ];
        await _cacheManager.invalidateCaches(keys);
      }

      // 1. Capacity must resolve first — FTE depends on its value — but it's
      // typically a cheap lookup, so fetch it alone rather than letting the
      // slower attendance-summary calls below also block the FTE request.
      final capacity = await _getSchoolCapacityUseCase(schoolCode: code);

      // Invalidate the FTE cache key with the fresh capacity if we are forcing a refresh
      if (forceRefresh) {
        final fteKey = CacheManager.buildCacheKey(
          feature: 'classroom',
          resource: 'school_fte',
          identifier: '${code}_${capacity.capacity}',
        );
        await _cacheManager.invalidateCache(fteKey);
      }

      // 2. Run every remaining independent request — including the now-ready
      // FTE call — in parallel instead of serializing FTE after the rest.
      final results = await Future.wait([
        _getStudentCountsUseCase(schoolCode: code),
        _getClassroomCountUseCase(schoolCode: code, status: 'ACTIVE'),
        _getStaffAttendanceExpectedSummaryUseCase(
          classroomCode: null,
          schoolWide: true,
        ),
        _getStudentAttendanceExpectedSummaryUseCase(
          classroomCode: null,
          schoolWide: true,
        ),
        _getSchoolFteUseCase(schoolCode: code, capacity: capacity.capacity),
      ]);

      final studentCounts =
          results[0]
              as ({int activeCount, int upcomingCount, int enrolledCount});
      final classroomCount = results[1] as ClassroomCount;
      final staffSummary = results[2] as StudentAttendanceExpectedSummary;
      final studentSummary = results[3] as StudentAttendanceExpectedSummary;
      final fte = results[4] as SchoolFte;

      if (!isClosed) {
        emit(
          SchoolStatusState.loaded(
            schoolCode: code,
            activeCount: studentCounts.activeCount,
            upcomingCount: studentCounts.upcomingCount,
            enrolledCount: studentCounts.enrolledCount,
            capacity: capacity.capacity,
            minAgeMonths: capacity.minAgeMonths,
            maxAgeMonths: capacity.maxAgeMonths,
            totalClassrooms: classroomCount.total,
            adminClassrooms: classroomCount.adminCount,
            classroomClassrooms: classroomCount.classroomCount,
            schoolFte: fte.schoolFte,
            staffExpected: staffSummary.expected,
            staffPresent: staffSummary.present,
            staffAbsent: staffSummary.absent,
            staffSignOut: staffSummary.signOut,
            staffNotMarked: staffSummary.notMarked,
            studentExpected: studentSummary.expected,
            studentPresent: studentSummary.present,
            studentAbsent: studentSummary.absent,
            studentSignOut: studentSummary.signOut,
            studentNotMarked: studentSummary.notMarked,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SchoolStatusEnum.error,
            errorMessage: ApiErrorHandler.extractErrorMessage(e),
          ),
        );
      }
    } finally {
      _isFetching = false;
    }
  }
}
