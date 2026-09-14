import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';
import '../../../../domain/features/staff_classroom/usecases/assign_staff_to_classroom_usecase.dart';
import 'assign_staff_confirmation_state.dart';

/// Drives the review/submit step of the "Assign staff to classroom" flow.
class AssignStaffConfirmationCubit extends Cubit<AssignStaffConfirmationState> {
  AssignStaffConfirmationCubit({
    required AssignStaffToClassroomUseCase assignStaffToClassroomUseCase,
    required StorageService storageService,
  }) : _assignStaffToClassroomUseCase = assignStaffToClassroomUseCase,
       _storageService = storageService,
       super(const AssignStaffConfirmationState());

  final AssignStaffToClassroomUseCase _assignStaffToClassroomUseCase;
  final StorageService _storageService;

  void init(Set<StaffClassroomItem> initialSelection) {
    emit(state.copyWith(selectedStaff: Set.of(initialSelection)));
  }

  void removeStaff(StaffClassroomItem staff) {
    final updated = Set<StaffClassroomItem>.from(state.selectedStaff)
      ..remove(staff);
    emit(state.copyWith(selectedStaff: updated));
  }

  /// Returns a user-facing success message, or throws a user-facing error
  /// message string.
  Future<String> submit({required String classroomCode}) async {
    if (state.selectedStaff.isEmpty) {
      throw 'Please select at least one staff member';
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final schoolCode = await _storageService.getString(
        StorageKeys.schoolCode,
      );
      if (schoolCode == null || schoolCode.trim().isEmpty) {
        throw 'Missing schoolCode. Please sign in / select a school again.';
      }

      final staffCodes = state.selectedStaff
          .map((s) => s.staffCode.trim())
          .where((code) => code.isNotEmpty)
          .toList();

      final message = await _assignStaffToClassroomUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        staffCodes: staffCodes,
      );
      return message.isEmpty ? 'Assigned successfully' : message;
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }
}
