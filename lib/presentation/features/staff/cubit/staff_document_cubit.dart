import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/usecases/add_staff_document_usecase.dart';
import '../../../../domain/features/staff/usecases/update_staff_document_usecase.dart';

part 'staff_document_state.dart';

class StaffDocumentCubit extends Cubit<StaffDocumentState> {
  StaffDocumentCubit({
    required AddStaffDocumentUseCase addStaffDocumentUseCase,
    UpdateStaffDocumentUseCase? updateStaffDocumentUseCase,
  })  : _addStaffDocumentUseCase = addStaffDocumentUseCase,
        _updateStaffDocumentUseCase = updateStaffDocumentUseCase,
        super(const StaffDocumentState.initial());

  final AddStaffDocumentUseCase _addStaffDocumentUseCase;
  final UpdateStaffDocumentUseCase? _updateStaffDocumentUseCase;

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

  Future<void> updateDocument({
    required String documentUuid,
    required String staffCode,
    required StaffDocument document,
  }) async {
    if (_updateStaffDocumentUseCase == null) {
      emit(StaffDocumentState.error('Update functionality not available'));
      return;
    }

    emit(StaffDocumentState.loading());

    final result = await _updateStaffDocumentUseCase.call(
      documentUuid: documentUuid,
      staffCode: staffCode,
      document: document,
    );

    result.fold(
      (failure) {
        emit(StaffDocumentState.error(
          failure.message ?? 'Failed to update document',
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

