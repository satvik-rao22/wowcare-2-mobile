part of 'scheduling_staff_list_cubit.dart';

class SchedulingStaffListState extends Equatable {
  const SchedulingStaffListState({
    required this.staff,
    required this.isLoading,
    required this.errorMessage,
  });

  factory SchedulingStaffListState.initial() => const SchedulingStaffListState(
        staff: <StaffMember>[],
        isLoading: false,
        errorMessage: null,
      );

  final List<StaffMember> staff;
  final bool isLoading;
  final String? errorMessage;

  SchedulingStaffListState copyWith({
    List<StaffMember>? staff,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SchedulingStaffListState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [staff, isLoading, errorMessage];
}
