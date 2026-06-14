/// Response model for `GET /api/v1/invoices/overview`.
class InvoiceOverviewModel {
  const InvoiceOverviewModel({
    required this.amountInvoiced,
    required this.paid,
    required this.refunded,
    required this.netPaid,
    required this.inProcess,
    required this.outstanding,
  });

  final double amountInvoiced;
  final double paid;
  final double refunded;
  final double netPaid;
  final double inProcess;
  final double outstanding;

  factory InvoiceOverviewModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    double d(String key) => (data[key] as num?)?.toDouble() ?? 0;
    return InvoiceOverviewModel(
      amountInvoiced: d('amountInvoiced'),
      paid: d('paid'),
      refunded: d('refunded'),
      netPaid: d('netPaid'),
      inProcess: d('inProcess'),
      outstanding: d('outstanding'),
    );
  }
}
