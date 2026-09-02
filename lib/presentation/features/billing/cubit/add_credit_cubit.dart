import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_credit_usecase.dart';

part 'add_credit_state.dart';

enum AddCreditResult { missingAmount, failure, success }

class AddCreditCubit extends Cubit<AddCreditState> {
  AddCreditCubit({
    required CreateCreditUseCase createCredit,
    required StorageService storage,
  })  : _createCredit = createCredit,
        _storage = storage,
        super(const AddCreditState());

  final CreateCreditUseCase _createCredit;
  final StorageService _storage;

  /// Single-flight guard + stable idempotency key for the credit POST — see
  /// ReceivePaymentRefundCubit. Prevents a double-tap or a 401-replay from
  /// posting a duplicate credit.
  Future<AddCreditResult>? _inFlight;
  String? _idempotencyKey;

  void clearAmountError() {
    if (state.amountError) emit(state.copyWith(amountError: false));
  }

  /// Validates the amount then posts the credit (`POST /invoices/credits`).
  /// Single-flighted so a double-tap can't post two credits.
  Future<AddCreditResult> submit({
    required String amount,
    String? reason,
    String? description,
    String? ownerType,
    String? ownerCode,
    String? studentCode,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _submitImpl(
      amount: amount,
      reason: reason,
      description: description,
      ownerType: ownerType,
      ownerCode: ownerCode,
      studentCode: studentCode,
    );
    _inFlight = future;
    future.whenComplete(() {
      _inFlight = null;
    }).ignore();
    return future;
  }

  Future<AddCreditResult> _submitImpl({
    required String amount,
    String? reason,
    String? description,
    String? ownerType,
    String? ownerCode,
    String? studentCode,
  }) async {
    final parsed = double.tryParse(amount.trim()) ?? 0;
    if (amount.trim().isEmpty || parsed <= 0) {
      emit(state.copyWith(amountError: true));
      return AddCreditResult.missingAmount;
    }

    emit(state.copyWith(
        amountError: false, isSubmitting: true, errorMessage: null));
    try {
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      // Mint once, reuse across retries; rotated after success.
      final key = _idempotencyKey ??= IdempotencyKey.generate();
      await _createCredit(CreateCreditParams(
        schoolCode: schoolCode,
        amount: parsed,
        ownerType: ownerType,
        ownerCode: ownerCode,
        studentCode: studentCode,
        reason: reason,
        description: description,
        idempotencyKey: key,
      ));
      _idempotencyKey = null;
      if (isClosed) return AddCreditResult.success;
      emit(state.copyWith(isSubmitting: false));
      return AddCreditResult.success;
    } catch (e) {
      if (isClosed) return AddCreditResult.failure;
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return AddCreditResult.failure;
    }
  }
}
