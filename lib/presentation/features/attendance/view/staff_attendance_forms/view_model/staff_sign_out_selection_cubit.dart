import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';

import '../../../model/staff_entity.dart';

part 'staff_sign_out_selection_state.dart';

/// ViewModel (Cubit) for [StaffSelectionSignOutForm]. Owns the staff
/// sign-out-candidate fetch — the View keeps only UI-only state (classroom/
/// designation dropdown selection, search text, current selections), same
/// split as [StudentSignOutSelectionCubit].
class StaffSignOutSelectionCubit extends Cubit<StaffSignOutSelectionState> {
  StaffSignOutSelectionCubit({
    required GetStaffSignOutFormListUseCase getStaffSignOutFormListUseCase,
  }) : _getStaffSignOutFormListUseCase = getStaffSignOutFormListUseCase,
       super(const StaffSignOutSelectionState());

  final GetStaffSignOutFormListUseCase _getStaffSignOutFormListUseCase;

  /// Loads the sign-out candidate list for today (school-calendar day),
  /// scoped by [classroomCode] and [tagCodes] (designation codes) and
  /// [search]. Designation/search post-filtering stays in the View.
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

      final page = await _getStaffSignOutFormListUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
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
          designation: item.designation.isNotEmpty
              ? item.designation.first
              : 'Staff',
          staffCode: item.staffCode,
        );
      }).toList();

      emit(state.copyWith(staff: staffList, isLoading: false));
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
