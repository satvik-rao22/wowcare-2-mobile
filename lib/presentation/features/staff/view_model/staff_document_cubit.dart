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
  }) : _addStaffDocumentUseCase = addStaffDocumentUseCase,
       _updateStaffDocumentUseCase = updateStaffDocumentUseCase,
       super(const StaffDocumentState.initial());

  final AddStaffDocumentUseCase _addStaffDocumentUseCase;
  final UpdateStaffDocumentUseCase? _updateStaffDocumentUseCase;

  /// Re-entrancy guard shared by [addDocument] and [updateDocument]: a second
  /// document op while one is still in flight (a double-tap) is ignored, so the
  /// cubit enforces single-flight independently of any UI button-disabling.
  /// Only one document op at a time from this cubit is expected, so a single
  /// shared flag is sufficient.
  bool _inFlight = false;

  Future<void> addDocument({
    required String staffCode,
    required StaffDocument document,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      emit(StaffDocumentState.loading());

      final result = await _addStaffDocumentUseCase(
        staffCode: staffCode,
        document: document,
      );

      // The document screen owning this cubit may have been popped while the
      // add was in flight; skip the emit so we don't mutate a closed cubit.
      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            StaffDocumentState.error(
              failure.message ?? 'Failed to add document',
            ),
          );
        },
        (message) {
          emit(StaffDocumentState.success(message));
        },
      );
    } finally {
      _inFlight = false;
    }
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

    if (_inFlight) return;
    _inFlight = true;
    try {
      emit(StaffDocumentState.loading());

      final result = await _updateStaffDocumentUseCase.call(
        documentUuid: documentUuid,
        staffCode: staffCode,
        document: document,
      );

      // The document screen owning this cubit may have been popped while the
      // update was in flight; skip the emit so we don't mutate a closed cubit.
      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            StaffDocumentState.error(
              failure.message ?? 'Failed to update document',
            ),
          );
        },
        (message) {
          emit(StaffDocumentState.success(message));
        },
      );
    } finally {
      _inFlight = false;
    }
  }

  void reset() {
    emit(const StaffDocumentState.initial());
  }
}
