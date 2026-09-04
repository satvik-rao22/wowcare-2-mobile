part of 'student_pickup_cubit.dart';

class StudentPickupState extends Equatable {
  static const Object _unset = Object();

  const StudentPickupState({
    required this.mutationInProgress,
    this.pickups = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectFromExisting = true,
    this.selectedCarer,
    this.selectedRelation,
    this.existingCarers = const <String>[],
    this.guardianDetailsByName = const <String, Map<String, String>>{},
  });

  const StudentPickupState.initial()
      : mutationInProgress = false,
        pickups = const [],
        isLoading = false,
        errorMessage = null,
        selectFromExisting = true,
        selectedCarer = null,
        selectedRelation = null,
        existingCarers = const <String>[],
        guardianDetailsByName = const <String, Map<String, String>>{};

  final bool mutationInProgress;

  /// The cubit owns the pickup list (single source of truth for the card).
  final List<StudentPickup> pickups;
  final bool isLoading;
  final String? errorMessage;

  /// The add-pickup form model: whether "select from existing" is on, the chosen
  /// carer + relation, and the server-fetched carer list + name→details lookup.
  /// Owned here so the screen holds no competing `setState` copies.
  final bool selectFromExisting;
  final String? selectedCarer;
  final String? selectedRelation;
  final List<String> existingCarers;
  final Map<String, Map<String, String>> guardianDetailsByName;

  StudentPickupState copyWith({
    bool? mutationInProgress,
    List<StudentPickup>? pickups,
    bool? isLoading,
    String? errorMessage,
    bool? selectFromExisting,
    Object? selectedCarer = _unset,
    Object? selectedRelation = _unset,
    List<String>? existingCarers,
    Map<String, Map<String, String>>? guardianDetailsByName,
  }) {
    return StudentPickupState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      pickups: pickups ?? this.pickups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectFromExisting: selectFromExisting ?? this.selectFromExisting,
      selectedCarer:
          selectedCarer == _unset ? this.selectedCarer : selectedCarer as String?,
      selectedRelation: selectedRelation == _unset
          ? this.selectedRelation
          : selectedRelation as String?,
      existingCarers: existingCarers ?? this.existingCarers,
      guardianDetailsByName:
          guardianDetailsByName ?? this.guardianDetailsByName,
    );
  }

  @override
  List<Object?> get props => [
        mutationInProgress,
        pickups,
        isLoading,
        errorMessage,
        selectFromExisting,
        selectedCarer,
        selectedRelation,
        existingCarers,
        guardianDetailsByName,
      ];
}
