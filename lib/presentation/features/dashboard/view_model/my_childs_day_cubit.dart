import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/guardian_clock_pin_resolver.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule.dart';

import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

part 'my_childs_day_state.dart';

class MyChildsDayCubit extends Cubit<MyChildsDayState> {
  MyChildsDayCubit({
    required GetStudentProfileUseCase getStudentProfileUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
    required StudentRepository studentRepository,
  }) : _getStudentProfileUseCase = getStudentProfileUseCase,
       _storageService = storageService,
       _apiClient = apiClient,
       _studentRepository = studentRepository,
       super(const MyChildsDayState.initial());

  final GetStudentProfileUseCase _getStudentProfileUseCase;
  final StorageService _storageService;
  final ApiClient _apiClient;
  final StudentRepository _studentRepository;

  Timer? _clockTimer;

  void _safeEmit(MyChildsDayState state) {
    if (!isClosed) {
      try {
        emit(state);
      } catch (_) {}
    }
  }

  Future<void> loadForChild({
    required String studentCode,
    bool background = false,
  }) async {
    final code = studentCode.trim();
    if (code.isEmpty) {
      _stopClock();
      _safeEmit(const MyChildsDayState.initial());
      return;
    }

    // A normal call skips the refetch when the same child is already loaded; a
    // background refresh (pull-to-refresh) always refetches.
    if (!background &&
        state.studentCode == code &&
        state.status == MyChildsDayStatus.loaded) {
      return;
    }

    // Keep the current data on screen during a background refresh (no shimmer);
    // only show the loading placeholder for a normal first load.
    final hasData =
        state.studentCode == code && state.status == MyChildsDayStatus.loaded;
    _stopClock();
    if (!(background && hasData)) {
      _safeEmit(
        state.copyWith(
          status: MyChildsDayStatus.loading,
          studentCode: code,
          guardianClockPin: '',
        ),
      );
    }

    try {
      final tz = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: _apiClient,
      );
      if (isClosed) return;

      final results = await Future.wait([
        _getStudentProfileUseCase(
          code: code,
        ).then<Object?>((v) => v).onError((_, __) => null),
        _studentRepository
            .getStudentRegularSchedules(studentCode: code)
            .then<Object?>((v) => v)
            .onError((_, __) => <StudentRegularScheduleEntry>[]),
      ], eagerError: false);
      if (isClosed) return;

      final profile = results[0];
      final regularSchedules =
          (results[1] as List<StudentRegularScheduleEntry>?) ??
          <StudentRegularScheduleEntry>[];

      final todayKey = _schoolDowKey(tz);

      // Derive todayScheduleRange from the dedicated schedule API.
      String todayRange = '';
      for (final entry in regularSchedules) {
        if (entry.dayOfWeek.toUpperCase() == todayKey) {
          final startLabel = _fmtHM(entry.startHour, entry.startMinute);
          final endLabel = _fmtHM(entry.endHour, entry.endMinute);
          todayRange = '$startLabel - $endLabel';
          break;
        }
      }

      var guardianClockPin = '';
      try {
        // forceRefresh skips the 5-minute guardians cache. The guardian's
        // sign-in PIN is read off this response, and a cached copy meant a
        // PIN changed on the web kept showing its old value — nothing
        // invalidates that cache on a PIN change, because no PIN update ever
        // passes through this app.
        final guardians = await _studentRepository.getStudentGuardians(
          studentCode: code,
          forceRefresh: true,
        );
        final loggedInUserCode =
            (await _storageService.getString(StorageKeys.userCode) ?? '')
                .trim();
        final loggedInGuardianCode =
            (await _storageService.getString(StorageKeys.guardianCode) ?? '')
                .trim();

        // Shared with the app bar's kebab menu, so the PIN on this card and the
        // one in the menu can't drift apart.
        guardianClockPin = selectGuardianClockPin(
          guardians: guardians,
          loggedInUserCode: loggedInUserCode,
          loggedInGuardianCode: loggedInGuardianCode,
        );
      } catch (_) {
        // Non-blocking: pin is optional for dashboard display.
      }

      final typedProfile = profile as dynamic;
      _safeEmit(
        state.copyWith(
          status: MyChildsDayStatus.loaded,
          studentCode: code,
          fullName: (typedProfile?.fullName as String? ?? '').trim(),
          classroomName: ((typedProfile?.classroomName as String?) ?? '')
              .trim(),
          schoolCode: (typedProfile?.schoolCode as String? ?? '').trim(),
          schoolTimeZone: tz,
          todayDayOfWeek: todayKey,
          todayScheduleRange: todayRange,
          allRegularSchedules: regularSchedules,
          schoolNow: SchoolZoneDateTime.dateTimeFromInstantInSchool(
            ServerTimeService.instance.nowUtc(),
            tz,
          ),
          guardianClockPin: guardianClockPin,
          errorMessage: '',
        ),
      );

      _startClock(tz);
    } catch (e) {
      // A failed background refresh keeps the stale-but-valid data on screen
      // rather than replacing the card with an error state.
      if (background && hasData) {
        _startClock(state.schoolTimeZone);
        return;
      }
      _safeEmit(
        state.copyWith(
          status: MyChildsDayStatus.error,
          studentCode: code,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void _startClock(String iana) {
    if (isClosed) return;
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) {
        _stopClock();
        return;
      }
      if (state.status != MyChildsDayStatus.loaded) return;
      _safeEmit(
        state.copyWith(
          schoolNow: SchoolZoneDateTime.dateTimeFromInstantInSchool(
            ServerTimeService.instance.nowUtc(),
            iana,
          ),
        ),
      );
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  static String _fmtHM(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  String _schoolDowKey(String iana) {
    final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      ServerTimeService.instance.nowUtc(),
      iana,
    );
    switch (schoolNow.weekday) {
      case DateTime.monday:
        return 'MONDAY';
      case DateTime.tuesday:
        return 'TUESDAY';
      case DateTime.wednesday:
        return 'WEDNESDAY';
      case DateTime.thursday:
        return 'THURSDAY';
      case DateTime.friday:
        return 'FRIDAY';
      case DateTime.saturday:
        return 'SATURDAY';
      case DateTime.sunday:
        return 'SUNDAY';
    }
    return 'MONDAY';
  }

  @override
  Future<void> close() {
    _stopClock();
    return super.close();
  }
}
