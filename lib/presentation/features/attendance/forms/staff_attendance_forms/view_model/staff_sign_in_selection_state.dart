part of 'staff_sign_in_selection_cubit.dart';

class StaffSignInSelectionState extends Equatable {
  const StaffSignInSelectionState({
    this.staff = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StaffEntity> staff;
  final bool isLoading;
  final String? errorMessage;

  StaffSignInSelectionState copyWith({
    List<StaffEntity>? staff,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffSignInSelectionState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [staff, isLoading, errorMessage];
}
