import 'package:flutter/material.dart';

import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view/edit_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';

/// Typed route argument payloads for the scheduling GoRouter routes.
///
/// Each route reads its arguments from `state.extra` cast to the matching
/// class below — the `extra` object is passed through untouched, so it can
/// safely carry live [ClassroomCubit] / [SchedulingStaffListCubit] instances
/// captured at the call site rather than the route re-resolving them, which
/// would create a second instance outside the one the entry screen's
/// `MultiBlocProvider` owns.

/// [AddShiftScreen]
class AddShiftRouteArgs {
  const AddShiftRouteArgs({
    required this.schedulingStaffListCubit,
    required this.classroomCubit,
    this.initialDate,
    this.initialClassroomCode,
    this.initialStaffCode,
    this.initialShiftStart,
    this.initialShiftEnd,
    this.initialPublish = false,
    this.prefillStaff = true,
  });

  final SchedulingStaffListCubit schedulingStaffListCubit;
  final ClassroomCubit classroomCubit;
  final DateTime? initialDate;
  final String? initialClassroomCode;
  final String? initialStaffCode;
  final TimeOfDay? initialShiftStart;
  final TimeOfDay? initialShiftEnd;
  final bool initialPublish;
  final bool prefillStaff;
}

/// [EditShiftScreen]
class EditShiftRouteArgs {
  const EditShiftRouteArgs({
    required this.schedulingStaffListCubit,
    required this.classroomCubit,
    required this.mode,
    required this.shiftCode,
    required this.staffCode,
    required this.classroomCode,
    required this.initialDate,
    required this.staff,
    required this.classroom,
    required this.shiftStart,
    required this.shiftEnd,
    this.seriesCode,
    this.breakStart,
    this.breakEnd,
    this.note,
    this.status = ShiftStatus.published,
    this.isPublished = true,
    this.selectedDays = const <String>{},
    this.untilDate,
  });

  final SchedulingStaffListCubit schedulingStaffListCubit;
  final ClassroomCubit classroomCubit;
  final EditShiftMode mode;
  final String shiftCode;
  final String? seriesCode;
  final String staffCode;
  final String classroomCode;
  final DateTime initialDate;
  final String staff;
  final String classroom;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String? note;
  final ShiftStatus status;
  final bool isPublished;
  final Set<String> selectedDays;
  final DateTime? untilDate;
}

/// [ViewShiftScreen]
class ViewShiftRouteArgs {
  const ViewShiftRouteArgs({
    required this.date,
    required this.staff,
    required this.classroom,
    required this.shiftStart,
    required this.shiftEnd,
    this.breakStart,
    this.breakEnd,
    this.note,
    this.status = ShiftStatus.published,
    this.isRecurring = false,
    this.onEditThis,
    this.onEditSeries,
    this.onDeleteThis,
    this.onDeleteSeries,
    this.readOnly = false,
  });

  final DateTime date;
  final String staff;
  final String classroom;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String? note;
  final ShiftStatus status;
  final bool isRecurring;
  final Future<bool> Function()? onEditThis;
  final Future<bool> Function()? onEditSeries;
  final Future<bool> Function()? onDeleteThis;
  final Future<bool> Function()? onDeleteSeries;
  final bool readOnly;
}

/// [PublishShiftsScreen]
class PublishShiftsRouteArgs {
  const PublishShiftsRouteArgs({
    required this.dateRangeStart,
    this.staff = const <StaffMember>[],
    this.initialUntilDate,
    this.initialStaffCodes = const <String>[],
  });

  final DateTime dateRangeStart;
  final List<StaffMember> staff;
  final DateTime? initialUntilDate;
  final List<String> initialStaffCodes;
}
