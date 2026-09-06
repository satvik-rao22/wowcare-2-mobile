part of 'view_invoice_cubit.dart';

class ViewInvoiceState extends Equatable {
  const ViewInvoiceState({
    this.roomName,
    this.invoiceDetail,
  });

  /// The student's current classroom, looked up by student code (null until it
  /// resolves, or if the lookup failed / there was no student code).
  final String? roomName;

  /// The full invoice fetched by code — carries invoice number, due date and
  /// service period the transaction summary lacks (null until it resolves).
  final InvoiceListItemEntity? invoiceDetail;

  ViewInvoiceState copyWith({
    String? roomName,
    InvoiceListItemEntity? invoiceDetail,
  }) {
    return ViewInvoiceState(
      roomName: roomName ?? this.roomName,
      invoiceDetail: invoiceDetail ?? this.invoiceDetail,
    );
  }

  @override
  List<Object?> get props => [roomName, invoiceDetail];
}
