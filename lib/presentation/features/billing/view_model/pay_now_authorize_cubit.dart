import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/guardian_pay_usecase.dart';

part 'pay_now_authorize_state.dart';

/// One family's slice of a Pay Now payment. Each family is a separate payment
/// owner, so it's charged with its own [idempotencyKey] (minted on step 2 and
/// reused on retries so the backend dedupes double-submits).
class PayNowCharge extends Equatable {
  const PayNowCharge({
    required this.ownerType,
    required this.ownerCode,
    required this.amount,
    required this.idempotencyKey,
    this.familyName = '',
    this.allocations = const <PaymentAllocationEntity>[],
  });

  final String ownerType;
  final String ownerCode;
  final double amount;
  final String idempotencyKey;
  final String familyName;

  /// Per-child split of [amount] (empty = family-wide oldest-invoice-first).
  final List<PaymentAllocationEntity> allocations;

  @override
  List<Object?> get props =>
      [ownerType, ownerCode, amount, idempotencyKey, familyName, allocations];
}

/// Submits the Pay Now charge (`POST /payment-gateway/guardian/pay`). The
/// [idempotencyKey] is created once on the method-selection step and passed in,
/// so retries of a failed charge reuse the SAME key and the backend dedupes
/// double-submits / network retries into a single payment.
class PayNowAuthorizeCubit extends Cubit<PayNowAuthorizeState> {
  PayNowAuthorizeCubit({
    required GuardianPayUseCase guardianPay,
    required StorageService storage,
  })  : _guardianPay = guardianPay,
        _storage = storage,
        super(const PayNowAuthorizeState());

  final GuardianPayUseCase _guardianPay;
  final StorageService _storage;

  /// Charges one payment per family (only those with amount > 0). Stops and
  /// reports failure on the first error; each family reuses its own
  /// idempotency key so a retry can't double-charge the families that already
  /// succeeded.
  Future<bool> payMany({
    required List<PayNowCharge> charges,
    required String paymentMethodCode,
    required String payMethodHolderName,
  }) async {
    if (state.isSubmitting) return false; // Guard against double-tap.
    final payable = charges.where((c) => c.amount > 0).toList();
    if (payable.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Enter an amount to pay.'));
      return false;
    }
    emit(state.copyWith(isSubmitting: true, errorMessage: () => null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final guardian =
          (await _storage.getString(StorageKeys.guardianCode) ?? '').trim();

      GuardianPayResultEntity? last;
      for (final c in payable) {
        last = await _guardianPay(GuardianPayParams(
          organizationCode: org,
          schoolCode: school,
          guardianCode: guardian,
          ownerType: c.ownerType,
          ownerCode: c.ownerCode,
          paymentMethodCode: paymentMethodCode,
          amount: c.amount,
          idempotencyKey: c.idempotencyKey,
          payMethodHolderName: payMethodHolderName,
          allocations: c.allocations,
        ));
      }
      if (isClosed) return true;
      emit(state.copyWith(isSubmitting: false, result: () => last));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
      return false;
    }
  }
}
