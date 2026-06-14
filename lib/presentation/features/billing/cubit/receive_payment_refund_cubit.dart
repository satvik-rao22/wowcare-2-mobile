import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_payment_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/create_refund_usecase.dart';

part 'receive_payment_refund_state.dart';

/// Result of a receive-payment / issue-refund submission so the view can show
/// the right snackbar.
enum ReceivePaymentRefundResult {
  missingAmount,
  missingType,
  missingCheque,
  failure,
  success,
}

/// Owns the receive-payment / issue-refund form's non-text state and submits
/// the payment (`/invoices/payments`) or refund (`/invoices/refunds`). The view
/// keeps its text controllers and passes their values into [validateAndSave].
class ReceivePaymentRefundCubit extends Cubit<ReceivePaymentRefundState> {
  ReceivePaymentRefundCubit({
    required CreatePaymentUseCase createPayment,
    required CreateRefundUseCase createRefund,
    required StorageService storage,
  })  : _createPayment = createPayment,
        _createRefund = createRefund,
        _storage = storage,
        super(const ReceivePaymentRefundState.initial());

  final CreatePaymentUseCase _createPayment;
  final CreateRefundUseCase _createRefund;
  final StorageService _storage;

  void setPaymentType(String? value) {
    emit(state.copyWith(selectedPaymentType: () => value));
  }

  void setSendEmailNotification(bool value) {
    emit(state.copyWith(sendEmailNotification: value));
  }

  void clearAmountError() {
    if (!state.amountError) return;
    emit(state.copyWith(amountError: false));
  }

  Future<ReceivePaymentRefundResult> validateAndSave({
    required String amount,
    required String chequeNumber,
    required bool isRefund,
    String? ownerType,
    String? ownerCode,
    String? studentCode,
    String? narration,
  }) async {
    if (amount.trim().isEmpty) {
      emit(state.copyWith(amountError: true));
      return ReceivePaymentRefundResult.missingAmount;
    }
    if (state.selectedPaymentType == null) {
      return ReceivePaymentRefundResult.missingType;
    }
    if (state.selectedPaymentType == 'Cheque' && chequeNumber.trim().isEmpty) {
      return ReceivePaymentRefundResult.missingCheque;
    }

    emit(state.copyWith(
        amountError: false, isSubmitting: true, errorMessage: null));
    try {
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final params = InvoicePaymentParams(
        schoolCode: schoolCode,
        amount: double.tryParse(amount.trim()) ?? 0,
        date: DateTime.now(),
        ownerType: ownerType,
        ownerCode: ownerCode,
        studentCode: studentCode,
        method: state.selectedPaymentType,
        reference: chequeNumber.trim().isEmpty ? null : chequeNumber.trim(),
        narration: narration,
      );

      if (isRefund) {
        await _createRefund(params);
      } else {
        await _createPayment(params);
      }

      if (isClosed) return ReceivePaymentRefundResult.success;
      emit(state.copyWith(isSubmitting: false));
      return ReceivePaymentRefundResult.success;
    } catch (e) {
      if (isClosed) return ReceivePaymentRefundResult.failure;
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return ReceivePaymentRefundResult.failure;
    }
  }
}
