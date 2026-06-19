import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../domain/entities/day_detail.dart';
import '../../domain/usecases/get_day_detail_usecase.dart';
import '../../domain/usecases/get_staff_overview_usecase.dart';
import 'staff_detail_state.dart';

/// Drives the staff attendance & overtime detail screen. Loads the per-day
/// overview up front; loads a day's sessions lazily (and caches them) when a
/// row is expanded.
class StaffDetailCubit extends Cubit<StaffDetailState> {
  StaffDetailCubit({
    required this.getStaffOverviewUseCase,
    required this.getDayDetailUseCase,
  }) : super(const StaffDetailState.initial());

  final GetStaffOverviewUseCase getStaffOverviewUseCase;
  final GetDayDetailUseCase getDayDetailUseCase;

  String _staffCode = '';
  final Map<String, Future<DayDetail>> _detailCache = {};

  Future<void> load({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) async {
    _staffCode = staffCode;
    _detailCache.clear(); // range changed → stale day details
    emit(state.copyWith(status: Av2Status.loading, errorMessage: null));
    try {
      final profile = await getStaffOverviewUseCase(
        staffCode: staffCode,
        staffName: staffName,
        from: from,
        to: to,
      );
      if (isClosed) return;
      emit(state.copyWith(status: Av2Status.loaded, profile: profile));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: Av2Status.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Lazily loads (and memoizes) the sessions for one day.
  Future<DayDetail> dayDetail(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    return _detailCache.putIfAbsent(
      key,
      () => getDayDetailUseCase(staffCode: _staffCode, date: date),
    );
  }
}
