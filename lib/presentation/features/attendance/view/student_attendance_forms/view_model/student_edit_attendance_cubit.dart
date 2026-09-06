import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/util/school_timezone_resolver.dart';
import '../../../../../../core/util/school_zone_datetime.dart';
import '../../../../../../core/util/staff_code_resolver.dart';
import '../../../../../../domain/features/attendance/usecases/update_student_attendance_record_usecase.dart';
import '../../../view_model/attendance_time_parse_util.dart';
import '../../../view_model/edit_attendance_submit_outcome.dart';
import 'package:wowcare/core/util/server_time_service.dart';

part 'student_edit_attendance_state.dart';

/// Cubit for [StudentEditAttendanceForm].
///
/// Owns the editable sign-in/sign-out times, the resolved school timezone, and
/// the submission flag. The view passes in the record's raw prefill values
/// (times as strings + the record code) so the cubit stays free of view types.
class StudentEditAttendanceFormCubit extends Cubit<StudentEditAttendanceState> {
  StudentEditAttendanceFormCubit({
    required UpdateStudentAttendanceRecordUseCase updateUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _updateUseCase = updateUseCase,
       _storageService = storageService,
       _apiClient = apiClient,
       super(const StudentEditAttendanceState());

  final UpdateStudentAttendanceRecordUseCase _updateUseCase;
  final StorageService _storageService;
  final ApiClient _apiClient;

  TimeOfDay? _initialSignInTime;
  TimeOfDay? _initialSignOutTime;
  String? _attendanceRecordCode;
  DateTime _attendanceDate = ServerTimeService.instance.now();

  /// Resolves the school timezone, prefills the time pickers from the record's
  /// raw strings, and remembers the identifiers needed at submit time.
  Future<void> init({
    required String? signInRaw,
    required String? signOutRaw,
    required String? attendanceRecordCode,
    required DateTime attendanceDate,
  }) async {
    _attendanceRecordCode = attendanceRecordCode;
    _attendanceDate = attendanceDate;

    final schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storageService,
      apiClient: _apiClient,
    );
    if (isClosed) return;
    final signIn = parseSchoolTimeOrNull(signInRaw, schoolIana);
    final signOut = parseSchoolTimeOrNull(signOutRaw, schoolIana);
    _initialSignInTime = signIn;
    _initialSignOutTime = signOut;
    emit(
      state.copyWith(
        schoolIana: schoolIana,
        signInTime: signIn,
        signOutTime: signOut,
      ),
    );
  }

  void setSignInTime(TimeOfDay time) => emit(state.copyWith(signInTime: time));

  void setSignOutTime(TimeOfDay time) =>
      emit(state.copyWith(signOutTime: time));

  /// Updates the student attendance record with the (changed) times. Returns
  /// an outcome the view turns into a snackbar; on success the view pops `true`.
  Future<EditAttendanceSubmitOutcome> submit() async {
    if (state.isSubmitting) return const EditAttendanceSubmitOutcome.noop();

    emit(state.copyWith(isSubmitting: true));

    final attendanceCode = (_attendanceRecordCode ?? '').trim();
    if (attendanceCode.isEmpty) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return const EditAttendanceSubmitOutcome.failure(
        'Unable to update: missing attendance record code.',
      );
    }

    final staffCode = await resolveStaffCodeForLoggedInUser();
    if (staffCode.isEmpty) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return const EditAttendanceSubmitOutcome.failure(
        'Unable to resolve staffCode. Please re-login.',
      );
    }

    if (state.signInTime == null) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return const EditAttendanceSubmitOutcome.failure(
        'Sign-In time is required.',
      );
    }

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storageService,
      apiClient: _apiClient,
    );

    final date = _attendanceDate;
    final signedInChanged = !sameTimeOfDay(
      state.signInTime,
      _initialSignInTime,
    );
    final signedOutChanged = !sameTimeOfDay(
      state.signOutTime,
      _initialSignOutTime,
    );

    final signedInAt = signedInChanged
        ? SchoolZoneDateTime.utcFromSchoolWallClock(
            schoolTimeZone,
            year: date.year,
            month: date.month,
            day: date.day,
            hour: state.signInTime!.hour,
            minute: state.signInTime!.minute,
          )
        : null;
    final signedOutAt = signedOutChanged && state.signOutTime != null
        ? SchoolZoneDateTime.utcFromSchoolWallClock(
            schoolTimeZone,
            year: date.year,
            month: date.month,
            day: date.day,
            hour: state.signOutTime!.hour,
            minute: state.signOutTime!.minute,
          )
        : null;

    try {
      final message = await _updateUseCase(
        attendanceRecordCode: attendanceCode,
        staffCode: staffCode,
        signedInAt: signedInAt,
        signedOutAt: signedOutAt,
        timeZone: schoolTimeZone,
      );
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditAttendanceSubmitOutcome.success(message);
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditAttendanceSubmitOutcome.error(e);
    }
  }
}
