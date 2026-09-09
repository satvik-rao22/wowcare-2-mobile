import 'package:bloc/bloc.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/idempotency_key.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_payment_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/create_refund_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_ledger_usecase.dart';

part 'receive_payment_refund_state.dart';

/// A payable person inside the Receive Payment screen — a single student or
/// each sibling in a family, with their current outstanding balance.
class PayableStudent extends Equatable {
  const PayableStudent({
    required this.code,
    required this.name,
    required this.outstanding,
  });

  final String code;
  final String name;
  final double outstanding;

  @override
  List<Object?> get props => [code, name, outstanding];
}

/// Result of a receive-payment / issue-refund submission so the view can show
/// the right snackbar.
enum ReceivePaymentRefundResult {
  missingAmount,
  missingType,
  missingCheque,
  failure,
  success,
}

/// Owns the receive-payment / issue-refund form's non-text state and submits
/// the payment (`/invoices/payments`) or refund (`/invoices/refunds`). The view
/// keeps its text controllers and passes their values into [validateAndSave].
class ReceivePaymentRefundCubit extends Cubit<ReceivePaymentRefundState> {
  ReceivePaymentRefundCubit({
    required CreatePaymentUseCase createPayment,
    required CreateRefundUseCase createRefund,
    required GetFamilyLedgerUseCase getFamilyLedger,
    required StorageService storage,
  })  : _createPayment = createPayment,
        _createRefund = createRefund,
        _getFamilyLedger = getFamilyLedger,
        _storage = storage,
        super(const ReceivePaymentRefundState.initial());

  final CreatePaymentUseCase _createPayment;
  final CreateRefundUseCase _createRefund;
  final GetFamilyLedgerUseCase _getFamilyLedger;
  final StorageService _storage;

  /// Single-flight guard: coalesces a rapid double-tap (or a re-fired callback /
  /// rebuild) onto the ONE in-flight submission instead of firing a second
  /// payment/refund. Cleared when the submission completes.
  Future<ReceivePaymentRefundResult>? _inFlightSubmission;

  /// Stable per-operation `Idempotency-Key`s, keyed by a logical operation id
  /// (e.g. `pay:<studentCode>`). Minted once and REUSED across retries of the
  /// same operation so the backend dedupes a duplicate charge/refund; cleared
  /// only after a successful submission so a genuinely new payment gets a fresh
  /// key. This is the financial idempotency the UI `isSubmitting` bool can't give.
  final Map<String, String> _idempotencyKeys = <String, String>{};

  String _idempotencyKeyFor(String opId) =>
      _idempotencyKeys.putIfAbsent(opId, IdempotencyKey.generate);

  Future<ReceivePaymentRefundResult> _singleFlight(
    Future<ReceivePaymentRefundResult> Function() op,
  ) {
    final existing = _inFlightSubmission;
    if (existing != null) return existing;
    final future = op();
    _inFlightSubmission = future;
    future.whenComplete(() {
      _inFlightSubmission = null;
    }).ignore();
    return future;
  }

  /// Loads the list of payable students for the Custom Amount section. For a
  /// family (`ownerType == FAMILY` + a code) this is every sibling with their
  /// outstanding balance; otherwise it's a single fallback row built from the
  /// transaction being paid.
  Future<void> loadPayableStudents({
    required String? ownerType,
    required String? ownerCode,
    required String fallbackName,
    String? fallbackStudentCode,
    double fallbackOutstanding = 0,
  }) async {
    final List<PayableStudent> single = <PayableStudent>[
      PayableStudent(
        code: (fallbackStudentCode ?? '').trim(),
        name: fallbackName,
        outstanding: fallbackOutstanding,
      ),
    ];
    final bool isFamily = (ownerType ?? '').toUpperCase() == 'FAMILY' &&
        (ownerCode ?? '').trim().isNotEmpty;
    if (!isFamily) {
      emit(state.copyWith(payableStudents: single, isLoadingStudents: false));
      return;
    }
    emit(state.copyWith(isLoadingStudents: true));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final ledger = await _getFamilyLedger(
        organizationCode: org,
        school: school,
        ownerCode: ownerCode!.trim(),
        ownerType: 'FAMILY',
      );
      if (isClosed) return;
      final students = ledger.students
          .map((s) => PayableStudent(
                code: s.code,
                name: s.fullName,
                outstanding: s.outstanding,
              ))
          .toList();
      emit(state.copyWith(
        payableStudents: students.isNotEmpty ? students : single,
        isLoadingStudents: false,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(payableStudents: single, isLoadingStudents: false));
    }
  }

  /// Submits one payment per sibling for the entries in [amountsByCode] whose
  /// amount is greater than zero. Stops and reports failure on the first error.
  /// Single-flighted so a double-tap can't fire two submissions.
  Future<ReceivePaymentRefundResult> submitPayments({
    required Map<String, double> amountsByCode,
    required String chequeNumber,
    String? ownerType,
    String? ownerCode,
    String? narration,
  }) =>
      _singleFlight(() => _submitPaymentsImpl(
            amountsByCode: amountsByCode,
            chequeNumber: chequeNumber,
            ownerType: ownerType,
            ownerCode: ownerCode,
            narration: narration,
          ));

  Future<ReceivePaymentRefundResult> _submitPaymentsImpl({
    required Map<String, double> amountsByCode,
    required String chequeNumber,
    String? ownerType,
    String? ownerCode,
    String? narration,
  }) async {
    final Map<String, double> payable = <String, double>{
      for (final entry in amountsByCode.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
    if (payable.isEmpty) {
      emit(state.copyWith(amountError: true));
      return ReceivePaymentRefundResult.missingAmount;
    }
    if (state.selectedPaymentType == null) {
      return ReceivePaymentRefundResult.missingType;
    }
    if (state.selectedPaymentType == 'Cheque' && chequeNumber.trim().isEmpty) {
      return ReceivePaymentRefundResult.missingCheque;
    }

    emit(state.copyWith(
        amountError: false, isSubmitting: true, errorMessage: null));
    try {
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      for (final entry in payable.entries) {
        await _createPayment(InvoicePaymentParams(
          schoolCode: schoolCode,
          amount: entry.value,
          date: AppTime.now(),
          ownerType: ownerType,
          ownerCode: ownerCode,
          studentCode: entry.key.isNotEmpty ? entry.key : null,
          method: state.selectedPaymentType,
          reference: chequeNumber.trim().isEmpty ? null : chequeNumber.trim(),
          narration: narration,
          // Stable per-sibling key: a retry after a mid-loop failure re-sends the
          // already-charged siblings with the SAME key, so the backend dedupes
          // them instead of double-charging.
          idempotencyKey: _idempotencyKeyFor('pay:${entry.key}'),
        ));
      }
      // Whole submission succeeded — rotate keys so a genuinely new payment
      // later gets fresh ones.
      _idempotencyKeys.clear();
      if (isClosed) return ReceivePaymentRefundResult.success;
      emit(state.copyWith(isSubmitting: false));
      return ReceivePaymentRefundResult.success;
    } catch (e) {
      if (isClosed) return ReceivePaymentRefundResult.failure;
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return ReceivePaymentRefundResult.failure;
    }
  }

  void setPaymentType(String? value) {
    emit(state.copyWith(selectedPaymentType: () => value));
  }

  void setSendEmailNotification(bool value) {
    emit(state.copyWith(sendEmailNotification: value));
  }

  void clearAmountError() {
    if (!state.amountError) return;
    emit(state.copyWith(amountError: false));
  }

  Future<ReceivePaymentRefundResult> validateAndSave({
    required String amount,
    required String chequeNumber,
    required bool isRefund,
    String? ownerType,
    String? ownerCode,
    String? studentCode,
    String? narration,
  }) =>
      _singleFlight(() => _validateAndSaveImpl(
            amount: amount,
            chequeNumber: chequeNumber,
            isRefund: isRefund,
            ownerType: ownerType,
            ownerCode: ownerCode,
            studentCode: studentCode,
            narration: narration,
          ));

  Future<ReceivePaymentRefundResult> _validateAndSaveImpl({
    required String amount,
    required String chequeNumber,
    required bool isRefund,
    String? ownerType,
    String? ownerCode,
    String? studentCode,
    String? narration,
  }) async {
    // Reject an empty OR non-numeric OR non-positive amount rather than
    // silently charging/refunding 0 (BILL-MONEY-05): a malformed amount string
    // must never collapse to a 0 financial transaction.
    final parsedAmount = double.tryParse(amount.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      emit(state.copyWith(amountError: true));
      return ReceivePaymentRefundResult.missingAmount;
    }
    if (state.selectedPaymentType == null) {
      return ReceivePaymentRefundResult.missingType;
    }
    if (state.selectedPaymentType == 'Cheque' && chequeNumber.trim().isEmpty) {
      return ReceivePaymentRefundResult.missingCheque;
    }

    emit(state.copyWith(
        amountError: false, isSubmitting: true, errorMessage: null));
    try {
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final opId =
          '${isRefund ? 'refund' : 'pay'}:${studentCode ?? ownerCode ?? ''}';
      final params = InvoicePaymentParams(
        schoolCode: schoolCode,
        amount: parsedAmount,
        date: AppTime.now(),
        ownerType: ownerType,
        ownerCode: ownerCode,
        studentCode: studentCode,
        method: state.selectedPaymentType,
        reference: chequeNumber.trim().isEmpty ? null : chequeNumber.trim(),
        narration: narration,
        idempotencyKey: _idempotencyKeyFor(opId),
      );

      if (isRefund) {
        await _createRefund(params);
      } else {
        await _createPayment(params);
      }

      _idempotencyKeys.clear();
      if (isClosed) return ReceivePaymentRefundResult.success;
      emit(state.copyWith(isSubmitting: false));
      return ReceivePaymentRefundResult.success;
    } catch (e) {
      if (isClosed) return ReceivePaymentRefundResult.failure;
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return ReceivePaymentRefundResult.failure;
    }
  }
}
