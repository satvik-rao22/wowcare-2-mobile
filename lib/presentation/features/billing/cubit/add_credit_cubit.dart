import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_credit_usecase.dart';

part 'add_credit_state.dart';

enum AddCreditResult { missingAmount, failure, success }

class AddCreditCubit extends Cubit<AddCreditState> {
  AddCreditCubit({
    required CreateCreditUseCase createCredit,
    required StorageService storage,
  })  : _createCredit = createCredit,
        _storage = storage,
        super(const AddCreditState());

  final CreateCreditUseCase _createCredit;
  final StorageService _storage;

  void clearAmountError() {
    if (state.amountError) emit(state.copyWith(amountError: false));
  }

  /// Validates the amount then posts the credit (`POST /invoices/credits`).
  Future<AddCreditResult> submit({
    required String amount,
    String? reason,
    String? description,
    String? ownerType,
    String? ownerCode,
    String? studentCode,
  }) async {
    final parsed = double.tryParse(amount.trim()) ?? 0;
    if (amount.trim().isEmpty || parsed <= 0) {
      emit(state.copyWith(amountError: true));
      return AddCreditResult.missingAmount;
    }

    emit(state.copyWith(
        amountError: false, isSubmitting: true, errorMessage: null));
    try {
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      await _createCredit(CreateCreditParams(
        schoolCode: schoolCode,
        amount: parsed,
        ownerType: ownerType,
        ownerCode: ownerCode,
        studentCode: studentCode,
        reason: reason,
        description: description,
      ));
      if (isClosed) return AddCreditResult.success;
      emit(state.copyWith(isSubmitting: false));
      return AddCreditResult.success;
    } catch (e) {
      if (isClosed) return AddCreditResult.failure;
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return AddCreditResult.failure;
    }
  }
}
