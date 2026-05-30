import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

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

  Future<void> loadForChild({required String studentCode}) async {
    final code = studentCode.trim();
    if (code.isEmpty) {
      _stopClock();
      emit(const MyChildsDayState.initial());
      return;
    }

    if (state.studentCode == code && state.status == MyChildsDayStatus.loaded) {
      return;
    }

    _stopClock();
    emit(
      state.copyWith(
        status: MyChildsDayStatus.loading,
        studentCode: code,
        guardianClockPin: '',
      ),
    );

    try {
      final profile = await _getStudentProfileUseCase(code: code);
      final tz = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: _apiClient,
      );

      final todayKey = _schoolDowKey(tz);
      final todayRange = (profile.scheduleByDay[todayKey] ?? '').trim();

      var guardianClockPin = '';
      try {
        final guardians =
            await _studentRepository.getStudentGuardians(studentCode: code);
        final primary = guardians.where((g) => g.primaryContact).firstOrNull;
        final withPin = guardians
            .where((g) => (g.clockPin ?? '').trim().isNotEmpty)
            .toList();
        guardianClockPin =
            (primary?.clockPin ?? (withPin.firstOrNull?.clockPin ?? ''))
                .trim();
      } catch (_) {
        // Non-blocking: pin is optional for dashboard display.
      }

      emit(
        state.copyWith(
          status: MyChildsDayStatus.loaded,
          studentCode: code,
          fullName: profile.fullName.trim(),
          classroomName: (profile.classroomName ?? '').trim(),
          schoolCode: profile.schoolCode.trim(),
          schoolTimeZone: tz,
          todayDayOfWeek: todayKey,
          todayScheduleRange: todayRange,
          schoolNow: SchoolZoneDateTime.dateTimeFromInstantInSchool(
            DateTime.now().toUtc(),
            tz,
          ),
          guardianClockPin: guardianClockPin,
          errorMessage: '',
        ),
      );

      _startClock(tz);
    } catch (e) {
      emit(
        state.copyWith(
          status: MyChildsDayStatus.error,
          studentCode: code,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _startClock(String iana) {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != MyChildsDayStatus.loaded) return;
      emit(
        state.copyWith(
          schoolNow: SchoolZoneDateTime.dateTimeFromInstantInSchool(
            DateTime.now().toUtc(),
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

  String _schoolDowKey(String iana) {
    final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
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
