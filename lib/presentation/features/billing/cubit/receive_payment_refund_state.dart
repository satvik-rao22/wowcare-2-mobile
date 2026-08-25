part of 'receive_payment_refund_cubit.dart';

class ReceivePaymentRefundState extends Equatable {
  const ReceivePaymentRefundState({
    required this.isSubmitting,
    required this.amountError,
    required this.sendEmailNotification,
    required this.selectedPaymentType,
    required this.payableStudents,
    required this.isLoadingStudents,
    this.errorMessage,
  });

  const ReceivePaymentRefundState.initial()
    : isSubmitting = false,
      amountError = false,
      sendEmailNotification = true,
      selectedPaymentType = null,
      payableStudents = const <PayableStudent>[],
      isLoadingStudents = false,
      errorMessage = null;

  final bool isSubmitting;
  final bool amountError;
  final bool sendEmailNotification;
  final String? selectedPaymentType;
  final List<PayableStudent> payableStudents;
  final bool isLoadingStudents;
  final String? errorMessage;

  ReceivePaymentRefundState copyWith({
    bool? isSubmitting,
    bool? amountError,
    bool? sendEmailNotification,
    String? Function()? selectedPaymentType,
    List<PayableStudent>? payableStudents,
    bool? isLoadingStudents,
    String? errorMessage,
  }) {
    return ReceivePaymentRefundState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      amountError: amountError ?? this.amountError,
      sendEmailNotification:
          sendEmailNotification ?? this.sendEmailNotification,
      selectedPaymentType: selectedPaymentType != null
          ? selectedPaymentType()
          : this.selectedPaymentType,
      payableStudents: payableStudents ?? this.payableStudents,
      isLoadingStudents: isLoadingStudents ?? this.isLoadingStudents,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isSubmitting,
    amountError,
    sendEmailNotification,
    selectedPaymentType,
    payableStudents,
    isLoadingStudents,
    errorMessage,
  ];
}
