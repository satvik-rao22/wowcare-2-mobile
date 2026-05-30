import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

part 'create_invoice_state.dart';

/// Owns the create-invoice form's structural state: the invoice item rows
/// (each backed by its own controllers), the due/service dates, and the
/// form-locked flag.
///
/// Because the item rows hold [TextEditingController]s (which aren't value-
/// comparable), mutations bump [CreateInvoiceState.revision] to drive rebuilds.
/// The cubit owns the item controllers and disposes them in [close].
class CreateInvoiceCubit extends Cubit<CreateInvoiceState> {
  CreateInvoiceCubit() : super(CreateInvoiceState.initial());

  /// Hydrates items + dates from a previously-built invoice payload.
  void initialize(Map<String, dynamic>? data) {
    if (data == null) return;

    var items = state.items;
    if (data['invoiceItems'] is List) {
      final raw = data['invoiceItems'] as List<dynamic>;
      if (raw.isNotEmpty) {
        for (final item in state.items) {
          item.dispose();
        }
        items = raw.mapIndexed((index, r) {
          final map = r as Map<String, dynamic>;
          return InvoiceItemFormData(
            type: map['type']?.toString() ??
                (index == 0 ? 'New Item' : 'Preset Item'),
            description: map['description']?.toString() ?? '',
            amount: map['amount']?.toString() ?? '',
            deductionAmount: map['deductionAmt']?.toString() ?? '',
            percentageAmount: map['percentageAmt']?.toString() ?? '',
            currencySign: map['currencySign']?.toString() ?? '%',
            isPrimary: index == 0,
          );
        }).toList();
      }
    }

    emit(state.copyWith(
      items: items,
      dueDate: () =>
          data['invoiceDate'] is DateTime ? data['invoiceDate'] as DateTime : state.dueDate,
      serviceStartDate: () => data['serviceDate'] is DateTime
          ? data['serviceDate'] as DateTime
          : state.serviceStartDate,
      serviceEndDate: () => data['serviceDateEnd'] is DateTime
          ? data['serviceDateEnd'] as DateTime
          : state.serviceEndDate,
      revision: state.revision + 1,
    ));
    for (var i = 0; i < state.items.length; i++) {
      _recalculateDiscountAmount(i);
    }
  }

  void setDueDate(DateTime? value) =>
      emit(state.copyWith(dueDate: () => value));
  void setServiceStartDate(DateTime? value) =>
      emit(state.copyWith(serviceStartDate: () => value));
  void setServiceEndDate(DateTime? value) =>
      emit(state.copyWith(serviceEndDate: () => value));

  void addItem() {
    if (state.isFormLocked) return;
    emit(state.copyWith(
      items: [...state.items, InvoiceItemFormData.initial()],
      revision: state.revision + 1,
    ));
  }

  void removeItem(int index) {
    if (state.isFormLocked || index == 0 || index >= state.items.length) return;
    final items = List<InvoiceItemFormData>.from(state.items);
    items.removeAt(index).dispose();
    emit(state.copyWith(items: items, revision: state.revision + 1));
  }

  void updateItem(
    int index, {
    String? type,
    String? description,
    String? amount,
    String? deduction,
    String? percentage,
    String? currencySign,
  }) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];

    if (type != null) {
      item.type = type;
      if (type == 'Discount' || type == 'Subsidy') {
        item.currencySign = currencySign ?? item.currencySign;
        item.amountController.text =
            item.amountController.text.isEmpty ? '0' : item.amountController.text;
      }
    }
    if (description != null) {
      item.description = description;
      if (item.descriptionController.text != description) {
        item.descriptionController.text = description;
      }
    }
    if (amount != null) {
      item.amount = amount;
      if (item.amountController.text != amount) {
        item.amountController.text = amount;
      }
    }
    if (deduction != null) {
      item.deductionAmount = deduction;
      if (item.deductionController.text != deduction) {
        item.deductionController.text = deduction;
      }
    }
    if (percentage != null) {
      item.percentageAmount = percentage;
      if (item.percentageController.text != percentage) {
        item.percentageController.text = percentage;
      }
    }
    if (currencySign != null) {
      item.currencySign = currencySign;
    }
    _recalculateDiscountAmount(index);
    emit(state.copyWith(revision: state.revision + 1));
  }

  void _recalculateDiscountAmount(int index) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    if (item.type != 'Discount' && item.type != 'Subsidy') return;

    final deductionValue = double.tryParse(item.deductionController.text.isEmpty
            ? item.deductionAmount
            : item.deductionController.text) ??
        0;
    if (item.currencySign == '%') {
      final baseAmount = double.tryParse(item.percentageController.text.isEmpty
              ? item.percentageAmount
              : item.percentageController.text) ??
          0;
      final calculated = (baseAmount * deductionValue) / 100;
      item.amount = calculated.toStringAsFixed(2);
      item.amountController
        ..text = calculated.toStringAsFixed(2)
        ..selection = TextSelection.fromPosition(
            TextPosition(offset: item.amountController.text.length));
    } else {
      item.amount = deductionValue.toStringAsFixed(2);
      item.amountController
        ..text = deductionValue.toStringAsFixed(2)
        ..selection = TextSelection.fromPosition(
            TextPosition(offset: item.amountController.text.length));
    }
  }

  @override
  Future<void> close() {
    for (final item in state.items) {
      item.dispose();
    }
    return super.close();
  }
}

class InvoiceItemFormData {
  InvoiceItemFormData({
    required this.type,
    required this.description,
    required this.amount,
    required this.deductionAmount,
    required this.percentageAmount,
    required this.currencySign,
    this.isPrimary = false,
  })  : descriptionController = TextEditingController(text: description),
        amountController = TextEditingController(text: amount),
        deductionController = TextEditingController(text: deductionAmount),
        percentageController = TextEditingController(text: percentageAmount);

  factory InvoiceItemFormData.initial({bool isPrimary = false}) {
    return InvoiceItemFormData(
      type: isPrimary ? 'New Item' : 'Preset Item',
      description: '',
      amount: '',
      deductionAmount: '',
      percentageAmount: '',
      currencySign: '%',
      isPrimary: isPrimary,
    );
  }

  String type;
  String description;
  String amount;
  String deductionAmount;
  String percentageAmount;
  String currencySign;
  final bool isPrimary;

  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final TextEditingController deductionController;
  final TextEditingController percentageController;

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    deductionController.dispose();
    percentageController.dispose();
  }
}

extension IterableMapIndexedExtension<T> on Iterable<T> {
  List<R> mapIndexed<R>(R Function(int index, T value) callback) {
    var index = 0;
    final result = <R>[];
    for (final value in this) {
      result.add(callback(index, value));
      index += 1;
    }
    return result;
  }
}
