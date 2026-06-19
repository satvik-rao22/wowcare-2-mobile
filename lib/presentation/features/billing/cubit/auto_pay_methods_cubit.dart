import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
import 'package:wowcare/domain/features/billing/usecases/delete_payment_method_usecase.dart';

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
    required DeletePaymentMethodUseCase deleteMethod,
    required StorageService storage,
  })  : _getForteConfig = getForteConfig,
        _getStatus = getStatus,
        _setStatus = setStatus,
        _getMethods = getMethods,
        _addMethod = addMethod,
        _setPrimary = setPrimary,
        _deleteMethod = deleteMethod,
        _storage = storage,
        super(const AutoPayMethodsState());

  final GetSchoolForteConfigUseCase _getForteConfig;
  final GetAutoPayStatusUseCase _getStatus;
  final SetAutoPayStatusUseCase _setStatus;
  final GetPaymentMethodsUseCase _getMethods;
  final AddPaymentMethodUseCase _addMethod;
  final SetPrimaryPaymentMethodUseCase _setPrimary;
  final DeletePaymentMethodUseCase _deleteMethod;
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
      final enabled = status?.autopayEnabled ?? false;
      emit(state.copyWith(
        isLoading: false,
        apiLoginId: config?.apiLoginId ?? '',
        autopayEnabled: enabled,
        initialAutopayEnabled: enabled,
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

  /// Flips the auto-pay toggle locally only. The change is committed to the
  /// backend by [save] (the Save button), not immediately — so the user can
  /// toggle and pick a method, then save once.
  void toggleAutoPay(bool value) {
    emit(state.copyWith(autopayEnabled: value, errorMessage: () => null));
  }

  void selectMethod(String code) {
    emit(state.copyWith(selectedMethodCode: () => code));
  }

  /// Payload for the Forte tokenization webview. [title] sets the header shown
  /// in the HTML; [defaultMethod] preselects the method type (e.g. 'echeck'
  /// for the "Add Bank Account" entry point).
  Map<String, dynamic> buildWebviewPayload({
    String? title,
    String? defaultMethod,
  }) =>
      <String, dynamic>{
        'env': ApiConstants.forteEnv,
        'apiLoginId': state.apiLoginId,
        'title': title ?? 'Add Payment Method',
        if (defaultMethod != null) 'defaultMethod': defaultMethod,
      };

  Future<(String, String)> _guardianNames() async {
    final firstName =
        (await _storage.getString(StorageKeys.guardianProfileFirstName) ?? '')
            .trim();
    final lastName =
        (await _storage.getString(StorageKeys.guardianProfileLastName) ?? '')
            .trim();
    return (
      firstName.isEmpty ? 'Guardian' : firstName,
      lastName.isEmpty ? 'Guardian' : lastName,
    );
  }

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
      final (firstName, lastName) = await _guardianNames();

      await _addMethod(AddPaymentMethodParams(
        organizationCode: _organizationCode,
        schoolCode: _schoolCode,
        guardianCode: _guardianCode,
        oneTimeToken: oneTimeToken,
        methodType: methodType,
        firstName: firstName,
        lastName: lastName,
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

  /// "Edits" a saved method. Forte tokens are immutable (no update endpoint),
  /// so this re-tokenizes: adds the new method, preserves primary if the old
  /// one was primary, then removes the old method. Returns true on success.
  Future<bool> replacePaymentMethod({
    required String oldCode,
    required bool oldWasPrimary,
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
      final (firstName, lastName) = await _guardianNames();

      final created = await _addMethod(AddPaymentMethodParams(
        organizationCode: _organizationCode,
        schoolCode: _schoolCode,
        guardianCode: _guardianCode,
        oneTimeToken: oneTimeToken,
        methodType: methodType,
        firstName: firstName,
        lastName: lastName,
        label: label,
        makePrimary: false,
        makeAutopay: false,
      ));

      // Carry the auto-pay (primary) flag over to the replacement method.
      if (oldWasPrimary && created.code.isNotEmpty) {
        await _setPrimary(paymentMethodCode: created.code, scope: _scope);
      }

      // Remove the method being replaced.
      await _deleteMethod(paymentMethodCode: oldCode, scope: _scope);

      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(state.copyWith(
        isSaving: false,
        methods: methods,
        selectedMethodCode: () =>
            _primaryCodeOf(methods) ?? state.selectedMethodCode,
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

  /// Commits the pending auto-pay changes (the Save button):
  /// - if the toggle changed → `PUT /autopay/status`;
  /// - if a different primary method was picked (and auto-pay is on)
  ///   → `PUT /payment-methods/{code}/primary`.
  /// Then refreshes from the server. Returns true on success (or no-op).
  Future<bool> save() async {
    if (state.isSettingPrimary) return false;
    if (!state.autopayChanged && !state.primaryChanged) return true;
    if (!hasScope) {
      emit(state.copyWith(
        errorMessage: () => 'Account context unavailable. Please try again.',
      ));
      return false;
    }

    emit(state.copyWith(isSettingPrimary: true, errorMessage: () => null));
    try {
      if (state.autopayChanged) {
        await _setStatus(scope: _scope, autopayEnabled: state.autopayEnabled);
      }
      if (state.primaryChanged) {
        await _setPrimary(
          paymentMethodCode: state.selectedMethodCode!,
          scope: _scope,
        );
      }

      // Re-sync from the server so UI reflects the committed truth.
      final status = await _getStatus(_scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(state.copyWith(
        isSettingPrimary: false,
        autopayEnabled: status.autopayEnabled,
        initialAutopayEnabled: status.autopayEnabled,
        methods: methods,
        selectedMethodCode: () =>
            _primaryCodeOf(methods) ?? state.selectedMethodCode,
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

  /// Deletes a saved payment method, then refreshes the list. Returns true on
  /// success.
  Future<bool> deletePaymentMethod(String code) async {
    if (state.deletingMethodCode != null) return false;
    if (!hasScope) {
      emit(state.copyWith(
        errorMessage: () => 'Account context unavailable. Please try again.',
      ));
      return false;
    }
    emit(state.copyWith(
      deletingMethodCode: () => code,
      errorMessage: () => null,
    ));
    try {
      await _deleteMethod(paymentMethodCode: code, scope: _scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      final primaryCode = _primaryCodeOf(methods);
      // Keep the current selection unless it was the deleted method.
      final nextSelected =
          state.selectedMethodCode == code ? primaryCode : state.selectedMethodCode;
      emit(state.copyWith(
        deletingMethodCode: () => null,
        methods: methods,
        selectedMethodCode: () => nextSelected,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        deletingMethodCode: () => null,
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
