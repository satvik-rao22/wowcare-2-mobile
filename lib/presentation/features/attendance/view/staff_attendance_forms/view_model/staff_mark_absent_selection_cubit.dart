import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';

import '../../../model/staff_entity.dart';

part 'staff_mark_absent_selection_state.dart';

/// ViewModel (Cubit) for [StaffSelectionMarkAbsentForm]. Owns the staff
/// mark-absent-candidate fetch — the View keeps only UI-only state
/// (classroom/designation dropdown selection, search text, current
/// selections), same split as [StudentMarkAbsentSelectionCubit].
class StaffMarkAbsentSelectionCubit
    extends Cubit<StaffMarkAbsentSelectionState> {
  StaffMarkAbsentSelectionCubit({
    required GetStaffAbsentFormListUseCase getStaffAbsentFormListUseCase,
  }) : _getStaffAbsentFormListUseCase = getStaffAbsentFormListUseCase,
       super(const StaffMarkAbsentSelectionState());

  final GetStaffAbsentFormListUseCase _getStaffAbsentFormListUseCase;

  /// Loads the mark-absent candidate list for today (school-calendar day),
  /// scoped by [classroomCode] and [tagCodes] (designation codes) and
  /// [search]. Search/classroom/tag post-filtering stays in the View — the
  /// absent-form-list item doesn't expose a designation list to filter by
  /// client-side (unlike sign-in/transfer/sign-out), matching the pre-cubit
  /// behavior exactly.
  Future<void> loadStaff({
    String? classroomCode,
    List<String>? tagCodes,
    String? search,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await bootstrapAttendanceSchoolTimezone();
      final dateString = attendanceYyyyMmDd(attendanceSchoolToday());

      final classroomCodes = classroomCode != null && classroomCode.isNotEmpty
          ? <String>[classroomCode]
          : null;

      final page = await _getStaffAbsentFormListUseCase(
        fromAbsenceDate: dateString,
        toAbsenceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
        page: 0,
        size: 200,
      );

      if (isClosed) return;

      final staffList = page.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return StaffEntity(
          id: index + 1,
          name: item.staffName,
          primaryRoomId: 0,
          classroomCode: item.classroomCode,
          classroomName: item.classroomName,
          photoUuid: null,
          // Absent form entity doesn't expose designation list; use a safe
          // default label (matches the pre-cubit View behavior).
          designation: 'Staff',
          staffCode: item.staffCode,
        );
      }).toList();

      emit(state.copyWith(allStaff: staffList, isLoading: false));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }
}
