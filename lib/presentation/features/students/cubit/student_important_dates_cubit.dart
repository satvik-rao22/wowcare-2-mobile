import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

class StudentImportantDatesCubit extends Cubit<StudentImportantDatesState> {
  StudentImportantDatesCubit({
    required UpdateStudentImportantDatesUseCase updateStudentImportantDatesUseCase,
  })  : _updateStudentImportantDatesUseCase = updateStudentImportantDatesUseCase,
        super(const StudentImportantDatesState.initial());

  final UpdateStudentImportantDatesUseCase _updateStudentImportantDatesUseCase;

  /// Seed the form model from the caller's initial values (called from the
  /// screen's initState). Owns the two dates so the view no longer keeps a copy.
  void initialize({DateTime? enrollDate, DateTime? schoolStartDate}) {
    emit(state.copyWith(
      enrollDate: enrollDate,
      schoolStartDate: schoolStartDate,
    ));
  }

  /// Editing a field clears any prior success/error banner so stale feedback
  /// doesn't linger while the user changes the form.
  void setEnrollDate(DateTime? date) {
    emit(state.copyWith(
      enrollDate: date,
      isSuccess: false,
      isError: false,
      message: null,
    ));
  }

  void setSchoolStartDate(DateTime? date) {
    emit(state.copyWith(
      schoolStartDate: date,
      isSuccess: false,
      isError: false,
      message: null,
    ));
  }

  /// Persist the CURRENT form model. The dates are read from state, so the
  /// widget doesn't build or pass the entity.
  Future<void> save({required String studentCode}) {
    return updateImportantDates(
      studentCode: studentCode,
      dates: StudentImportantDates(
        enrollDate: state.enrollDate,
        schoolStartDate: state.schoolStartDate,
      ),
    );
  }

  Future<void> updateImportantDates({
    required String studentCode,
    required StudentImportantDates dates,
  }) async {
    // Single-flight: ignore a second submit while one is already in flight.
    // The Save button disables on `isLoading`, but that only takes effect after
    // the first emit renders — a fast double-tap (or a programmatic re-call)
    // could otherwise fire two identical PATCHes. Guard at the cubit so the
    // duplicate is dropped regardless of UI timing.
    if (state.isLoading) return;

    emit(state.copyWith(
      isLoading: true,
      isSuccess: false,
      isError: false,
      message: null,
    ));

    final result = await _updateStudentImportantDatesUseCase(
      studentCode: studentCode,
      dates: dates,
    );

    // The edit screen may have been popped while the request was in flight;
    // emitting onto a closed cubit throws, so drop the stale result.
    if (isClosed) return;

    result.fold(
      (Failure failure) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          isSuccess: false,
          message: failure.message ?? StudentStrings.failedToUpdateImportantDates,
        ));
      },
      (String message) {
        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          isError: false,
          message: message,
        ));
      },
    );
  }

  void reset() {
    emit(const StudentImportantDatesState.initial());
  }
}

class StudentImportantDatesState extends Equatable {
  static const Object _unset = Object();

  const StudentImportantDatesState({
    required this.isLoading,
    this.message,
    this.isSuccess = false,
    this.isError = false,
    this.enrollDate,
    this.schoolStartDate,
  });

  const StudentImportantDatesState.initial()
      : isLoading = false,
        isSuccess = false,
        isError = false,
        message = null,
        enrollDate = null,
        schoolStartDate = null;

  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final String? message;

  /// The form model — the two important dates being edited. Owned here so the
  /// view no longer holds competing `setState` copies.
  final DateTime? enrollDate;
  final DateTime? schoolStartDate;

  StudentImportantDatesState copyWith({
    bool? isLoading,
    bool? isSuccess,
    bool? isError,
    Object? message = _unset,
    Object? enrollDate = _unset,
    Object? schoolStartDate = _unset,
  }) {
    return StudentImportantDatesState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isError: isError ?? this.isError,
      message: message == _unset ? this.message : message as String?,
      enrollDate:
          enrollDate == _unset ? this.enrollDate : enrollDate as DateTime?,
      schoolStartDate: schoolStartDate == _unset
          ? this.schoolStartDate
          : schoolStartDate as DateTime?,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSuccess, isError, message, enrollDate, schoolStartDate];
}
