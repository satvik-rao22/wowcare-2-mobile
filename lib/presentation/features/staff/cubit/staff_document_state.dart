part of 'staff_document_cubit.dart';

class StaffDocumentState extends Equatable {
  const StaffDocumentState();

  const StaffDocumentState.initial() : this();

  const StaffDocumentState.loading() : this();

  factory StaffDocumentState.success(String message) => _SuccessState(message);

  factory StaffDocumentState.error(String message) => _ErrorState(message);

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

class _LoadingState extends StaffDocumentState {
  const _LoadingState();
}

class _SuccessState extends StaffDocumentState {
  const _SuccessState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class _ErrorState extends StaffDocumentState {
  const _ErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
