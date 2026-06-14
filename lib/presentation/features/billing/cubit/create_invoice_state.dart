part of 'create_invoice_cubit.dart';

class CreateInvoiceState extends Equatable {
  const CreateInvoiceState({
    required this.items,
    required this.invoiceDate,
    required this.dueDate,
    required this.catalog,
    required this.catalogLoaded,
    required this.isFormLocked,
    required this.revision,
  });

  /// Starts with a single primary item row and an empty catalog.
  factory CreateInvoiceState.initial() => CreateInvoiceState(
        items: [InvoiceItemFormData.initial(isPrimary: true)],
        invoiceDate: null,
        dueDate: null,
        catalog: const <String, List<InvoiceCatalogOption>>{},
        catalogLoaded: false,
        isFormLocked: false,
        revision: 0,
      );

  final List<InvoiceItemFormData> items;
  final DateTime? invoiceDate;
  final DateTime? dueDate;

  /// Selectable Item Description entries keyed by item type
  /// (Tuition Fee / Other Fee / Discount / Subsidy).
  final Map<String, List<InvoiceCatalogOption>> catalog;

  /// True once the catalog prefetch has completed (even if some lists are
  /// empty) — lets the UI show "No … available" instead of a stuck loader.
  final bool catalogLoaded;

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
      if (InvoiceItemTypes.isDeduction(item.type)) {
        total -= amount;
      } else {
        total += amount;
      }
    }
    return total;
  }

  CreateInvoiceState copyWith({
    List<InvoiceItemFormData>? items,
    DateTime? Function()? invoiceDate,
    DateTime? Function()? dueDate,
    Map<String, List<InvoiceCatalogOption>>? catalog,
    bool? catalogLoaded,
    bool? isFormLocked,
    int? revision,
  }) {
    return CreateInvoiceState(
      items: items ?? this.items,
      invoiceDate: invoiceDate != null ? invoiceDate() : this.invoiceDate,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      catalog: catalog ?? this.catalog,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      isFormLocked: isFormLocked ?? this.isFormLocked,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
        invoiceDate,
        dueDate,
        catalog,
        catalogLoaded,
        isFormLocked,
        revision,
      ];
}
