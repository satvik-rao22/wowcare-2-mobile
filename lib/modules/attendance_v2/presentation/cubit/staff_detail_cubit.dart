import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import '../../core/config/av2_config.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/day_detail.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../../domain/usecases/calculate_overtime_usecase.dart';
import '../../domain/usecases/delete_absence_usecase.dart';
import '../../domain/usecases/delete_session_usecase.dart';
import '../../domain/usecases/edit_absence_usecase.dart';
import '../../domain/usecases/edit_session_usecase.dart';
import '../../domain/usecases/get_day_detail_usecase.dart';
import '../../domain/usecases/get_staff_list_usecase.dart';
import '../../domain/usecases/get_staff_overview_usecase.dart';
import '../controllers/av2_day_filter.dart';
import 'staff_detail_state.dart';

/// Drives the staff attendance & overtime detail screen.
///
/// On entry / date change / pull-to-refresh it runs **calculate → overview**:
/// the backend recomputes overtime into its table, then we read page 0. The
/// overview is paginated (server default 10/page) and filtered server-side
/// (`overtimeOnly` / `absentOnly`); more pages load on scroll. Day sessions
/// load lazily (and are cached) when a row is expanded.
class StaffDetailCubit extends Cubit<StaffDetailState> {
  StaffDetailCubit({
    required this.calculateOvertimeUseCase,
    required this.getStaffOverviewUseCase,
    required this.getDayDetailUseCase,
    required this.editSessionUseCase,
    required this.deleteSessionUseCase,
    required this.editAbsenceUseCase,
    required this.deleteAbsenceUseCase,
    required this.getStaffListUseCase,
  }) : super(const StaffDetailState.initial());

  final CalculateOvertimeUseCase calculateOvertimeUseCase;
  final GetStaffOverviewUseCase getStaffOverviewUseCase;
  final GetDayDetailUseCase getDayDetailUseCase;
  final EditSessionUseCase editSessionUseCase;
  final DeleteSessionUseCase deleteSessionUseCase;
  final EditAbsenceUseCase editAbsenceUseCase;
  final DeleteAbsenceUseCase deleteAbsenceUseCase;
  final GetStaffListUseCase getStaffListUseCase;

  static const int _pageSize = Av2Config.overviewPageSize;

  String _staffCode = '';
  String _staffName = '';
  DateTime? _from;
  DateTime? _to;

  /// Header source — the summary/identity stay range-wide, captured from an
  /// unfiltered ("All") page so filtering the list doesn't skew the hero.
  StaffOvertimeProfile? _header;
  List<AttendanceDay> _days = const [];
  final Map<String, Future<DayDetail>> _detailCache = {};

  /// Full load (entry + date change): shows the loading state, resets to "All".
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
    _header = null;
    _days = const [];
    await _calculate();
    await _loadFirstPage(Av2DayFilter.all, fullLoader: true);
  }

  /// Pull-to-refresh / app-bar refresh: recompute + reload page 0 with the
  /// current filter, without the full-screen loader.
  Future<void> refresh() async {
    if (_from == null || _to == null) return;
    await _calculate();
    await _loadFirstPage(state.filter, fullLoader: false);
  }

  /// Loads the school's staff once (admin only), for the "switch staff" picker.
  Future<void> loadStaffList() async {
    if (state.staff.isNotEmpty) return;
    try {
      final list = await getStaffListUseCase();
      if (isClosed || list.isEmpty) return;
      emit(state.copyWith(staff: list));
    } catch (e) {
      debugPrint('Av2 loadStaffList failed: $e');
    }
  }

  /// User tapped a filter chip — reload page 0 with the new server filter.
  Future<void> setFilter(Av2DayFilter filter) async {
    if (filter == state.filter || _from == null) return;
    await _loadFirstPage(filter, fullLoader: false);
  }

  /// Scroll reached the bottom — fetch and append the next page.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || _from == null) return;
    emit(state.copyWith(loadingMore: true));
    final next = state.page + 1;
    try {
      final page = await _fetch(state.filter, next);
      if (isClosed) return;
      _days = _mergeDays(_days, page.days);
      emit(state.copyWith(
        profile: _merged(),
        page: next,
        hasMore: page.days.length >= _pageSize,
        loadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      debugPrint('Av2 loadMore failed: $e');
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> _calculate() async {
    try {
      await calculateOvertimeUseCase(staffCode: _staffCode, from: _from!, to: _to!);
    } catch (e) {
      debugPrint('Av2 calculate failed (continuing to overview): $e');
    }
  }

  Future<void> _loadFirstPage(
    Av2DayFilter filter, {
    required bool fullLoader,
  }) async {
    if (fullLoader) {
      emit(state.copyWith(
          status: Av2Status.loading, filter: filter, errorMessage: null));
    }
    _detailCache.clear();
    try {
      final page = await _fetch(filter, 0);
      if (isClosed) return;
      _days = page.days;
      if (filter == Av2DayFilter.all || _header == null) _header = page;
      emit(state.copyWith(
        status: Av2Status.loaded,
        profile: _merged(),
        filter: filter,
        page: 0,
        hasMore: page.days.length >= _pageSize,
        loadingMore: false,
        reloadId: state.reloadId + 1,
      ));
    } catch (e) {
      if (isClosed) return;
      // Only take over the screen with an error when there's nothing to show;
      // a failed filter/refresh keeps the existing data visible.
      if (fullLoader || state.profile == null) {
        emit(state.copyWith(
          status: Av2Status.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ));
      } else {
        emit(state.copyWith(status: Av2Status.loaded, loadingMore: false));
      }
    }
  }

  Future<StaffOvertimeProfile> _fetch(Av2DayFilter filter, int page) {
    return getStaffOverviewUseCase(
      staffCode: _staffCode,
      staffName: _staffName,
      from: _from!,
      to: _to!,
      page: page,
      size: _pageSize,
      overtimeOnly: filter == Av2DayFilter.overtime,
      absentOnly: filter == Av2DayFilter.absent,
    );
  }

  /// Merges the header (range-wide summary/identity) with the accumulated days.
  StaffOvertimeProfile _merged() => _header!.copyWith(days: _days);

  /// Appends a new page's days, de-duping by date and keeping newest-first.
  List<AttendanceDay> _mergeDays(
    List<AttendanceDay> current,
    List<AttendanceDay> incoming,
  ) {
    final byKey = <String, AttendanceDay>{};
    for (final d in current) {
      byKey['${d.date.year}-${d.date.month}-${d.date.day}'] = d;
    }
    for (final d in incoming) {
      byKey['${d.date.year}-${d.date.month}-${d.date.day}'] = d;
    }
    return byKey.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Edits a session's sign-in/out (admin), then recomputes + reloads page 0.
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
    await _recalcAndReload();
  }

  /// Deletes a session (admin), then recomputes + reloads page 0.
  Future<void> deleteSession({required String recordCode}) async {
    await deleteSessionUseCase(recordCode: recordCode, staffCode: _staffCode);
    await _recalcAndReload();
  }

  /// Edits an absence (admin), then recomputes + reloads page 0.
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
    await _recalcAndReload();
  }

  /// Deletes an absence (admin), then recomputes + reloads page 0.
  Future<void> deleteAbsence({required String code}) async {
    await deleteAbsenceUseCase(code: code, staffCode: _staffCode);
    await _recalcAndReload();
  }

  Future<void> _recalcAndReload() async {
    await _calculate();
    await _loadFirstPage(state.filter, fullLoader: false);
  }

  /// Lazily loads (and memoizes) the sessions for one day.
  Future<DayDetail> dayDetail(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    return _detailCache.putIfAbsent(
      key,
      () => getDayDetailUseCase(staffCode: _staffCode, date: date),
    );
  }

  /// Gathers everything the CSV export needs for the *full* current-filter
  /// range (not just the loaded pages): all days in one fetch, plus each
  /// attended day's sessions (fetched concurrently in the background; reuses
  /// the expand cache). The caller writes the file + shows the popup.
  Future<Av2ExportData> buildExport() async {
    final filter = state.filter;
    final full = await getStaffOverviewUseCase(
      staffCode: _staffCode,
      staffName: _staffName,
      from: _from!,
      to: _to!,
      page: 0,
      size: Av2Config.profilePageSize,
      overtimeOnly: filter == Av2DayFilter.overtime,
      absentOnly: filter == Av2DayFilter.absent,
    );
    final attended = full.days
        .where((d) => !d.isAbsent && d.status != DayStatus.notMarked)
        .toList();
    final detailByDate = await _gatherDetails(attended);
    return Av2ExportData(
      profile: full,
      detailByDate: detailByDate,
      filter: filter,
    );
  }

  /// Fetches day detail for [days] in small concurrent batches.
  Future<Map<String, DayDetail>> _gatherDetails(List<AttendanceDay> days) async {
    final out = <String, DayDetail>{};
    const batchSize = 6;
    for (var i = 0; i < days.length; i += batchSize) {
      final slice = days.skip(i).take(batchSize).toList();
      final results = await Future.wait(slice.map((d) async {
        try {
          final detail = await dayDetail(d.date);
          return MapEntry('${d.date.year}-${d.date.month}-${d.date.day}', detail);
        } catch (_) {
          return null;
        }
      }));
      for (final e in results) {
        if (e != null) out[e.key] = e.value;
      }
    }
    return out;
  }
}

/// Bundle of everything needed to render the CSV export.
class Av2ExportData {
  const Av2ExportData({
    required this.profile,
    required this.detailByDate,
    required this.filter,
  });

  final StaffOvertimeProfile profile;
  final Map<String, DayDetail> detailByDate;
  final Av2DayFilter filter;
}
