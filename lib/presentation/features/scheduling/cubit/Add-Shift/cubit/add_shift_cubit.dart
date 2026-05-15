import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/util/core_utils.dart';
import '../../../../../../core/util/storage_keys.dart';
import '../../../../../../domain/features/staff/repositories/staff_repository.dart';

import 'add_shift_state.dart';

class AddShiftCubit extends Cubit<AddShiftState> {
  final StaffRepository repository;
  final StorageService storageService;

  AddShiftCubit({required this.repository, required this.storageService})
    : super(const AddShiftState());

  static const Map<String, int> weekdayCodeByName = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
  };

  /// DATE
  void selectDate(DateTime date) {
    emit(state.copyWith(shiftDate: date));
  }

  /// DATE RANGE
  void updateDateRange(DateTime startDate, DateTime? endDate) {
    emit(state.copyWith(shiftDate: startDate, repeatUntilDate: endDate));
  }

  /// STAFF
  void selectStaff(String code) {
    emit(
      state.copyWith(
        selectedStaffCode: code,
        selectedClassroomCode: null,
        allowedClassroomCodes: [],
        allowedClassrooms: [],
      ),
    );

    loadStaffProfile(code);
  }

  /// CLASSROOM
  void selectClassroom(String code) {
    emit(state.copyWith(selectedClassroomCode: code));
  }

  /// SHIFT START
  void selectStartTime(TimeOfDay time) {
    emit(state.copyWith(startTime: time));
  }

  /// SHIFT END
  void selectEndTime(TimeOfDay time) {
    emit(state.copyWith(endTime: time));
  }

  /// BREAK START
  void selectBreakStart(TimeOfDay time) {
    emit(state.copyWith(breakStartTime: time));
  }

  /// BREAK END
  void selectBreakEnd(TimeOfDay time) {
    emit(state.copyWith(breakEndTime: time));
  }

  /// REPEAT DAYS
  void updateRepeatDays(List<String> days) {
    emit(state.copyWith(selectedDays: days));
  }

  /// REPEAT UNTIL
  void updateRepeatUntil(DateTime date) {
    emit(state.copyWith(repeatUntilDate: date));
  }

  /// NOTES
  void updateNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  /// LOAD STAFF PROFILE
  Future<void> loadStaffProfile(String staffCode) async {
    emit(state.copyWith(isProfileLoading: true));

    try {
      final profile = await repository.getStaffProfile(
        staffCode: staffCode,
        forEditStaff: true,
      );

      emit(
        state.copyWith(
          isProfileLoading: false,
          allowedClassroomCodes: profile.allowedClassroomCodes,
          allowedClassrooms: profile.allowedClassrooms,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isProfileLoading: false, error: e.toString()));
    }
  }

  /// VALIDATION
  bool validateForm(BuildContext context) {
    if (state.shiftDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select shift date',
        isWarning: true,
      );

      return false;
    }

    if (state.selectedStaffCode == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select staff',
        isWarning: true,
      );

      return false;
    }

    if (state.selectedClassroomCode == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select classroom',
        isWarning: true,
      );

      return false;
    }

    if (state.startTime == null || state.endTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select shift timings',
        isWarning: true,
      );

      return false;
    }

    final startMinutes = _toMinutes(state.startTime!);

    final endMinutes = _toMinutes(state.endTime!);

    if (startMinutes >= endMinutes) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Shift end time must be after start time',
        isWarning: true,
      );

      return false;
    }

    if (state.selectedDays.isNotEmpty && state.repeatUntilDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select repeat until date',
        isWarning: true,
      );

      return false;
    }

    return true;
  }

  /// BUILD REQUEST
  Future<Map<String, dynamic>?> buildRequest(BuildContext context) async {
    if (!validateForm(context)) {
      return null;
    }

    final schoolCode = await storageService.getString(StorageKeys.schoolCode);

    final organizationCode = await storageService.getString(
      StorageKeys.organizationCode,
    );

    final repeatDays = state.selectedDays
        .map((e) => weekdayCodeByName[e]!)
        .toList();

    return {
      "staffCode": state.selectedStaffCode,

      "classroomCode": state.selectedClassroomCode,

      "schoolCode": schoolCode,

      "organizationCode": organizationCode,

      "shiftDate": DateFormat('yyyy-MM-dd').format(state.shiftDate!),

      "startTime": _formatTime(state.startTime),

      "endTime": _formatTime(state.endTime),

      if (state.breakStartTime != null)
        "breakStartTime": _formatTime(state.breakStartTime),

      if (state.breakEndTime != null)
        "breakEndTime": _formatTime(state.breakEndTime),

      "publish": true,

      "repeat": repeatDays.isNotEmpty,

      if (repeatDays.isNotEmpty) ...{
        "repeatDays": repeatDays,

        "repeatUntilDate": DateFormat(
          'yyyy-MM-dd',
        ).format(state.repeatUntilDate!),
      },

      "overrideConflicts": true,

      "forceAdd": true,

      if (state.notes.isNotEmpty) "notes": state.notes,
    };
  }

  /// FORMAT TIME
  String _formatTime(TimeOfDay? t) {
    if (t == null) {
      return '00:00:00';
    }

    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:00';
  }

  /// TIME TO MINUTES
  int _toMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }
}
