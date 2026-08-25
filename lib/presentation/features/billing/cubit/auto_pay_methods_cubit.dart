import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/add_payment_method_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_payment_settings_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_autopay_status_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/set_autopay_status_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_payment_methods_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_school_forte_config_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/set_primary_payment_method_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/set_autopay_method_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_payment_method_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/update_payment_method_usecase.dart';

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
    required GetPaymentSettingsUseCase getPaymentSettings,
    required GetAutoPayStatusUseCase getStatus,
    required SetAutoPayStatusUseCase setStatus,
    required GetPaymentMethodsUseCase getMethods,
    required AddPaymentMethodUseCase addMethod,
    required SetPrimaryPaymentMethodUseCase setPrimary,
    required SetAutopayMethodUseCase setAutopay,
    required DeletePaymentMethodUseCase deleteMethod,
    required UpdatePaymentMethodUseCase updateMethod,
    required StorageService storage,
  }) : _getForteConfig = getForteConfig,
       _getPaymentSettings = getPaymentSettings,
       _getStatus = getStatus,
       _setStatus = setStatus,
       _getMethods = getMethods,
       _addMethod = addMethod,
       _setPrimary = setPrimary,
       _setAutopay = setAutopay,
       _deleteMethod = deleteMethod,
       _updateMethod = updateMethod,
       _storage = storage,
       super(const AutoPayMethodsState());

  final GetSchoolForteConfigUseCase _getForteConfig;
  final GetPaymentSettingsUseCase _getPaymentSettings;
  final GetAutoPayStatusUseCase _getStatus;
  final SetAutoPayStatusUseCase _setStatus;
  final GetPaymentMethodsUseCase _getMethods;
  final AddPaymentMethodUseCase _addMethod;
  final SetPrimaryPaymentMethodUseCase _setPrimary;
  final SetAutopayMethodUseCase _setAutopay;
  final DeletePaymentMethodUseCase _deleteMethod;
  final UpdatePaymentMethodUseCase _updateMethod;
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
      _schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      _guardianCode = (await _storage.getString(StorageKeys.guardianCode) ?? '')
          .trim();

      final config = await _getForteConfig(
        organizationCode: _organizationCode,
        schoolCode: _schoolCode,
      );

      // School payment settings drive which method types the add-method webview
      // offers. A failure here is non-fatal — leave allowedMethods empty so the
      // webview shows all options rather than blocking the add flow.
      List<String> allowedMethods = const <String>[];
      if (_schoolCode.isNotEmpty) {
        try {
          final settings = await _getPaymentSettings(schoolCode: _schoolCode);
          allowedMethods = settings?.allowedMethods ?? const <String>[];
        } catch (_) {
          allowedMethods = const <String>[];
        }
      }

      AutoPayStatusEntity? status;
      List<PaymentMethodEntity> methods = const [];
      if (hasScope) {
        status = await _getStatus(_scope);
        methods = await _getMethods(_scope);
      }

      if (isClosed) return;
      final selectedCode = _autopayCodeOf(methods) ?? _primaryCodeOf(methods);
      final enabled = status?.autopayEnabled ?? false;
      emit(
        state.copyWith(
          isLoading: false,
          apiLoginId: config?.apiLoginId ?? '',
          maxMethods:
              (config?.maxPaymentMethods != null &&
                  config!.maxPaymentMethods! > 0)
              ? config.maxPaymentMethods!
              : state.maxMethods,
          autopayEnabled: enabled,
          initialAutopayEnabled: enabled,
          methods: methods,
          allowedMethods: allowedMethods,
          selectedMethodCode: () => selectedCode,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
        ),
      );
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
  }) => <String, dynamic>{
    'env': ApiConstants.forteEnv,
    'apiLoginId': state.apiLoginId,
    'title': title ?? 'Add Payment Method',
    if (defaultMethod != null) 'defaultMethod': defaultMethod,
    // Restrict the webview's method dropdown to the school's accepted types
    // (empty → no restriction).
    if (state.allowedMethods.isNotEmpty) 'allowedMethods': state.allowedMethods,
  };

  /// Number of whitespace-separated words in [name] (used to require a first
  /// and last name before sending a holder name to Forte).
  int _nameWordCount(String name) =>
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

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
  /// webview, then refreshes the list. [accountHolder] (uppercase name from the
  /// form) and the [makePrimary]/[makeAutopay] toggles are sent to the backend.
  Future<bool> addPaymentMethodFromToken({
    required String oneTimeToken,
    required PaymentMethodType methodType,
    String? accountHolder,
    String? label,
    bool makePrimary = false,
    bool makeAutopay = false,
  }) async {
    if (state.isSaving) return false;
    if (!hasScope) {
      emit(
        state.copyWith(
          errorMessage: () => 'Account context unavailable. Please try again.',
        ),
      );
      return false;
    }
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      var holderName = (accountHolder ?? '').trim();
      // Forte mandates BOTH a first and last name on the card-holder /
      // account-holder. If the form left it blank or only captured a single
      // word, supplement it with the stored guardian name so the request isn't
      // rejected ("MANDATORY FIELD MISSING: ... name_on_card / account_holder").
      if (_nameWordCount(holderName) < 2) {
        final (firstName, lastName) = await _guardianNames();
        final first = holderName.isNotEmpty ? holderName : firstName;
        holderName = [
          first,
          lastName,
        ].where((p) => p.trim().isNotEmpty).join(' ').trim();
      }

      await _addMethod(
        AddPaymentMethodParams(
          organizationCode: _organizationCode,
          schoolCode: _schoolCode,
          guardianCode: _guardianCode,
          oneTimeToken: oneTimeToken,
          methodType: methodType,
          payMethodHolderName: holderName,
          label: label,
          makePrimary: makePrimary,
          makeAutopay: makeAutopay,
        ),
      );

      final status = await _getStatus(_scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(
        state.copyWith(
          isSaving: false,
          autopayEnabled: status.autopayEnabled,
          initialAutopayEnabled: status.autopayEnabled,
          methods: methods,
          selectedMethodCode: () =>
              _autopayCodeOf(methods) ??
              _primaryCodeOf(methods) ??
              state.selectedMethodCode,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
        ),
      );
      return false;
    }
  }

  /// Edits a saved method's editable fields via `PUT .../payment-methods/{code}`
  /// and, when toggled, marks it primary/auto-pay (separate endpoints). Only the
  /// editable fields per method type are sent (card: name/expiry; echeck:
  /// holder/routing/type/description). Returns true on success.
  Future<bool> updatePaymentMethod({
    required PaymentMethodEntity method,
    // Card fields
    String? nameOnCard,
    int? expireMonth,
    int? expireYear,
    // eCheck fields
    String? accountHolder,
    String? routingNumber,
    String? accountType,
    String? itemDescription,
    // Shared
    String? label,
    bool makePrimary = false,
    bool makeAutopay = false,
  }) async {
    if (state.isSaving) return false;
    if (!hasScope) {
      emit(
        state.copyWith(
          errorMessage: () => 'Account context unavailable. Please try again.',
        ),
      );
      return false;
    }
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      await _updateMethod(
        paymentMethodCode: method.code,
        params: UpdatePaymentMethodParams(
          organizationCode: _organizationCode,
          schoolCode: _schoolCode,
          guardianCode: _guardianCode,
          label: label,
          card: method.isEcheck
              ? null
              : PaymentMethodCardEntity(
                  nameOnCard: (nameOnCard ?? '').trim(),
                  expireMonth: expireMonth ?? method.card?.expireMonth,
                  expireYear: expireYear ?? method.card?.expireYear,
                ),
          echeck: method.isEcheck
              ? PaymentMethodEcheckEntity(
                  accountHolder: (accountHolder ?? '').trim(),
                  routingNumber: (routingNumber ?? method.echeck?.routingNumber)
                      ?.trim(),
                  accountType: accountType ?? method.echeck?.accountType,
                  itemDescription:
                      (itemDescription ?? method.echeck?.itemDescription)
                          ?.trim(),
                )
              : null,
        ),
      );

      // Apply primary / auto-pay flags whenever the toggle is ON at save time.
      // These PUT .../primary and PUT .../autopay endpoints are idempotent (they
      // set THIS method), so re-asserting an already-primary/autopay method is
      // harmless — this guarantees the calls run on every edit where the toggle
      // is enabled, not only on an off→on flip.
      if (makePrimary) {
        await _setPrimary(paymentMethodCode: method.code, scope: _scope);
      }
      if (makeAutopay) {
        await _setAutopay(paymentMethodCode: method.code, scope: _scope);
      }

      final status = await _getStatus(_scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(
        state.copyWith(
          isSaving: false,
          autopayEnabled: status.autopayEnabled,
          initialAutopayEnabled: status.autopayEnabled,
          methods: methods,
          selectedMethodCode: () =>
              _autopayCodeOf(methods) ?? state.selectedMethodCode,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
        ),
      );
      return false;
    }
  }

  /// Commits the pending auto-pay changes (the Save button):
  /// - if the toggle changed → `PUT /autopay/status`;
  /// - if a different auto-pay method was picked (and auto-pay is on)
  ///   → `PUT /payment-methods/{code}/autopay`.
  /// Then refreshes from the server. Returns true on success (or no-op).
  Future<bool> save() async {
    if (state.isSettingPrimary) return false;
    if (!state.autopayChanged && !state.methodChanged) return true;
    if (!hasScope) {
      emit(
        state.copyWith(
          errorMessage: () => 'Account context unavailable. Please try again.',
        ),
      );
      return false;
    }

    emit(state.copyWith(isSettingPrimary: true, errorMessage: () => null));
    try {
      if (state.autopayChanged) {
        await _setStatus(scope: _scope, autopayEnabled: state.autopayEnabled);
      }
      if (state.methodChanged) {
        await _setAutopay(
          paymentMethodCode: state.selectedMethodCode!,
          scope: _scope,
        );
      }

      // Re-sync from the server so UI reflects the committed truth.
      final status = await _getStatus(_scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      emit(
        state.copyWith(
          isSettingPrimary: false,
          autopayEnabled: status.autopayEnabled,
          initialAutopayEnabled: status.autopayEnabled,
          methods: methods,
          selectedMethodCode: () =>
              _autopayCodeOf(methods) ?? state.selectedMethodCode,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSettingPrimary: false,
          errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
        ),
      );
      return false;
    }
  }

  /// Deletes a saved payment method, then refreshes the list. Returns true on
  /// success.
  Future<bool> deletePaymentMethod(String code) async {
    if (state.deletingMethodCode != null) return false;
    if (!hasScope) {
      emit(
        state.copyWith(
          errorMessage: () => 'Account context unavailable. Please try again.',
        ),
      );
      return false;
    }
    emit(
      state.copyWith(deletingMethodCode: () => code, errorMessage: () => null),
    );
    try {
      await _deleteMethod(paymentMethodCode: code, scope: _scope);
      final methods = await _getMethods(_scope);
      if (isClosed) return true;
      // Keep the current selection unless it was the deleted method.
      final nextSelected = state.selectedMethodCode == code
          ? (_autopayCodeOf(methods) ?? _primaryCodeOf(methods))
          : state.selectedMethodCode;
      emit(
        state.copyWith(
          deletingMethodCode: () => null,
          methods: methods,
          selectedMethodCode: () => nextSelected,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          deletingMethodCode: () => null,
          errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
        ),
      );
      return false;
    }
  }

  String? _primaryCodeOf(List<PaymentMethodEntity> methods) {
    for (final m in methods) {
      if (m.primary) return m.code;
    }
    return null;
  }

  String? _autopayCodeOf(List<PaymentMethodEntity> methods) {
    for (final m in methods) {
      if (m.autopay) return m.code;
    }
    return null;
  }
}
