import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/add_payment_method_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_autopay_status_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/set_autopay_status_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_payment_methods_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_school_forte_config_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/set_primary_payment_method_usecase.dart';

part 'auto_pay_methods_state.dart';

/// Drives the auto-pay payment-methods screen.
///
/// Flow: [load] fetches the school Forte config (`apiLoginId`), the guardian's
/// auto-pay status, and saved payment methods. Adding a method tokenizes the
/// card/ACH in the Forte webview and the resulting one-time token is POSTed via
/// [addPaymentMethodFromToken]. Changing the auto-pay method calls
/// [saveSelectedAsPrimary] (`PUT .../primary`).
class AutoPayMethodsCubit extends Cubit<AutoPayMethodsState> {
  AutoPayMethodsCubit({
    required GetSchoolForteConfigUseCase getForteConfig,
    required GetAutoPayStatusUseCase getStatus,
    required SetAutoPayStatusUseCase setStatus,
    required GetPaymentMethodsUseCase getMethods,
    required AddPaymentMethodUseCase addMethod,
    required SetPrimaryPaymentMethodUseCase setPrimary,
    required StorageService storage,
  })  : _getForteConfig = getForteConfig,
        _getStatus = getStatus,
        _setStatus = setStatus,
        _getMethods = getMethods,
        _addMethod = addMethod,
        _setPrimary = setPrimary,
        _storage = storage,
        super(const AutoPayMethodsState());

  final GetSchoolForteConfigUseCase _getForteConfig;
  final GetAutoPayStatusUseCase _getStatus;
  final SetAutoPayStatusUseCase _setStatus;
  final GetPaymentMethodsUseCase _getMethods;
  final AddPaymentMethodUseCase _addMethod;
  final SetPrimaryPaymentMethodUseCase _setPrimary;
  final StorageService _storage;

  String _organizationCode = '';
  String _schoolCode = '';
  String _guardianCode = '';

  GuardianScopeParams get _scope => GuardianScopeParams(
        organizationCode: _organizationCode,
        schoolCode: _schoolCode,
        guardianCode: _guardianCode,
      );

  /// True only when org/school/guardian scope is fully resolved.
  bool get hasScope =>
      _organizationCode.isNotEmpty &&
      _schoolCode.isNotEmpty &&
      _guardianCode.isNotEmpty;

  /// Initial load: Forte config → auto-pay status → saved methods.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: () => null));
    try {
      _organizationCode =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      _schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      _guardianCode =
          (await _storage.getString(StorageKeys.guardianCode) ?? '').trim();

      final config = await _getForteConfig(
        organizationCode: _organizationCode,
        schoolCode: _schoolCode,
      );

      AutoPayStatusEntity? status;
      List<PaymentMethodEntity> methods = const [];
      if (hasScope) {
        status = await _getStatus(_scope);
        methods = await _getMethods(_scope);
      }

      if (isClosed) return;
      final primaryCode = _primaryCodeOf(methods);
      emit(state.copyWith(
        isLoading: false,
        apiLoginId: config?.apiLoginId ?? '',
        autopayEnabled: status?.autopayEnabled ?? false,
        methods: methods,
        selectedMethodCode: () => primaryCode,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// Enables/disables auto-pay (`PUT /payment-gateway/autopay/status`).
  ///
  /// Optimistically flips the toggle, then reverts if the call fails so the UI
  /// never shows a state the backend didn't accept.
  Future<void> toggleAutoPay(bool value) async {
    debugPrint('[AUTOPAY][TOGGLE] tapped -> $value '
        '(isToggling=${state.isTogglingAutoPay}, hasScope=$hasScope)');
    if (state.isTogglingAutoPay) return;
    if (!hasScope) {
      emit(state.copyWith(
        errorMessage: () => 'Account context unavailable. Please try again.',
      ));
      return;
    }
    final previous = state.autopayEnabled;
    emit(state.copyWith(
      autopayEnabled: value,
      isTogglingAutoPay: true,
      errorMessage: () => null,
    ));
    try {
      debugPrint('[AUTOPAY][TOGGLE] PUT autopay/status -> $value');
      final status =
          await _setStatus(scope: _scope, autopayEnabled: value);
      if (isClosed) return;
      debugPrint('[AUTOPAY][TOGGLE] PUT ok -> ${status.autopayEnabled}');
      emit(state.copyWith(
        isTogglingAutoPay: false,
        autopayEnabled: status.autopayEnabled,
      ));
    } catch (e) {
      if (isClosed) return;
      debugPrint('[AUTOPAY][TOGGLE] PUT failed: $e');
      emit(state.copyWith(
        isTogglingAutoPay: false,
        autopayEnabled: previous,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  void selectMethod(String code) {
    emit(state.copyWith(selectedMethodCode: () => code));
  }

  /// Payload for the Forte tokenization webview.
  Map<String, dynamic> buildWebviewPayload() => <String, dynamic>{
        'env': ApiConstants.forteEnv,
        'apiLoginId': state.apiLoginId,
        'isAutoPayEnabled': state.autopayEnabled,
      };

  /// Adds a payment method from the Forte one-time token returned by the
  /// webview, then refreshes the list. Returns true on success.
  Future<bool> addPaymentMethodFromToken({
    required String oneTimeToken,
    required PaymentMethodType methodType,
    String? label,
  }) async {
    if (state.isSaving) return false;
    if (!hasScope) {
      emit(state.copyWith(
        errorMessage: () => 'Account context unavailable. Please try again.',
      ));
      return false;
    }
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      final firstName =
          (await _storage.getString(StorageKeys.guardianProfileFirstName) ?? '')
              .trim();
      final lastName =
          (await _storage.getString(StorageKeys.guardianProfileLastName) ?? '')
              .trim();

      await _addMethod(AddPaymentMethodParams(
        organizationCode: _organizationCode,
        schoolCode: _schoolCode,
        guardianCode: _guardianCode,
        oneTimeToken: oneTimeToken,
        methodType: methodType,
        firstName: firstName.isEmpty ? 'Guardian' : firstName,
        lastName: lastName.isEmpty ? 'Guardian' : lastName,
        label: label,
        // Per product requirement: never auto-set primary/autopay on create.
        makePrimary: false,
        makeAutopay: false,
      ));

      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(state.copyWith(
        isSaving: false,
        methods: methods,
        selectedMethodCode: () =>
            state.selectedMethodCode ?? _primaryCodeOf(methods),
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
      return false;
    }
  }

  /// Marks the currently-selected method as primary (the auto-pay method).
  Future<bool> saveSelectedAsPrimary() async {
    final code = state.selectedMethodCode;
    if (code == null || code.isEmpty) return false;
    if (state.isSettingPrimary) return false;
    if (state.primaryMethod?.code == code) return true;

    emit(state.copyWith(isSettingPrimary: true, errorMessage: () => null));
    try {
      await _setPrimary(paymentMethodCode: code, scope: _scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(state.copyWith(
        isSettingPrimary: false,
        methods: methods,
        selectedMethodCode: () => _primaryCodeOf(methods) ?? code,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        isSettingPrimary: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
      return false;
    }
  }

  String? _primaryCodeOf(List<PaymentMethodEntity> methods) {
    for (final m in methods) {
      if (m.primary) return m.code;
    }
    return null;
  }
}
