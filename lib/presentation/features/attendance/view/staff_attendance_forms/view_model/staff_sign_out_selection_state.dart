part of 'staff_sign_out_selection_cubit.dart';

class StaffSignOutSelectionState extends Equatable {
  const StaffSignOutSelectionState({
    this.staff = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StaffEntity> staff;
  final bool isLoading;
  final String? errorMessage;

  StaffSignOutSelectionState copyWith({
    List<StaffEntity>? staff,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffSignOutSelectionState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [staff, isLoading, errorMessage];
}
