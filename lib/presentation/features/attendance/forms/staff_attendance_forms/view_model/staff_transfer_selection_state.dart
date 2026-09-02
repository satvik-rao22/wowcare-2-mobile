part of 'staff_transfer_selection_cubit.dart';

class StaffTransferSelectionState extends Equatable {
  const StaffTransferSelectionState({
    this.staff = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StaffEntity> staff;
  final bool isLoading;
  final String? errorMessage;

  StaffTransferSelectionState copyWith({
    List<StaffEntity>? staff,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffTransferSelectionState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [staff, isLoading, errorMessage];
}
