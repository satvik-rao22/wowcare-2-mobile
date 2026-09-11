import 'package:equatable/equatable.dart';

/// A single invoice line item carried through the create-invoice preview flow.
///
/// Presentation carrier only (replaces the old
/// `{'type':…, 'description':…, 'amount':…}` map). `amount`/`description` are
/// kept as the raw entered strings — they are parsed at the display/compute
/// sites exactly as before (`double.tryParse(amount)`), so no money parsing
/// changes here.
class InvoiceDraftItem extends Equatable {
  const InvoiceDraftItem({
    required this.type,
    required this.description,
    required this.amount,
  });

  final String type;
  final String description;
  final String amount;

  @override
  List<Object?> get props => [type, description, amount];
}

/// The in-flight invoice draft threaded between the create-invoice screens
/// (create → select-students → preview) and used to seed the create-invoice
/// cubit when editing.
///
/// Presentation carrier only, replacing the raw `Map<String, dynamic>?`
/// (`invoiceData` / `initialInvoiceData`). All fields are optional so the same
/// model serves both the "seed for edit" shape (just `invoiceCode`) and the
/// full preview draft. Dates are held as [DateTime] — the producers always
/// supply real `DateTime`s from the cubit form state, matching the old
/// `value is DateTime` reads; [dateFrom] provides the same DateTime-or-String
/// tolerance for any caller building from a loose map.
class InvoiceDraft extends Equatable {
  const InvoiceDraft({
    this.invoiceCode,
    this.internalNote,
    this.invoiceItems = const <InvoiceDraftItem>[],
    this.invoiceDate,
    this.dueDate,
    this.serviceDate,
    this.serviceDateEnd,
  });

  final String? invoiceCode;
  final String? internalNote;
  final List<InvoiceDraftItem> invoiceItems;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final DateTime? serviceDate;
  final DateTime? serviceDateEnd;

  /// Tolerant date reader preserving the old `value is DateTime ? value : …`
  /// behavior: a real [DateTime] is used as-is, a non-empty [String] is parsed
  /// (returning null if unparseable), anything else is null.
  static DateTime? dateFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        invoiceCode,
        internalNote,
        invoiceItems,
        invoiceDate,
        dueDate,
        serviceDate,
        serviceDateEnd,
      ];
}
