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
    required StorageService storage,
  })  : _getFeeStructures = getFeeStructures,
        _getOtherFees = getOtherFees,
        _getDiscounts = getDiscounts,
        _getSubsidies = getSubsidies,
        _createInvoice = createInvoice,
        _issueInvoice = issueInvoice,
        _storage = storage,
        super(CreateInvoiceState.initial());

  final GetFeeStructuresUseCase _getFeeStructures;
  final GetOtherFeesUseCase _getOtherFees;
  final GetDiscountsUseCase _getDiscounts;
  final GetSubsidiesUseCase _getSubsidies;
  final CreateInvoiceUseCase _createInvoice;
  final IssueInvoiceUseCase _issueInvoice;
  final StorageService _storage;

  /// Hydrates items + dates from a previously-built invoice payload, then kicks
  /// off the (silent) catalog prefetch.
  void initialize(Map<String, dynamic>? data) {
    if (data != null) {
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

  List<InvoiceCatalogOption> _discountOptions(List<DiscountEntity> discounts) =>
      [
        for (final d in discounts)
          if (d.name.trim().isNotEmpty)
            InvoiceCatalogOption(
              label: d.name.trim(),
              amount: d.deductionAmount ?? d.price ?? 0,
              code: d.code,
            ),
      ];

  List<InvoiceCatalogOption> _subsidyOptions(List<SubsidyEntity> subsidies) => [
        for (final s in subsidies)
          if (s.name.trim().isNotEmpty)
            InvoiceCatalogOption(
              label: s.name.trim(),
              amount: s.deductionAmount ?? s.price ?? 0,
              code: s.code,
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
  }) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];

    if (type != null && type != item.type) {
      item.type = type;
      // Switching type clears the previous selection so a stale catalog label
      // / amount / source code can't leak across types.
      item.description = '';
      item.descriptionController.text = '';
      item.amount = '';
      item.amountController.text = '';
      item.sourceCode = null;
    }

    if (description != null) {
      item.description = description;
      if (item.descriptionController.text != description) {
        item.descriptionController.text = description;
      }
      // Catalog-backed types auto-fill the amount + source code from the entry.
      if (InvoiceItemTypes.catalogTypes.contains(item.type)) {
        final option = _optionForLabel(item.type, description);
        if (option != null) {
          final filled = option.amount.toStringAsFixed(2);
          item.amount = filled;
          item.amountController.text = filled;
          item.sourceCode = option.code;
        }
      }
    }

    if (amount != null) {
      item.amount = amount;
      if (item.amountController.text != amount) {
        item.amountController.text = amount;
      }
    }

    emit(state.copyWith(revision: state.revision + 1));
  }

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
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

      final shouldIssue = mode == 'send';
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
      result.add(CreateInvoiceItemParams(
        itemType: InvoiceItemTypes.apiCode(item.type),
        description: description,
        amount: amount,
        quantity: 1,
        sourceCode: item.sourceCode,
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
  });

  final String label;
  final double amount;
  final String? code;

  @override
  List<Object?> get props => [label, amount, code];
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

  final bool isPrimary;

  final TextEditingController descriptionController;
  final TextEditingController amountController;

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
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
