import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/discount_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_catalog_entities.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/issue_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/update_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_discounts_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_fee_structures_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_other_fees_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_subsidies_usecase.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';

part 'create_invoice_state.dart';

/// Item type identifiers. The first (mandatory) item may be a [newItem],
/// [tuitionFee] or [otherFee]; additional items add [discount] and [subsidy].
class InvoiceItemTypes {
  static const String newItem = 'New Item';
  static const String tuitionFee = 'Tuition Fee';
  static const String otherFee = 'Other Fee';
  static const String discount = 'Discount';
  static const String subsidy = 'Subsidy';

  static const List<String> firstItemOptions = [newItem, tuitionFee, otherFee];
  static const List<String> additionalItemOptions = [
    newItem,
    tuitionFee,
    otherFee,
    discount,
    subsidy,
  ];

  /// Types whose Item Description is a catalog-backed dropdown (and whose
  /// amount is auto-filled from the chosen entry).
  static const Set<String> catalogTypes = {
    tuitionFee,
    otherFee,
    discount,
    subsidy,
  };

  /// Types that subtract from the invoice total.
  static bool isDeduction(String type) => type == discount || type == subsidy;

  /// Maps a display type to the API `itemType` enum value.
  static String apiCode(String type) {
    switch (type) {
      case tuitionFee:
        return 'TUITION_FEE';
      case otherFee:
        return 'OTHER_FEE';
      case discount:
        return 'DISCOUNT';
      case subsidy:
        return 'SUBSIDY';
      default:
        return 'NEW_ITEM';
    }
  }
}

/// Outcome of [CreateInvoiceCubit.submitInvoices].
class InvoiceSubmitResult {
  const InvoiceSubmitResult({
    required this.success,
    this.created = 0,
    this.error,
  });

  final bool success;
  final int created;
  final String? error;
}

/// Owns the create-invoice form: the invoice item rows (each backed by its own
/// controllers), the invoice/due dates, and the catalog of selectable entries
/// (tuition fee structures, other fees, discounts, subsidies) prefetched once
/// on open so the description dropdowns never show a loader.
///
/// Because the item rows hold [TextEditingController]s (which aren't value-
/// comparable), mutations bump [CreateInvoiceState.revision] to drive rebuilds.
class CreateInvoiceCubit extends Cubit<CreateInvoiceState> {
  CreateInvoiceCubit({
    required GetFeeStructuresUseCase getFeeStructures,
    required GetOtherFeesUseCase getOtherFees,
    required GetDiscountsUseCase getDiscounts,
    required GetSubsidiesUseCase getSubsidies,
    required CreateInvoiceUseCase createInvoice,
    required IssueInvoiceUseCase issueInvoice,
    required UpdateInvoiceUseCase updateInvoice,
    required StorageService storage,
  })  : _getFeeStructures = getFeeStructures,
        _getOtherFees = getOtherFees,
        _getDiscounts = getDiscounts,
        _getSubsidies = getSubsidies,
        _createInvoice = createInvoice,
        _issueInvoice = issueInvoice,
        _updateInvoice = updateInvoice,
        _storage = storage,
        super(CreateInvoiceState.initial());

  final GetFeeStructuresUseCase _getFeeStructures;
  final GetOtherFeesUseCase _getOtherFees;
  final GetDiscountsUseCase _getDiscounts;
  final GetSubsidiesUseCase _getSubsidies;
  final CreateInvoiceUseCase _createInvoice;
  final IssueInvoiceUseCase _issueInvoice;
  final UpdateInvoiceUseCase _updateInvoice;
  final StorageService _storage;

  /// When editing an existing invoice, its code — set from `initialize` data.
  /// Drives [submitInvoices] to PATCH instead of POST.
  String? _editingInvoiceCode;

  bool get isEditing =>
      _editingInvoiceCode != null && _editingInvoiceCode!.isNotEmpty;

  /// Hydrates items + dates from a previously-built invoice payload, then kicks
  /// off the (silent) catalog prefetch.
  void initialize(Map<String, dynamic>? data) {
    if (data != null) {
      final rawCode = data['invoiceCode']?.toString().trim();
      _editingInvoiceCode = (rawCode != null && rawCode.isNotEmpty) ? rawCode : null;
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
              type: map['type']?.toString() ?? InvoiceItemTypes.newItem,
              description: map['description']?.toString() ?? '',
              amount: map['amount']?.toString() ?? '',
              isPrimary: index == 0,
            );
          }).toList();
        }
      }

      emit(state.copyWith(
        items: items,
        invoiceDate: () => data['invoiceDate'] is DateTime
            ? data['invoiceDate'] as DateTime
            : state.invoiceDate,
        dueDate: () => data['dueDate'] is DateTime
            ? data['dueDate'] as DateTime
            : state.dueDate,
        revision: state.revision + 1,
      ));
    }

    loadCatalog();
  }

  /// Prefetches the four catalogs in parallel. Failures are swallowed per-call
  /// so one failing endpoint never blanks the others; the dropdowns simply stay
  /// empty until data arrives (no loader is shown).
  Future<void> loadCatalog() async {
    final school =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (school.isEmpty) {
      if (!isClosed) emit(state.copyWith(catalogLoaded: true));
      return;
    }

    final results = await Future.wait([
      _safe(() async => _feeStructureOptions(
          await _getFeeStructures(school: school, status: 'ACTIVE'))),
      _safe(() async => _otherFeeOptions(
          await _getOtherFees(school: school, status: 'ACTIVE'))),
      _safe(() async => _discountOptions(
          (await _getDiscounts(school: school, status: 'ACTIVE', size: 200))
              .content)),
      _safe(() async => _subsidyOptions(
          await _getSubsidies(school: school, status: 'ACTIVE'))),
    ]);

    if (isClosed) return;
    emit(state.copyWith(
      catalog: <String, List<InvoiceCatalogOption>>{
        InvoiceItemTypes.tuitionFee: results[0],
        InvoiceItemTypes.otherFee: results[1],
        InvoiceItemTypes.discount: results[2],
        InvoiceItemTypes.subsidy: results[3],
      },
      catalogLoaded: true,
      revision: state.revision + 1,
    ));
  }

  Future<List<InvoiceCatalogOption>> _safe(
      Future<List<InvoiceCatalogOption>> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return const <InvoiceCatalogOption>[];
    }
  }

  // ─── Catalog → option mappers ─────────────────────────────────────────────

  List<InvoiceCatalogOption> _feeStructureOptions(
      List<FeeStructureEntity> structures) {
    final options = <InvoiceCatalogOption>[];
    for (final s in structures) {
      for (final d in s.feesDetails) {
        if (!d.isActive) continue;
        final cycle = d.billingCycle.trim();
        final label = cycle.isEmpty
            ? s.ageGroupName.trim()
            : '${s.ageGroupName.trim()} — $cycle';
        options.add(InvoiceCatalogOption(
            label: label, amount: d.cost, code: d.code));
      }
    }
    return options;
  }

  List<InvoiceCatalogOption> _otherFeeOptions(List<OtherFeeEntity> fees) => [
        for (final f in fees)
          if (f.description.trim().isNotEmpty)
            InvoiceCatalogOption(
                label: f.description.trim(), amount: f.cost, code: f.code),
      ];

  /// Normalizes a catalog `discountType` to the API value type the invoice
  /// payload expects (`PERCENT` / `FLAT`).
  static String _normalizeValueType(String? raw) {
    final v = (raw ?? '').trim().toUpperCase();
    if (v == 'PERCENT' || v == 'PERCENTAGE' || v == '%') return 'PERCENT';
    return 'FLAT';
  }

  List<InvoiceCatalogOption> _discountOptions(List<DiscountEntity> discounts) =>
      [
        for (final d in discounts)
          if (d.name.trim().isNotEmpty)
            () {
              final valueType = _normalizeValueType(d.discountType);
              return InvoiceCatalogOption(
                label: d.name.trim(),
                amount: d.deductionAmount ?? d.price ?? 0,
                code: d.code,
                valueType: valueType,
                valueInput: valueType == 'PERCENT'
                    ? d.percentage
                    : (d.deductionAmount ?? d.price ?? 0),
              );
            }(),
      ];

  List<InvoiceCatalogOption> _subsidyOptions(List<SubsidyEntity> subsidies) => [
        for (final s in subsidies)
          if (s.name.trim().isNotEmpty)
            InvoiceCatalogOption(
              label: s.name.trim(),
              amount: s.deductionAmount ?? s.price ?? 0,
              code: s.code,
              valueType: _normalizeValueType(s.discountType),
              valueInput: s.deductionAmount ?? s.price ?? 0,
            ),
      ];

  // ─── Intents ──────────────────────────────────────────────────────────────

  void setInvoiceDate(DateTime? value) =>
      emit(state.copyWith(invoiceDate: () => value));
  void setDueDate(DateTime? value) =>
      emit(state.copyWith(dueDate: () => value));

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
    String? value,
    String? valueType,
  }) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];

    if (type != null && type != item.type) {
      item.type = type;
      // Switching type clears the previous selection so a stale catalog label
      // / amount / source code / discount value can't leak across types.
      item.description = '';
      item.descriptionController.text = '';
      item.amount = '';
      item.amountController.text = '';
      item.sourceCode = null;
      item.valueType = null;
      item.valueController.clear();
    }

    if (description != null) {
      item.description = description;
      if (item.descriptionController.text != description) {
        item.descriptionController.text = description;
      }
      // Catalog-backed types auto-fill source code (+ amount or discount value)
      // from the chosen entry.
      if (InvoiceItemTypes.catalogTypes.contains(item.type)) {
        final option = _optionForLabel(item.type, description);
        if (option != null) {
          item.sourceCode = option.code;
          if (InvoiceItemTypes.isDeduction(item.type)) {
            // Discount/subsidy: seed the value + type; amount is computed.
            item.valueType = option.valueType ?? 'FLAT';
            final seed = option.valueInput ?? option.amount;
            item.valueController.text = _formatValue(seed);
          } else {
            final filled = option.amount.toStringAsFixed(2);
            item.amount = filled;
            item.amountController.text = filled;
          }
        }
      }
    }

    if (value != null) {
      if (item.valueController.text != value) {
        item.valueController.text = value;
      }
    }

    if (valueType != null) {
      item.valueType = valueType;
    }

    if (amount != null) {
      item.amount = amount;
      if (item.amountController.text != amount) {
        item.amountController.text = amount;
      }
    }

    // Discount/subsidy amounts derive from their value + the fee base, so
    // recompute them after any change (a fee edit changes a PERCENT result).
    _recomputeDeductions();

    emit(state.copyWith(revision: state.revision + 1));
  }

  /// Sum of the non-deduction item amounts — the base a PERCENT discount or
  /// subsidy is applied against.
  double _feeBase() {
    double base = 0;
    for (final item in state.items) {
      if (InvoiceItemTypes.isDeduction(item.type)) continue;
      base += double.tryParse(item.amountController.text.trim().isEmpty
              ? item.amount
              : item.amountController.text.trim()) ??
          0;
    }
    return base;
  }

  /// Recomputes each discount/subsidy row's amount from its value + type:
  /// `PERCENT` → value% of the fee base, `FLAT` → the value itself.
  void _recomputeDeductions() {
    final base = _feeBase();
    for (final item in state.items) {
      if (!InvoiceItemTypes.isDeduction(item.type)) continue;
      final value = double.tryParse(item.valueController.text.trim()) ?? 0;
      final computed =
          (item.valueType ?? 'FLAT') == 'PERCENT' ? base * value / 100 : value;
      final filled = computed.toStringAsFixed(2);
      item.amount = filled;
      item.amountController.text = filled;
    }
  }

  /// Formats a seeded discount value without trailing zeros (e.g. `12`, `2.5`).
  String _formatValue(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  InvoiceCatalogOption? _optionForLabel(String type, String label) {
    final options = state.catalog[type];
    if (options == null) return null;
    for (final o in options) {
      if (o.label == label) return o;
    }
    return null;
  }

  /// Creates one invoice per [students] entry via `POST /api/v1/invoices`,
  /// reusing the same items/dates/notes. Returns a single aggregated result.
  Future<InvoiceSubmitResult> submitInvoices({
    required List<Student> students,
    required String mode,
    String? notes,
  }) async {
    final issueDate = state.invoiceDate;
    final dueDate = state.dueDate;
    if (issueDate == null || dueDate == null) {
      return const InvoiceSubmitResult(
          success: false, error: 'Please select the invoice and due dates.');
    }
    if (students.isEmpty) {
      return const InvoiceSubmitResult(
          success: false, error: 'Please keep at least one student.');
    }

    final items = _buildItemParams();
    if (items.isEmpty) {
      return const InvoiceSubmitResult(
          success: false, error: 'Please add at least one invoice item.');
    }

    try {
      final shouldIssue = mode == 'send';

      // Edit mode: PATCH the existing invoice (single), then optionally issue it.
      if (isEditing) {
        await _updateInvoice(
          code: _editingInvoiceCode!,
          params: UpdateInvoiceParams(
            issueDate: issueDate,
            dueDate: dueDate,
            items: _buildUpdateItemParams(),
          ),
        );
        if (shouldIssue) {
          await _issueInvoice(_editingInvoiceCode!);
        }
        return const InvoiceSubmitResult(success: true, created: 1);
      }

      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

      var created = 0;
      for (final student in students) {
        final result = await _createInvoice(CreateInvoiceParams(
          organizationCode: org,
          schoolCode: school,
          studentCode: student.code,
          issueDate: issueDate,
          dueDate: dueDate,
          notes: notes,
          items: items,
        ));
        // "Save & Send" issues the freshly-created invoice; "Save as Draft"
        // leaves it unissued.
        if (shouldIssue && result.code.isNotEmpty) {
          await _issueInvoice(result.code);
        }
        created += 1;
      }
      return InvoiceSubmitResult(success: true, created: created);
    } catch (e) {
      return InvoiceSubmitResult(
          success: false, error: ApiErrorHandler.extractErrorMessage(e));
    }
  }

  /// Items for the update (PATCH) payload — the API's update item shape only
  /// carries description/quantity/unit/total.
  List<UpdateInvoiceItemParams> _buildUpdateItemParams() {
    final result = <UpdateInvoiceItemParams>[];
    for (final item in state.items) {
      final amount = double.tryParse(item.amountController.text.isEmpty
              ? item.amount
              : item.amountController.text) ??
          0;
      final description = item.descriptionController.text.trim().isEmpty
          ? item.description.trim()
          : item.descriptionController.text.trim();
      if (description.isEmpty) continue;
      result.add(UpdateInvoiceItemParams(
        description: description,
        quantity: 1,
        unitPrice: amount,
        totalPrice: amount,
      ));
    }
    return result;
  }

  List<CreateInvoiceItemParams> _buildItemParams() {
    final result = <CreateInvoiceItemParams>[];
    for (final item in state.items) {
      final amount = double.tryParse(item.amountController.text.isEmpty
              ? item.amount
              : item.amountController.text) ??
          0;
      final description = item.descriptionController.text.trim().isEmpty
          ? item.description.trim()
          : item.descriptionController.text.trim();
      if (description.isEmpty) continue;
      final isDeduction = InvoiceItemTypes.isDeduction(item.type);
      result.add(CreateInvoiceItemParams(
        itemType: InvoiceItemTypes.apiCode(item.type),
        description: description,
        amount: amount,
        quantity: 1,
        sourceCode: item.sourceCode,
        valueType: isDeduction ? (item.valueType ?? 'FLAT') : null,
        valueInput: isDeduction
            ? (double.tryParse(item.valueController.text.trim()) ?? 0)
            : null,
      ));
    }
    return result;
  }

  @override
  Future<void> close() {
    for (final item in state.items) {
      item.dispose();
    }
    return super.close();
  }
}

/// A selectable catalog entry surfaced in an Item Description dropdown.
class InvoiceCatalogOption extends Equatable {
  const InvoiceCatalogOption({
    required this.label,
    required this.amount,
    this.code,
    this.valueType,
    this.valueInput,
  });

  final String label;
  final double amount;
  final String? code;

  /// For discount/subsidy entries: the default value type (`PERCENT`/`FLAT`)
  /// and the value (e.g. `12` for 12%). Null for plain fee entries.
  final String? valueType;
  final double? valueInput;

  @override
  List<Object?> get props => [label, amount, code, valueType, valueInput];
}

class InvoiceItemFormData {
  InvoiceItemFormData({
    required this.type,
    required this.description,
    required this.amount,
    this.isPrimary = false,
  })  : descriptionController = TextEditingController(text: description),
        amountController = TextEditingController(text: amount);

  factory InvoiceItemFormData.initial({bool isPrimary = false}) {
    return InvoiceItemFormData(
      type: InvoiceItemTypes.newItem,
      description: '',
      amount: '',
      isPrimary: isPrimary,
    );
  }

  String type;
  String description;
  String amount;

  /// For catalog-backed types, the selected entry's source code (fee detail /
  /// other fee / discount / subsidy code) sent to the API as `sourceCode`.
  String? sourceCode;

  /// For discount/subsidy rows: `PERCENT` or `FLAT`. The `valueController`
  /// holds the value (e.g. `12`); the [amount] is computed from it.
  String? valueType;
  final TextEditingController valueController = TextEditingController();

  final bool isPrimary;

  final TextEditingController descriptionController;
  final TextEditingController amountController;

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    valueController.dispose();
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
