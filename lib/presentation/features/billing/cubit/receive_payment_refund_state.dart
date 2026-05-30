part of 'receive_payment_refund_cubit.dart';

class ReceivePaymentRefundState extends Equatable {
  const ReceivePaymentRefundState({
    required this.isSubmitting,
    required this.amountError,
    required this.sendEmailNotification,
    required this.selectedPaymentType,
  });

  const ReceivePaymentRefundState.initial()
      : isSubmitting = false,
        amountError = false,
        sendEmailNotification = true,
        selectedPaymentType = null;

  final bool isSubmitting;
  final bool amountError;
  final bool sendEmailNotification;
  final String? selectedPaymentType;

  ReceivePaymentRefundState copyWith({
    bool? isSubmitting,
    bool? amountError,
    bool? sendEmailNotification,
    String? Function()? selectedPaymentType,
  }) {
    return ReceivePaymentRefundState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      amountError: amountError ?? this.amountError,
      sendEmailNotification:
          sendEmailNotification ?? this.sendEmailNotification,
      selectedPaymentType: selectedPaymentType != null
          ? selectedPaymentType()
          : this.selectedPaymentType,
    );
  }

  @override
  List<Object?> get props =>
      [isSubmitting, amountError, sendEmailNotification, selectedPaymentType];
}
