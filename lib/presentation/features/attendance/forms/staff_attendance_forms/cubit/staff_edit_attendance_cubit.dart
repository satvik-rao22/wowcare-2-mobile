import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/util/school_timezone_resolver.dart';
import '../../../../../../core/util/school_zone_datetime.dart';
import '../../../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../attendance_time_parse_util.dart';
import '../../edit_attendance_submit_outcome.dart';

part 'staff_edit_attendance_state.dart';

/// Cubit for [StaffEditAttendanceForm].
///
/// Owns the editable sign-in/sign-out times, the resolved school timezone, and
/// the submission flag. The view passes in the record's raw prefill values
/// (times as strings + identifiers) so the cubit stays free of view data types.
class StaffEditAttendanceFormCubit extends Cubit<StaffEditAttendanceState> {
  StaffEditAttendanceFormCubit({
    required AttendanceRepository attendanceRepository,
    required StorageService storageService,
    required ApiClient apiClient,
  })  : _attendanceRepository = attendanceRepository,
        _storageService = storageService,
        _apiClient = apiClient,
        super(const StaffEditAttendanceState());

  final AttendanceRepository _attendanceRepository;
  final StorageService _storageService;
  final ApiClient _apiClient;

  TimeOfDay? _initialSignInTime;
  TimeOfDay? _initialSignOutTime;
  String? _attendanceRecordCode;
  String _staffCode = '';
  DateTime _attendanceDate = AppTime.now();

  /// Resolves the school timezone, prefills the time pickers from the record's
  /// raw strings, and remembers the identifiers needed at submit time.
  Future<void> init({
    required String? signInRaw,
    required String? signOutRaw,
    required String? attendanceRecordCode,
    required String staffCode,
    required DateTime attendanceDate,
  }) async {
    _attendanceRecordCode = attendanceRecordCode;
    _staffCode = staffCode.trim();
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
    emit(state.copyWith(
      schoolIana: schoolIana,
      signInTime: signIn,
      signOutTime: signOut,
    ));
  }

  void setSignInTime(TimeOfDay time) =>
      emit(state.copyWith(signInTime: time));

  void setSignOutTime(TimeOfDay time) =>
      emit(state.copyWith(signOutTime: time));

  /// Patches the staff attendance record with the (changed) times. Returns an
  /// outcome the view turns into a snackbar; on success the view pops `true`.
  Future<EditAttendanceSubmitOutcome> submit() async {
    if (state.isSubmitting) return const EditAttendanceSubmitOutcome.noop();

    final attendanceCode = (_attendanceRecordCode ?? '').trim();
    if (attendanceCode.isEmpty) {
      return const EditAttendanceSubmitOutcome.failure(
        'Unable to update: missing attendance record code.',
      );
    }
    if (state.signInTime == null) {
      return const EditAttendanceSubmitOutcome.failure(
        'Sign-In time is required.',
      );
    }
    if (_staffCode.isEmpty) {
      return const EditAttendanceSubmitOutcome.failure(
        'Unable to update: missing staff code.',
      );
    }

    emit(state.copyWith(isSubmitting: true));

    final normalizedCode = attendanceCode.toUpperCase();
    final isTransferRecord =
        normalizedCode.startsWith('STTR_') || normalizedCode.startsWith('SCTR_');

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storageService,
      apiClient: _apiClient,
    );

    final date = _attendanceDate;
    final signedInChanged = !sameTimeOfDay(state.signInTime, _initialSignInTime);
    final signedOutChanged =
        !sameTimeOfDay(state.signOutTime, _initialSignOutTime);

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

    final payload = <String, dynamic>{
      'staffCode': _staffCode,
      if (signedInAt != null) 'signedInAt': signedInAt.toUtc().toIso8601String(),
      if (signedOutAt != null)
        'signedOutAt': signedOutAt.toUtc().toIso8601String(),
      if (!isTransferRecord && signedInAt != null) 'signedInMethod': 'APP',
      if (!isTransferRecord && signedOutAt != null) 'signedOutMethod': 'APP',
      'timeZone': schoolTimeZone,
    };

    try {
      await _attendanceRepository.updateStaffAttendanceDailyRecord(
        attendanceCode: attendanceCode,
        body: payload,
      );
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return const EditAttendanceSubmitOutcome.success(
        'Attendance updated successfully',
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return EditAttendanceSubmitOutcome.error(e);
    }
  }
}
