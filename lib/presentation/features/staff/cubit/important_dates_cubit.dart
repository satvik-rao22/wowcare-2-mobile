import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../domain/features/staff/usecases/update_important_dates_usecase.dart';

class ImportantDatesCubit extends Cubit<ImportantDatesState> {
  ImportantDatesCubit({
    required UpdateImportantDatesUseCase updateImportantDatesUseCase,
  }) : _updateImportantDatesUseCase = updateImportantDatesUseCase,
       super(ImportantDatesState.initial());

  final UpdateImportantDatesUseCase _updateImportantDatesUseCase;

  Future<void> updateImportantDates({
    required String staffCode,
    required List<Map<String, String>> dates,
  }) async {
    emit(ImportantDatesState.loading());

    final result = await _updateImportantDatesUseCase(
      staffCode: staffCode,
      dates: dates,
    );

    result.fold(
      (Failure failure) {
        emit(
          ImportantDatesState.error(
            failure.message ?? 'Failed to update important dates',
          ),
        );
      },
      (String message) {
        emit(ImportantDatesState.success(message));
      },
    );
  }

  void reset() {
    emit(ImportantDatesState.initial());
  }
}

class ImportantDatesState extends Equatable {
  const ImportantDatesState._();

  factory ImportantDatesState.initial() => const _InitialState();
  factory ImportantDatesState.loading() => const _LoadingState();
  factory ImportantDatesState.success(String message) => _SuccessState(message);
  factory ImportantDatesState.error(String message) => _ErrorState(message);

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

class _InitialState extends ImportantDatesState {
  const _InitialState() : super._();
}

class _LoadingState extends ImportantDatesState {
  const _LoadingState() : super._();
}

class _SuccessState extends ImportantDatesState {
  const _SuccessState(this.message) : super._();
  final String message;

  @override
  List<Object?> get props => [message];
}

class _ErrorState extends ImportantDatesState {
  const _ErrorState(this.message) : super._();
  final String message;

  @override
  List<Object?> get props => [message];
}
