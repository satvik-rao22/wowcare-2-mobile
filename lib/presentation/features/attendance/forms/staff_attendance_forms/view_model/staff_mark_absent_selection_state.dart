part of 'staff_mark_absent_selection_cubit.dart';

class StaffMarkAbsentSelectionState extends Equatable {
  const StaffMarkAbsentSelectionState({
    this.allStaff = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// The full, unfiltered fetch result. [StaffSelectionMarkAbsentForm] keeps
  /// its own locally-filtered view derived from this (search/classroom/tag
  /// selection are all client-side there, matching the pre-cubit behavior).
  final List<StaffEntity> allStaff;
  final bool isLoading;
  final String? errorMessage;

  StaffMarkAbsentSelectionState copyWith({
    List<StaffEntity>? allStaff,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffMarkAbsentSelectionState(
      allStaff: allStaff ?? this.allStaff,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [allStaff, isLoading, errorMessage];
}
