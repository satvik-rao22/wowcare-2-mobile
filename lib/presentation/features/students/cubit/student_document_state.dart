part of 'student_document_cubit.dart';

class StudentDocumentState extends Equatable {
  const StudentDocumentState();

  const StudentDocumentState.initial() : this();

  const StudentDocumentState.loading() : this();

  factory StudentDocumentState.success(String message) =>
      _SuccessState(message);

  factory StudentDocumentState.error(String message) => _ErrorState(message);

  bool get isLoading => this is _LoadingState;
  bool get isSuccess => this is _SuccessState;
  bool get isError => this is _ErrorState;
  String? get message => this is _SuccessState
      ? (this as _SuccessState).message
      : this is _ErrorState
      ? (this as _ErrorState).message
      : null;

  @override
  List<Object?> get props => [];
}

class _LoadingState extends StudentDocumentState {
  const _LoadingState();
}

class _SuccessState extends StudentDocumentState {
  const _SuccessState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class _ErrorState extends StudentDocumentState {
  const _ErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
