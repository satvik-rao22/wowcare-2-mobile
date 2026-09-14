import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import '../../domain/entities/day_detail.dart';
import '../../domain/usecases/calculate_overtime_usecase.dart';
import '../../domain/usecases/delete_absence_usecase.dart';
import '../../domain/usecases/delete_session_usecase.dart';
import '../../domain/usecases/edit_absence_usecase.dart';
import '../../domain/usecases/edit_session_usecase.dart';
import '../../domain/usecases/get_day_detail_usecase.dart';
import '../../domain/usecases/get_staff_overview_usecase.dart';
import 'staff_detail_state.dart';

/// Drives the staff attendance & overtime detail screen.
///
/// On entry / date change / pull-to-refresh it runs **calculate → overview**:
/// the backend recomputes overtime into its table, then we read it. Day
/// sessions load lazily (and are cached) when a row is expanded.
class StaffDetailCubit extends Cubit<StaffDetailState> {
  StaffDetailCubit({
    required this.calculateOvertimeUseCase,
    required this.getStaffOverviewUseCase,
    required this.getDayDetailUseCase,
    required this.editSessionUseCase,
    required this.deleteSessionUseCase,
    required this.editAbsenceUseCase,
    required this.deleteAbsenceUseCase,
  }) : super(const StaffDetailState.initial());

  final CalculateOvertimeUseCase calculateOvertimeUseCase;
  final GetStaffOverviewUseCase getStaffOverviewUseCase;
  final GetDayDetailUseCase getDayDetailUseCase;
  final EditSessionUseCase editSessionUseCase;
  final DeleteSessionUseCase deleteSessionUseCase;
  final EditAbsenceUseCase editAbsenceUseCase;
  final DeleteAbsenceUseCase deleteAbsenceUseCase;

  String _staffCode = '';
  String _staffName = '';
  DateTime? _from;
  DateTime? _to;
  final Map<String, Future<DayDetail>> _detailCache = {};

  /// Full load (entry + date change): shows the loading state.
  Future<void> load({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) async {
    _staffCode = staffCode;
    _staffName = staffName;
    _from = from;
    _to = to;
    _detailCache.clear();
    emit(state.copyWith(status: Av2Status.loading, errorMessage: null));
    await _calculateThenLoad(emitLoaded: true, emitError: true);
  }

  /// Pull-to-refresh: recompute + reload without flipping to the full-screen
  /// loader; keeps the current data visible if the refresh fails.
  Future<void> refresh() async {
    if (_from == null || _to == null) return;
    await _calculateThenLoad(emitLoaded: true, emitError: state.profile == null);
  }

  Future<void> _calculateThenLoad({
    required bool emitLoaded,
    required bool emitError,
  }) async {
    final from = _from!, to = _to!;
    // Best-effort recompute — never block showing the (possibly stale) profile
    // if calculate hiccups.
    try {
      await calculateOvertimeUseCase(staffCode: _staffCode, from: from, to: to);
    } catch (e) {
      debugPrint('Av2 calculate failed (continuing to overview): $e');
    }
    try {
      _detailCache.clear();
      final profile = await getStaffOverviewUseCase(
        staffCode: _staffCode,
        staffName: _staffName,
        from: from,
        to: to,
      );
      if (isClosed) return;
      if (emitLoaded) {
        emit(state.copyWith(
          status: Av2Status.loaded,
          profile: profile,
          reloadId: state.reloadId + 1,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      if (emitError) {
        emit(state.copyWith(
          status: Av2Status.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ));
      }
    }
  }

  /// Edits a session's sign-in/out (admin), then recomputes + reloads so the
  /// day totals and overtime reflect the change. Rethrows so the caller can
  /// surface the error.
  Future<void> editSession({
    required String recordCode,
    required DateTime signInLocal,
    DateTime? signOutLocal,
  }) async {
    await editSessionUseCase(
      recordCode: recordCode,
      staffCode: _staffCode,
      signInLocal: signInLocal,
      signOutLocal: signOutLocal,
      timeZone: state.profile?.timeZone ?? '',
    );
    await _calculateThenLoad(emitLoaded: true, emitError: false);
  }

  /// Deletes a session (admin), then recomputes + reloads. Rethrows so the
  /// caller can surface the error.
  Future<void> deleteSession({required String recordCode}) async {
    await deleteSessionUseCase(recordCode: recordCode, staffCode: _staffCode);
    await _calculateThenLoad(emitLoaded: true, emitError: false);
  }

  /// Edits an absence (admin), then recomputes + reloads.
  Future<void> editAbsence({
    required String code,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String type,
    required String note,
  }) async {
    await editAbsenceUseCase(
      code: code,
      staffCode: _staffCode,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      type: type,
      note: note,
    );
    await _calculateThenLoad(emitLoaded: true, emitError: false);
  }

  /// Deletes an absence (admin), then recomputes + reloads.
  Future<void> deleteAbsence({required String code}) async {
    await deleteAbsenceUseCase(code: code, staffCode: _staffCode);
    await _calculateThenLoad(emitLoaded: true, emitError: false);
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
