import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';

class AssignStaffConfirmationState extends Equatable {
  const AssignStaffConfirmationState({
    this.selectedStaff = const {},
    this.isSubmitting = false,
  });

  final Set<StaffClassroomItem> selectedStaff;
  final bool isSubmitting;

  AssignStaffConfirmationState copyWith({
    Set<StaffClassroomItem>? selectedStaff,
    bool? isSubmitting,
  }) {
    return AssignStaffConfirmationState(
      selectedStaff: selectedStaff ?? this.selectedStaff,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [selectedStaff, isSubmitting];
}
