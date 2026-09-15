import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/sign_in_pin_resolver.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/scheduling/services/school_hours_resolver.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

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
    required GetStaffTodaySignInStatusUseCase getStaffTodaySignInStatus,
  }) : _staffRepository = staffRepository,
       _storageService = storageService,
       _apiClient = apiClient,
       _getStaffTodaySignInStatus = getStaffTodaySignInStatus,
       super(const MyDayState());

  final StaffRepository _staffRepository;
  final StorageService _storageService;
  final ApiClient _apiClient;
  final GetStaffTodaySignInStatusUseCase _getStaffTodaySignInStatus;

  bool _isFetching = false;

  /// Invalidates in-flight identity work when the persona switches, so a slow
  /// response for the previous staff member can never land on the new one.
  /// Carried over from the widget this state came from.
  int _profileGeneration = 0;

  /// The same guard for the PIN fetch, which races independently of identity.
  int _pinGeneration = 0;

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

  // ---------------------------------------------------------------------------
  // Staff identity + today's sign-in status
  //
  // Mandate 2 bucket A. This ran in `_MyDayCardState` across six `setState`
  // calls, reading StorageService and GetStaffTodaySignInStatusUseCase
  // directly from the widget (§2.4, and a Mandate 5 violation besides). The
  // logic is carried over unchanged, including the `_profileGeneration` token
  // that discards stale responses after a persona switch.
  // ---------------------------------------------------------------------------

  /// Fetches the staff member's clock-in PIN from the API.
  ///
  /// This used to read `StorageKeys.staffPin`, a snapshot written once at
  /// login — so a PIN changed on the web kept showing its old value on the
  /// card until the user logged out and back in. Nothing is stored now; every
  /// load and every pull-to-refresh asks the API.
  ///
  /// A failed fetch leaves the current PIN on screen rather than blanking it.
  Future<void> loadClockPin() async {
    final generation = ++_pinGeneration;

    final pin = await fetchSignInPinForLoggedInUser(
      staffRepository: _staffRepository,
      storageService: _storageService,
    );

    // Discard a slow response that lost its race with a persona switch, the
    // same way [loadStaffIdentity] guards its own.
    if (isClosed || generation != _pinGeneration || pin == null) return;
    emit(state.copyWith(clockInPin: pin));
  }

  /// Loads staff identity and today's sign-in status in one pass so button
  /// taps never hit a timing window where storage hasn't resolved yet.
  ///
  /// Returns the resolved `isSignedIn` when the status fetch succeeded, or null
  /// when it was skipped or failed — the view uses it to sync GeofenceCubit,
  /// which it must do itself because that is a cubit-to-cubit concern owned by
  /// the screen, not by this one.
  Future<bool?> loadStaffIdentity() async {
    final generation = ++_profileGeneration;

    String code = await resolveStaffCodeForLoggedInUser();
    if (code.isEmpty) {
      code =
          (await _storageService.getString(StorageKeys.staffCode))?.trim() ??
          '';
    }
    final userCode =
        (await _storageService.getString(StorageKeys.userCode))?.trim() ?? '';
    final name =
        (await _storageService.getString(StorageKeys.displayName) ?? '').trim();
    final designation =
        (await _storageService.getString(StorageKeys.staffDesignation) ?? '')
            .trim();
    if (isClosed || generation != _profileGeneration) return null;

    emit(
      state.copyWith(
        staffCode: code,
        userCode: userCode,
        staffDisplayName: name,
        staffDesignation: designation,
        staffIdentityLoaded: true,
      ),
    );

    final effectiveCode = state.effectiveStaffCode;
    if (effectiveCode.isEmpty) {
      if (!isClosed && generation == _profileGeneration) {
        emit(
          state.copyWith(
            clearTodayStatusRaw: true,
            isSignedIn: false,
            signInStatusLoaded: true,
          ),
        );
      }
      return null;
    }

    try {
      final status = await _getStaffTodaySignInStatus(staffCode: effectiveCode);
      if (isClosed || generation != _profileGeneration) return null;
      final signedIn = status?.toUpperCase() == 'SIGNED_IN';
      emit(
        state.copyWith(
          todayStatusRaw: status,
          clearTodayStatusRaw: status == null,
          isSignedIn: signedIn,
          signInStatusLoaded: true,
        ),
      );
      return signedIn;
    } catch (_) {
      // Sign-in status check is best-effort.
      if (!isClosed && generation == _profileGeneration) {
        emit(state.copyWith(signInStatusLoaded: true));
      }
      return null;
    }
  }

  /// Clears identity + status on a persona switch and invalidates any in-flight
  /// [loadStaffIdentity].
  void resetForProfileSwitch() {
    _profileGeneration++;
    if (isClosed) return;
    emit(
      state.copyWith(
        signInStatusLoaded: false,
        staffIdentityLoaded: false,
        clearTodayStatusRaw: true,
        isSignedIn: false,
        staffCode: '',
        userCode: '',
        staffDisplayName: '',
        staffDesignation: '',
      ),
    );
  }

  /// Pull-to-refresh — keeps current data visible while re-fetching.
  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    // The PIN rides along with pull-to-refresh: it is fetched, never stored,
    // so this is the user's way of picking up a PIN changed on the web. Both
    // dashboard coordinators (staff and admin) reach it through here.
    await Future.wait([_fetch(), loadClockPin()]);
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
        state.copyWith(
          status: MyDayStatus.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
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
