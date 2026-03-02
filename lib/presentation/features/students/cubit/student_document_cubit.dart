import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/usecases/add_student_document_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_document_usecase.dart';

part 'student_document_state.dart';

class StudentDocumentCubit extends Cubit<StudentDocumentState> {
  StudentDocumentCubit({
    required AddStudentDocumentUseCase addStudentDocumentUseCase,
    required UpdateStudentDocumentUseCase updateStudentDocumentUseCase,
  })  : _addStudentDocumentUseCase = addStudentDocumentUseCase,
        _updateStudentDocumentUseCase = updateStudentDocumentUseCase,
        super(const StudentDocumentState.initial());

  final AddStudentDocumentUseCase _addStudentDocumentUseCase;
  final UpdateStudentDocumentUseCase _updateStudentDocumentUseCase;

  Future<void> addDocument({
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? notes,
  }) async {
    emit(const StudentDocumentState.loading());

    final result = await _addStudentDocumentUseCase(
      studentCode: studentCode,
      name: name,
      type: type,
      expiryDate: expiryDate,
      storagePath: storagePath,
      mimeType: mimeType,
      size: size,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(StudentDocumentState.error(
          failure.message ?? 'Failed to add document',
        ));
      },
      (message) {
        emit(StudentDocumentState.success(message));
      },
    );
  }

  Future<void> updateDocument({
    required String documentUuid,
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? notes,
  }) async {
    emit(const StudentDocumentState.loading());

    final result = await _updateStudentDocumentUseCase(
      documentUuid: documentUuid,
      studentCode: studentCode,
      name: name,
      type: type,
      expiryDate: expiryDate,
      storagePath: storagePath,
      mimeType: mimeType,
      size: size,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(StudentDocumentState.error(
          failure.message ?? 'Failed to update document',
        ));
      },
      (message) {
        emit(StudentDocumentState.success(message));
      },
    );
  }

  void reset() {
    emit(const StudentDocumentState.initial());
  }
}
