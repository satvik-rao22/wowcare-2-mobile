import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/features/student/entities/student_important_dates.dart';
import '../../../../domain/features/student/usecases/update_student_important_dates_usecase.dart';

class StudentImportantDatesCubit extends Cubit<StudentImportantDatesState> {
  StudentImportantDatesCubit({
    required UpdateStudentImportantDatesUseCase
    updateStudentImportantDatesUseCase,
  }) : _updateStudentImportantDatesUseCase = updateStudentImportantDatesUseCase,
       super(const StudentImportantDatesState.initial());

  final UpdateStudentImportantDatesUseCase _updateStudentImportantDatesUseCase;

  Future<void> updateImportantDates({
    required String studentCode,
    required StudentImportantDates dates,
  }) async {
    emit(const StudentImportantDatesState.loading());

    final result = await _updateStudentImportantDatesUseCase(
      studentCode: studentCode,
      dates: dates,
    );

    result.fold(
      (Failure failure) {
        emit(
          StudentImportantDatesState.error(
            failure.message ?? 'Failed to update important dates',
          ),
        );
      },
      (String message) {
        emit(StudentImportantDatesState.success(message));
      },
    );
  }

  void reset() {
    emit(const StudentImportantDatesState.initial());
  }
}

class StudentImportantDatesState extends Equatable {
  const StudentImportantDatesState({
    required this.isLoading,
    this.message,
    this.isSuccess = false,
    this.isError = false,
  });

  const StudentImportantDatesState.initial()
    : isLoading = false,
      isSuccess = false,
      isError = false,
      message = null;

  const StudentImportantDatesState.loading()
    : isLoading = true,
      isSuccess = false,
      isError = false,
      message = null;

  const StudentImportantDatesState.success(String message)
    : isLoading = false,
      isSuccess = true,
      isError = false,
      message = message;

  const StudentImportantDatesState.error(String message)
    : isLoading = false,
      isSuccess = false,
      isError = true,
      message = message;

  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final String? message;

  @override
  List<Object?> get props => [isLoading, isSuccess, isError, message];
}
