part of 'send_invoice_cubit.dart';

class SendInvoiceState extends Equatable {
  const SendInvoiceState({
    this.roomName,
    this.isSending = false,
    this.errorMessage,
  });

  /// The student's current classroom, looked up by student code (null until it
  /// resolves, or if the lookup failed / there was no student code).
  final String? roomName;

  /// True while the issue/resend request is in flight (drives the button
  /// spinner and disables the button).
  final bool isSending;

  /// Last send failure message, cleared when a new send starts.
  final String? errorMessage;

  SendInvoiceState copyWith({
    String? roomName,
    bool? isSending,
    String? errorMessage,
  }) {
    return SendInvoiceState(
      roomName: roomName ?? this.roomName,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [roomName, isSending, errorMessage];
}
