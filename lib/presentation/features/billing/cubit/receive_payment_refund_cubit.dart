import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'receive_payment_refund_state.dart';

/// Result of a receive-payment / issue-refund submission so the view can show
/// the right snackbar.
enum ReceivePaymentRefundResult { missingAmount, missingType, missingCheque, success }

/// Owns the non-text state for the receive-payment / issue-refund form: payment
/// type, email-notification flag, validation + submit flags. The view keeps its
/// text controllers and passes their values into [validateAndSave].
class ReceivePaymentRefundCubit extends Cubit<ReceivePaymentRefundState> {
  ReceivePaymentRefundCubit() : super(const ReceivePaymentRefundState.initial());

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

    emit(state.copyWith(amountError: false, isSubmitting: true));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (isClosed) return ReceivePaymentRefundResult.success;
    emit(state.copyWith(isSubmitting: false));
    return ReceivePaymentRefundResult.success;
  }
}
