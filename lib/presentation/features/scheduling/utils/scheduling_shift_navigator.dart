import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_series_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shift_by_code_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';
import 'package:wowcare/presentation/features/scheduling/view/edit_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';

/// Opens [ViewShiftScreen] (and edit/delete flows) from classroom scheduling
/// rows — same behaviour as staff scheduling.
class SchedulingShiftNavigator {
  const SchedulingShiftNavigator({
    required this.classroomNamesByCode,
    required this.selectedDay,
    required this.onDataMutated,
  });

  final Map<String, String> classroomNamesByCode;
  final DateTime selectedDay;
  final Future<void> Function() onDataMutated;

  Future<void> openFromStaffEntry(
    BuildContext context, {
    required StaffScheduleEntry entry,
    required String classroomName,
  }) async {
    final shiftCode = entry.shiftCode?.trim() ?? '';
    if (shiftCode.isNotEmpty) {
      await openByShiftCode(
        context,
        shiftCode: shiftCode,
        fallbackStaffName: entry.staffName,
      );
      return;
    }
    await _pushViewFromClockStrings(
      context,
      staffName: entry.staffName,
      classroomName: classroomName,
      startTime: entry.startTime,
      endTime: entry.endTime,
      isPublished: entry.isPublished,
    );
  }

  Future<void> openFromSlotDetail(
    BuildContext context, {
    required StaffShiftSlotDetail detail,
    required String staffName,
    required String classroomName,
  }) async {
    final shiftCode = detail.shiftCode.trim();
    if (shiftCode.isNotEmpty) {
      await openByShiftCode(
        context,
        shiftCode: shiftCode,
        fallbackStaffName: staffName,
      );
      return;
    }
    if (!detail.hasShiftData) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ViewShiftScreen(
          date: selectedDay,
          staff: staffName,
          classroom: classroomName,
          shiftStart: detail.shiftStart!,
          shiftEnd: detail.shiftEnd!,
          breakStart: detail.breakStart,
          breakEnd: detail.breakEnd,
          status: detail.isPublished
              ? ShiftStatus.published
              : ShiftStatus.draft,
        ),
      ),
    );
  }

  Future<void> openByShiftCode(
    BuildContext context, {
    required String shiftCode,
    String fallbackStaffName = '',
  }) async {
    final navigator = Navigator.of(context);
    try {
      final shift =
          await serviceLocator<GetStaffShiftByCodeUseCase>()(shiftCode);
      if (!context.mounted) return;
      final classroomName = shift.classroomName.trim().isNotEmpty
          ? shift.classroomName
          : (classroomNamesByCode[shift.classroomCode] ??
              shift.classroomCode);
      final staffName = shift.staffName.trim().isNotEmpty
          ? shift.staffName
          : fallbackStaffName;
      final mutated = await navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ViewShiftScreen(
            date: shift.shiftDate,
            staff: staffName,
            classroom: classroomName,
            shiftStart: shift.startTime,
            shiftEnd: shift.endTime,
            breakStart: shift.breakStartTime,
            breakEnd: shift.breakEndTime,
            note: shift.notes,
            status: shift.isPublished
                ? ShiftStatus.published
                : ShiftStatus.draft,
            isRecurring: shift.isRecurring,
            onEditThis: () => _openEditShiftScreen(
              context,
              shiftCode: shiftCode,
              fallbackStaffName: fallbackStaffName,
              mode: EditShiftMode.thisShift,
            ),
            onEditSeries: () => _openEditShiftScreen(
              context,
              shiftCode: shiftCode,
              fallbackStaffName: fallbackStaffName,
              mode: EditShiftMode.entireSeries,
            ),
            onDeleteThis: () => _deleteStaffShift(
              context,
              shiftCode: shift.shiftCode,
              staffCode: shift.staffCode,
              isSeries: false,
            ),
            onDeleteSeries: () => _deleteStaffShift(
              context,
              shiftCode: shift.shiftCode,
              staffCode: shift.staffCode,
              seriesCode: shift.seriesCode,
              isSeries: true,
            ),
          ),
        ),
      );
      if (mutated == true) {
        await onDataMutated();
      }
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _openEditShiftScreen(
    BuildContext context, {
    required String shiftCode,
    required String fallbackStaffName,
    required EditShiftMode mode,
  }) async {
    final classroomCubit = context.read<ClassroomCubit>();
    final schedulingStaffListCubit = context.read<SchedulingStaffListCubit>();
    final navigator = Navigator.of(context);
    try {
      final shift =
          await serviceLocator<GetStaffShiftByCodeUseCase>()(shiftCode);
      if (!context.mounted) return;
      final classroomName = shift.classroomName.trim().isNotEmpty
          ? shift.classroomName
          : (classroomNamesByCode[shift.classroomCode] ??
              shift.classroomCode);
      final staffName = shift.staffName.trim().isNotEmpty
          ? shift.staffName
          : fallbackStaffName;
      const weekdayName = <int, String>{
        DateTime.monday: 'Monday',
        DateTime.tuesday: 'Tuesday',
        DateTime.wednesday: 'Wednesday',
        DateTime.thursday: 'Thursday',
        DateTime.friday: 'Friday',
        DateTime.saturday: 'Saturday',
        DateTime.sunday: 'Sunday',
      };
      const dayNameByIndex = <int, String>{
        0: 'Monday',
        1: 'Tuesday',
        2: 'Wednesday',
        3: 'Thursday',
        4: 'Friday',
        5: 'Saturday',
        6: 'Sunday',
        7: 'Sunday',
      };
      final actualDay = weekdayName[shift.shiftDate.weekday];
      final decodedDays = <String>{
        for (final d in shift.seriesRecurrenceDays)
          if (dayNameByIndex[d] != null) dayNameByIndex[d]!,
      };
      final selectedDays =
          (actualDay != null && decodedDays.contains(actualDay))
              ? decodedDays
              : <String>{if (actualDay != null) actualDay};
      final saved = await navigator.push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<SchedulingStaffListCubit>.value(
                value: schedulingStaffListCubit,
              ),
              BlocProvider<ClassroomCubit>.value(value: classroomCubit),
            ],
            child: EditShiftScreen(
              mode: mode,
              shiftCode: shift.shiftCode,
              seriesCode: shift.seriesCode,
              staffCode: shift.staffCode,
              classroomCode: shift.classroomCode,
              initialDate: shift.shiftDate,
              staff: staffName,
              classroom: classroomName,
              shiftStart: shift.startTime,
              shiftEnd: shift.endTime,
              breakStart: shift.breakStartTime,
              breakEnd: shift.breakEndTime,
              note: shift.notes,
              status: shift.isPublished
                  ? ShiftStatus.published
                  : ShiftStatus.draft,
              isPublished: shift.isPublished,
              selectedDays: selectedDays,
              untilDate: shift.seriesEndDate ?? shift.shiftDate,
            ),
          ),
        ),
      );
      if (saved == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigator.canPop()) navigator.pop(true);
        });
      }
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _deleteStaffShift(
    BuildContext context, {
    required String shiftCode,
    required String staffCode,
    String? seriesCode,
    required bool isSeries,
  }) async {
    final navigator = Navigator.of(context);
    try {
      if (isSeries) {
        final code = (seriesCode ?? '').trim();
        if (code.isEmpty) {
          throw Exception('Missing series code');
        }
        await serviceLocator<DeleteStaffShiftSeriesUseCase>()(
          seriesCode: code,
          staffCode: staffCode,
        );
      } else {
        await serviceLocator<DeleteStaffShiftUseCase>()(
          shiftCode: shiftCode,
          staffCode: staffCode,
        );
      }
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: isSeries
            ? 'Shift series deleted successfully'
            : 'Shift deleted successfully',
        isSuccess: true,
      );
      if (navigator.canPop()) navigator.pop(true);
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _pushViewFromClockStrings(
    BuildContext context, {
    required String staffName,
    required String classroomName,
    required String startTime,
    required String endTime,
    required bool isPublished,
  }) async {
    final start = _parseClockTime(startTime);
    final end = _parseClockTime(endTime);
    if (start == null || end == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ViewShiftScreen(
          date: selectedDay,
          staff: staffName,
          classroom: classroomName,
          shiftStart: start,
          shiftEnd: end,
          status: isPublished ? ShiftStatus.published : ShiftStatus.draft,
        ),
      ),
    );
  }

  static TimeOfDay? _parseClockTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(' ');
    if (parts.length < 2) return null;
    final timePart = parts[0];
    final marker = parts[1].toUpperCase();
    final segments = timePart.split(':');
    if (segments.length < 2) return null;
    var hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;
    final isPm = marker == 'PM';
    final isAm = marker == 'AM';
    if (!isAm && !isPm) return null;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
