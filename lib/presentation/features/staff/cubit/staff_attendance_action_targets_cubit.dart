import 'package:bloc/bloc.dart';

import '../../../../domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import '../../attendance/forms/staff_attendance_forms/staff_entity.dart';
import '../model/staff_attendance_action.dart';

/// Resolves which of the staff members selected in the list are actually
/// eligible for a bulk attendance action, and shapes them into the
/// [StaffEntity] list the attendance forms take.
///
/// The staff screen ran all four of these inline via
/// `serviceLocator<Get…FormListUseCase>()` — four near-identical blocks
/// differing only in the endpoint, the date parameter names, and which
/// [StaffEntity] fields each list can populate.
///
/// Stateless (`Cubit<void>`): the screen awaits the result and navigates; there
/// is no state for it to rebuild from.
class StaffAttendanceActionTargetsCubit extends Cubit<void> {
  StaffAttendanceActionTargetsCubit({
    required GetStaffSignInFormListUseCase getStaffSignInFormListUseCase,
    required GetStaffSignOutFormListUseCase getStaffSignOutFormListUseCase,
    required GetStaffTransferFormListUseCase getStaffTransferFormListUseCase,
    required GetStaffAbsentFormListUseCase getStaffAbsentFormListUseCase,
  }) : _getStaffSignInFormListUseCase = getStaffSignInFormListUseCase,
       _getStaffSignOutFormListUseCase = getStaffSignOutFormListUseCase,
       _getStaffTransferFormListUseCase = getStaffTransferFormListUseCase,
       _getStaffAbsentFormListUseCase = getStaffAbsentFormListUseCase,
       super(null);

  final GetStaffSignInFormListUseCase _getStaffSignInFormListUseCase;
  final GetStaffSignOutFormListUseCase _getStaffSignOutFormListUseCase;
  final GetStaffTransferFormListUseCase _getStaffTransferFormListUseCase;
  final GetStaffAbsentFormListUseCase _getStaffAbsentFormListUseCase;

  /// One page big enough to hold any realistic selection, matching the size the
  /// screen used.
  static const int _pageSize = 500;

  Future<List<StaffEntity>> resolveTargets({
    required StaffAttendanceAction action,
    required String date,
    required Set<String> selectedStaffCodes,
  }) async {
    switch (action) {
      case StaffAttendanceAction.signIn:
        final page = await _getStaffSignInFormListUseCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: _pageSize,
        );
        return _indexed(
          page.items.where((i) => selectedStaffCodes.contains(i.staffCode)),
          (index, item) => StaffEntity(
            id: index + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            // Only the sign-in list carries these two, and the sign-in payload
            // needs both.
            classroomCode: item.classroomCode,
            designation: _firstDesignation(item.designation),
            staffCode: item.staffCode,
            isExpectedToday: item.isExpectedToday,
          ),
        );

      case StaffAttendanceAction.signOut:
        final page = await _getStaffSignOutFormListUseCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: _pageSize,
        );
        return _indexed(
          page.items.where((i) => selectedStaffCodes.contains(i.staffCode)),
          (index, item) => StaffEntity(
            id: index + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            designation: _firstDesignation(item.designation),
            staffCode: item.staffCode,
          ),
        );

      case StaffAttendanceAction.transfer:
        // Transfer uses absence-style date parameters against its own endpoint.
        final page = await _getStaffTransferFormListUseCase(
          fromAbsenceDate: date,
          toAbsenceDate: date,
          page: 0,
          size: _pageSize,
        );
        return _indexed(
          page.items.where((i) => selectedStaffCodes.contains(i.staffCode)),
          (index, item) => StaffEntity(
            id: index + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            designation: _firstDesignation(item.designation),
            staffCode: item.staffCode,
          ),
        );

      case StaffAttendanceAction.markAbsent:
        final page = await _getStaffAbsentFormListUseCase(
          fromAbsenceDate: date,
          toAbsenceDate: date,
          page: 0,
          size: _pageSize,
        );
        return _indexed(
          page.items.where((i) => selectedStaffCodes.contains(i.staffCode)),
          // The absent list has no designation field, so it stays 'Staff'.
          (index, item) => StaffEntity(
            id: index + 1,
            name: item.staffName,
            primaryRoomId: 0,
            photoUuid: null,
            designation: 'Staff',
            staffCode: item.staffCode,
          ),
        );
    }
  }

  static String _firstDesignation(List<String> designation) =>
      designation.isNotEmpty ? designation.first : 'Staff';

  static List<StaffEntity> _indexed<T>(
    Iterable<T> items,
    StaffEntity Function(int index, T item) build,
  ) {
    final list = items.toList();
    return <StaffEntity>[
      for (var i = 0; i < list.length; i++) build(i, list[i]),
    ];
  }
}
