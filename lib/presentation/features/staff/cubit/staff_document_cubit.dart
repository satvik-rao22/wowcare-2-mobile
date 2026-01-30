import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/usecases/add_staff_document_usecase.dart';

part 'staff_document_state.dart';

class StaffDocumentCubit extends Cubit<StaffDocumentState> {
  StaffDocumentCubit({
    required AddStaffDocumentUseCase addStaffDocumentUseCase,
  })  : _addStaffDocumentUseCase = addStaffDocumentUseCase,
        super(const StaffDocumentState.initial());

  final AddStaffDocumentUseCase _addStaffDocumentUseCase;

  Future<void> addDocument({
    required String staffCode,
    required StaffDocument document,
  }) async {
    emit(const StaffDocumentState.loading());

    final result = await _addStaffDocumentUseCase(
      staffCode: staffCode,
      document: document,
    );

    result.fold(
      (failure) {
        emit(StaffDocumentState.error(
          failure.message ?? 'Failed to add document',
        ));
      },
      (message) {
        emit(StaffDocumentState.success(message));
      },
    );
  }

  void reset() {
    emit(const StaffDocumentState.initial());
  }
}

