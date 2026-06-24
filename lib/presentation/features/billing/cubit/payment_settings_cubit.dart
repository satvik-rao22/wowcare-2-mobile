import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/payment_settings_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_payment_settings_usecase.dart';

part 'payment_settings_state.dart';

/// Loads the school's payment settings (accepted method types + who pays the
/// convenience fee) for the parent-side payment flows.
class PaymentSettingsCubit extends Cubit<PaymentSettingsState> {
  PaymentSettingsCubit({
    required GetPaymentSettingsUseCase getPaymentSettings,
    required StorageService storage,
  })  : _getPaymentSettings = getPaymentSettings,
        _storage = storage,
        super(const PaymentSettingsState());

  final GetPaymentSettingsUseCase _getPaymentSettings;
  final StorageService _storage;

  /// Fetches settings for [schoolCode] (defaults to the stored school). On
  /// failure the state keeps [PaymentSettingsEntity.fallback] so the UI degrades
  /// permissively rather than blocking payments.
  Future<void> load({String? schoolCode}) async {
    emit(state.copyWith(status: PaymentSettingsStatus.loading));
    try {
      final school = (schoolCode ??
              await _storage.getString(StorageKeys.schoolCode) ??
              '')
          .trim();
      if (school.isEmpty) {
        emit(state.copyWith(status: PaymentSettingsStatus.failure));
        return;
      }
      final settings = await _getPaymentSettings(schoolCode: school);
      if (isClosed) return;
      emit(state.copyWith(
        status: PaymentSettingsStatus.loaded,
        settings: settings ?? PaymentSettingsEntity.fallback,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: PaymentSettingsStatus.failure,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }
}
