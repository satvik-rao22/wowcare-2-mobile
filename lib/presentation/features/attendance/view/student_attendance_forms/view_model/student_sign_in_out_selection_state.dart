part of 'student_sign_in_out_selection_cubit.dart';

/// State for [StudentSignInOutSelectionCubit] — just the QR re-validation
/// in-flight flag, which used to be a plain `setState`-driven field on the
/// screen (Mandate 2: screen/business state belongs in a cubit).
class StudentSignInOutSelectionState extends Equatable {
  const StudentSignInOutSelectionState({this.isValidating = false});

  final bool isValidating;

  StudentSignInOutSelectionState copyWith({bool? isValidating}) {
    return StudentSignInOutSelectionState(
      isValidating: isValidating ?? this.isValidating,
    );
  }

  @override
  List<Object?> get props => [isValidating];
}
