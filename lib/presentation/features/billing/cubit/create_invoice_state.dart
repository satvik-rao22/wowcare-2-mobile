part of 'create_invoice_cubit.dart';

class CreateInvoiceState extends Equatable {
  const CreateInvoiceState({
    required this.items,
    required this.dueDate,
    required this.serviceStartDate,
    required this.serviceEndDate,
    required this.isFormLocked,
    required this.revision,
  });

  /// Starts with a single primary item row.
  factory CreateInvoiceState.initial() => CreateInvoiceState(
        items: [InvoiceItemFormData.initial(isPrimary: true)],
        dueDate: null,
        serviceStartDate: null,
        serviceEndDate: null,
        isFormLocked: false,
        revision: 0,
      );

  final List<InvoiceItemFormData> items;
  final DateTime? dueDate;
  final DateTime? serviceStartDate;
  final DateTime? serviceEndDate;
  final bool isFormLocked;

  /// Bumped on every in-place item mutation so equality-based rebuilds fire
  /// even though the item objects (which hold controllers) aren't comparable.
  final int revision;

  double get totalAmount {
    double total = 0;
    for (final item in items) {
      final amount = double.tryParse(item.amountController.text.isEmpty
              ? item.amount
              : item.amountController.text) ??
          0;
      if (item.type == 'Discount' || item.type == 'Subsidy') {
        total -= amount;
      } else {
        total += amount;
      }
    }
    return total;
  }

  CreateInvoiceState copyWith({
    List<InvoiceItemFormData>? items,
    DateTime? Function()? dueDate,
    DateTime? Function()? serviceStartDate,
    DateTime? Function()? serviceEndDate,
    bool? isFormLocked,
    int? revision,
  }) {
    return CreateInvoiceState(
      items: items ?? this.items,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      serviceStartDate:
          serviceStartDate != null ? serviceStartDate() : this.serviceStartDate,
      serviceEndDate:
          serviceEndDate != null ? serviceEndDate() : this.serviceEndDate,
      isFormLocked: isFormLocked ?? this.isFormLocked,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
        dueDate,
        serviceStartDate,
        serviceEndDate,
        isFormLocked,
        revision,
      ];
}
