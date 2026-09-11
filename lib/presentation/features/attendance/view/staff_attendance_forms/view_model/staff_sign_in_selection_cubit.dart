import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';

import '../../../model/staff_entity.dart';

part 'staff_sign_in_selection_state.dart';

/// ViewModel (Cubit) for [StaffSelectionSignInForm]. Owns the staff
/// sign-in-candidate fetch — the View keeps only UI-only state (classroom/
/// designation dropdown selection, search text, current selections), same
/// split as [StudentSignInSelectionCubit].
class StaffSignInSelectionCubit extends Cubit<StaffSignInSelectionState> {
  StaffSignInSelectionCubit({
    required GetStaffSignInFormListUseCase getStaffSignInFormListUseCase,
  }) : _getStaffSignInFormListUseCase = getStaffSignInFormListUseCase,
       super(const StaffSignInSelectionState());

  final GetStaffSignInFormListUseCase _getStaffSignInFormListUseCase;

  /// Loads the sign-in candidate list for today (school-calendar day),
  /// scoped by [classroomCode] and [tagCodes] (designation codes) and
  /// [search]. Designation/search post-filtering stays in the View — it's
  /// UI-derived filtering on top of this fetch, not a data concern.
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

      final page = await _getStaffSignInFormListUseCase(
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
          isExpectedToday: item.isExpectedToday,
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
