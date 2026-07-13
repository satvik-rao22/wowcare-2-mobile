import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
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
  Future<ReceivePaymentRefundResult> submitPayments({
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
          date: DateTime.now(),
          ownerType: ownerType,
          ownerCode: ownerCode,
          studentCode: entry.key.isNotEmpty ? entry.key : null,
          method: state.selectedPaymentType,
          reference: chequeNumber.trim().isEmpty ? null : chequeNumber.trim(),
          narration: narration,
        ));
      }
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
  }) async {
    if (amount.trim().isEmpty) {
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
      final params = InvoicePaymentParams(
        schoolCode: schoolCode,
        amount: double.tryParse(amount.trim()) ?? 0,
        date: DateTime.now(),
        ownerType: ownerType,
        ownerCode: ownerCode,
        studentCode: studentCode,
        method: state.selectedPaymentType,
        reference: chequeNumber.trim().isEmpty ? null : chequeNumber.trim(),
        narration: narration,
      );

      if (isRefund) {
        await _createRefund(params);
      } else {
        await _createPayment(params);
      }

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
