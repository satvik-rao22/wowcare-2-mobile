import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';
import 'package:wowcare/core/util/server_time_service.dart';

part 'my_day_state.dart';

/// Fetches the school's regular schedule and resolves today's active entry.
///
/// Reuses the existing [StaffRepository.getSchoolRegularSchedules] call —
/// no new datasource or API path is needed.
///
/// Load strategy mirrors the other dashboard cubits:
/// - First open (`isInitial`): shows shimmer.
/// - Navigation revisit (`isSilent = true`): silently refreshes, no shimmer.
/// - Pull-to-refresh: preserves existing data while re-fetching.
class MyDayCubit extends Cubit<MyDayState> {
  MyDayCubit({
    required StaffRepository staffRepository,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _staffRepository = staffRepository,
       _storageService = storageService,
       _apiClient = apiClient,
       super(const MyDayState());

  final StaffRepository _staffRepository;
  final StorageService _storageService;
  final ApiClient _apiClient;

  bool _isFetching = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// First-open or navigation-revisit load.
  ///
  /// [isSilent] = true skips shimmer when data is already present (revisit).
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!isSilent && state.isInitial) {
      emit(state.copyWith(status: MyDayStatus.loading));
    }

    await _fetch();
    _isFetching = false;
  }

  /// Pull-to-refresh — keeps current data visible while re-fetching.
  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    await _fetch();
    _isFetching = false;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _fetch() async {
    final schoolCode = await _storageService.getString(StorageKeys.schoolCode);
    if (schoolCode == null || schoolCode.trim().isEmpty) {
      emit(
        state.copyWith(
          status: MyDayStatus.loaded,
          schoolClosed: true,
          clearTodaySchedule: true,
          clearWorkSchedule: true,
          clearBreakSchedule: true,
        ),
      );
      return;
    }

    // Use the canonical resolver — handles stale cache, context validation,
    // and admin/director accounts that may not have a cached staffCode.
    // If the resolver fails (e.g. getStaffCodeForUser API down), it clears the
    // cached staffCode and returns ''. In that case fall back to the raw cached
    // value so the staff profile can still be fetched for the schedule display.
    String staffCode = await resolveStaffCodeForLoggedInUser();
    if (staffCode.isEmpty) {
      staffCode = (await _storageService.getString(StorageKeys.staffCode) ?? '')
          .trim();
    }

    try {
      // Fetch school schedule and staff schedules in parallel.
      // Staff schedule failure is swallowed — we fall back to school schedule.
      final schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: _apiClient,
      );
      final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        ServerTimeService.instance.nowUtc(),
        schoolIana,
      );
      final todayKey = SchoolHoursResolver.dayOfWeekKey(schoolNow);

      final results = await Future.wait([
        _staffRepository
            .getSchoolRegularSchedules(schoolCode: schoolCode.trim())
            .then<Object?>((v) => v)
            .onError((_, __) => null),
        staffCode.isNotEmpty
            ? _staffRepository
                  .getStaffSchedules(staffCode: staffCode)
                  .then<Object?>((v) => v)
                  .onError((_, __) => null)
            : Future.value(null),
      ], eagerError: false);

      final days =
          results[0] as List<SchoolRegularScheduleDay>? ??
          <SchoolRegularScheduleDay>[];
      final staffSchedules =
          results[1]
              as ({
                List<StaffProfileWorkSchedule> workSchedules,
                List<StaffProfileBreakSchedule> breakSchedules,
              })?;

      // School schedule for today.
      SchoolRegularScheduleDay? todayEntry;
      for (final d in days) {
        if (d.dayOfWeek.toUpperCase() == todayKey) {
          todayEntry = d;
          break;
        }
      }

      // Staff's personal work schedule for today from the dedicated schedule API.
      StaffProfileWorkSchedule? todayWorkSchedule;
      StaffProfileBreakSchedule? todayBreakSchedule;
      if (staffSchedules != null) {
        for (final ws in staffSchedules.workSchedules) {
          if (!_matchesDay(ws.dayOfWeek, todayKey)) continue;
          final isSet =
              ws.workStartTime.hour != 0 ||
              ws.workStartTime.minute != 0 ||
              ws.workEndTime.hour != 0 ||
              ws.workEndTime.minute != 0;
          if (isSet) todayWorkSchedule = ws;
          break;
        }
        for (final bs in staffSchedules.breakSchedules) {
          if (_matchesDay(bs.dayOfWeek, todayKey)) {
            todayBreakSchedule = bs;
            break;
          }
        }
      }

      final bool closed = todayEntry == null || !todayEntry.isActive;

      AppLogger.d(
        '[MyDayCubit] today=$todayKey '
        'schoolEntry=${todayEntry?.dayOfWeek} closed=$closed '
        'staffWork=${todayWorkSchedule?.dayOfWeek}',
      );

      emit(
        state.copyWith(
          status: MyDayStatus.loaded,
          todaySchedule: closed ? null : todayEntry,
          todayWorkSchedule: todayWorkSchedule,
          todayBreakSchedule: todayBreakSchedule,
          allSchoolSchedules: days,
          allWorkSchedules: staffSchedules?.workSchedules ?? [],
          allBreakSchedules: staffSchedules?.breakSchedules ?? [],
          schoolClosed: closed,
          schoolTimeZone: schoolIana,
          clearTodaySchedule: closed,
          clearWorkSchedule: todayWorkSchedule == null,
          clearBreakSchedule: todayBreakSchedule == null,
        ),
      );
    } catch (e) {
      AppLogger.e('[MyDayCubit] fetch failed: $e');
      emit(
        state.copyWith(status: MyDayStatus.error, errorMessage: ApiErrorHandler.extractErrorMessage(e)),
      );
    }
  }

  /// Returns true when [dayOfWeek] (from the API — may be "TUESDAY" or "TUE")
  /// matches [todayKey] (always a full uppercase name like "TUESDAY").
  static bool _matchesDay(String dayOfWeek, String todayKey) {
    final upper = dayOfWeek.trim().toUpperCase();
    if (upper == todayKey) return true;
    // Allow 3-letter abbreviation: "TUE" matches "TUESDAY" etc.
    return todayKey.startsWith(upper) && upper.length == 3;
  }
}
