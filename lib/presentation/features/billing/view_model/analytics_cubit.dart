import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/billing_school_time.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_analytics_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_analytics_usecase.dart';

part 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required GetInvoiceAnalyticsUseCase getAnalytics,
    required StorageService storage,
  })  : _getAnalytics = getAnalytics,
        _storage = storage,
        super(const AnalyticsState.initial());

  final GetInvoiceAnalyticsUseCase _getAnalytics;
  final StorageService _storage;

  Future<void> load({int? year, bool background = false}) async {
    // A background refresh (pull-to-refresh) keeps the current chart on screen
    // instead of flashing a shimmer, and refetches silently.
    final keepVisible = background && state.analytics != null;
    emit(state.copyWith(isLoading: !keepVisible, errorMessage: () => null));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      // Default to the current SCHOOL-calendar year when none is specified.
      final effectiveYear =
          year ?? state.selectedYear ?? billingSchoolCurrentYear();
      final analytics = await _getAnalytics(
        organizationCode: org,
        school: school,
        year: effectiveYear,
      );
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        analytics: () => analytics,
      ));
    } catch (e) {
      if (isClosed) return;
      // Keep the existing chart on a failed background refresh.
      if (keepVisible) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  Future<void> setYear(int? year) async {
    emit(state.copyWith(selectedYear: () => year));
    await load(year: year);
  }
}
