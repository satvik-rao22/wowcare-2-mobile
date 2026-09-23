import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/attendance_events.dart';

import '../../core/config/reg_config.dart';
import '../../core/errors/reg_exceptions.dart';
import '../../data/reg_context.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/entities/regularization_request.dart';
import '../../domain/usecases/approve_request_usecase.dart';
import '../../domain/usecases/approve_selected_usecase.dart';
import '../../domain/usecases/edit_regularization_usecase.dart';
import '../../domain/usecases/get_requests_usecase.dart';
import '../controllers/reg_inbox_filter.dart';
import 'reg_inbox_state.dart';

/// Drives a regularization list — the pending queue **and** the approved
/// history, from the one §9.5 endpoint.
///
/// [scopeTo] is what makes it serve both the school-wide admin inbox and one
/// staff member's profile list, so there is a single set of list, paging,
/// selection and approve rules rather than one per screen.
class RegInboxCubit extends Cubit<RegInboxState> {
  RegInboxCubit({
    required GetRequestsUseCase getRequests,
    required ApproveRequestUseCase approveRequest,
    required ApproveSelectedUseCase approveSelected,
    required EditRegularizationUseCase editRequest,
    required RegContext context,
  })  : _getRequests = getRequests,
        _approveRequest = approveRequest,
        _approveSelected = approveSelected,
        _editRequest = editRequest,
        _context = context,
        super(const RegInboxState());

  final GetRequestsUseCase _getRequests;
  final ApproveRequestUseCase _approveRequest;
  final ApproveSelectedUseCase _approveSelected;
  final EditRegularizationUseCase _editRequest;
  final RegContext _context;

  /// Whose requests to list. Empty is the whole school (the admin inbox); a
  /// staff code narrows it to one person's profile.
  String _staffCode = '';

  /// Narrows the list to one staff member, and opens on [filter].
  void scopeTo(String staffCode, {RegInboxFilter filter = RegInboxFilter.all}) {
    _staffCode = staffCode.trim();
    emit(state.copyWith(filter: filter));
  }

  /// [keepMessage] is set by actions that reload right after reporting their
  /// outcome, so the reload does not wipe the message being shown.
  Future<void> load({bool keepMessage = false}) async {
    emit(state.copyWith(
      status: RegListStatus.loading,
      message: keepMessage ? null : '',
    ));
    try {
      final user = await _context.currentUserCode();
      final page = await _getRequests(
        staffCode: _staffCode.isEmpty ? null : _staffCode,
        status: state.filter.status,
        sort: state.filter.sort,
        page: 0,
        size: RegConfig.inboxPageSize,
      );
      emit(state.copyWith(
        status: RegListStatus.loaded,
        requests: page.items,
        hasMore: page.hasMore,
        page: 0,
        selected: const {},
        currentUserCode: user,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: RegListStatus.error,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  Future<void> refresh() => load();

  /// Switches tab.
  ///
  /// Refetches from page 0 rather than filtering in memory: the tab changes
  /// both `status` **and** `sort` (§9.5), so the loaded page is not a prefix
  /// of the new result set — keeping it would show rows in the wrong order
  /// under the wrong heading. The selection is dropped for the same reason.
  Future<void> setFilter(RegInboxFilter filter) async {
    if (filter == state.filter) return;
    emit(state.copyWith(
      filter: filter,
      selected: const {},
      requests: const [],
      page: 0,
      hasMore: false,
    ));
    await load();
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _getRequests(
        staffCode: _staffCode.isEmpty ? null : _staffCode,
        status: state.filter.status,
        sort: state.filter.sort,
        page: state.page + 1,
        size: RegConfig.inboxPageSize,
      );
      emit(state.copyWith(
        requests: [...state.requests, ...next.items],
        page: next.page,
        hasMore: next.hasMore,
        loadingMore: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        loadingMore: false,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  // ——————————————————————————————————————————————————————————————
  // Selection
  // ——————————————————————————————————————————————————————————————

  void toggleSelect(String code, bool on) {
    // Guard at the cubit as well as the widget: only a pending row is ever
    // selectable.
    final selectable = state.selectableRequests.map((r) => r.code).toSet();
    if (!selectable.contains(code)) return;

    final next = Set<String>.from(state.selected);
    if (on) {
      next.add(code);
    } else {
      next.remove(code);
    }
    emit(state.copyWith(selected: next));
  }

  void toggleSelectAll() {
    final selectable = state.selectableRequests.map((r) => r.code).toSet();
    if (selectable.isEmpty) return;
    emit(state.copyWith(
      selected: state.selected.length == selectable.length
          ? const {}
          : selectable,
    ));
  }

  void clearSelection() => emit(state.copyWith(selected: const {}));

  // ——————————————————————————————————————————————————————————————
  // Approve
  // ——————————————————————————————————————————————————————————————

  /// §9.6 — approve one request, optionally with a modified time and note.
  Future<void> approve(
    String code, {
    DateTime? signOutLocal,
    String note = '',
  }) async {
    emit(state.copyWith(busy: true, message: ''));
    try {
      final updated = await _approveRequest(
        code,
        signOutLocal: signOutLocal,
        note: note,
      );
      // Approval writes signed_out_at onto the attendance row and recomputes
      // the day, so anything showing attendance needs to re-read it.
      AttendanceEvents.notifyChanged();
      emit(state.copyWith(
        busy: false,
        requests: _applyDecision(updated),
        selected: Set<String>.from(state.selected)..remove(code),
        message: updated.wasModified
            ? 'Approved with your adjusted time'
            : 'Approved',
      ));
    } catch (error) {
      emit(state.copyWith(
        busy: false,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  /// §9.7 — approve the ticked set, each as submitted.
  Future<void> approveSelected() async {
    if (state.selected.isEmpty) return;
    final codes = state.selected.toList(growable: false);
    emit(state.copyWith(busy: true, message: ''));
    try {
      final result = await _approveSelected(codes);

      // Only the codes that actually went through leave the queue. Skipped
      // items stay put with the reason, so the admin can see what another
      // admin had already handled (§9.7).
      final approvedCodes =
          codes.where((c) => !result.skippedKeys.contains(c)).toSet();

      if (result.applied > 0) AttendanceEvents.notifyChanged();
      emit(state.copyWith(
        busy: false,
        requests: _removeOrMark(approvedCodes),
        selected: const {},
        message: result.summary,
      ));
    } catch (error) {
      emit(state.copyWith(
        busy: false,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  /// Places an approved request back into the list, or drops it.
  ///
  /// On the **Pending** tab the row has left the queue, so it goes. On
  /// **Approved** / **All** it belongs there and must stay, re-rendered with
  /// its new status — removing it would make a history view lie about its own
  /// contents.
  List<RegularizationRequest> _applyDecision(RegularizationRequest updated) {
    if (state.filter == RegInboxFilter.pending) {
      return state.requests
          .where((r) => r.code != updated.code)
          .toList(growable: false);
    }
    return state.requests
        .map((r) => r.code == updated.code ? updated : r)
        .toList(growable: false);
  }

  /// Bulk equivalent of [_applyDecision]. The batch response carries only
  /// counts, not rows, so on a history tab the affected rows are refetched
  /// rather than guessed.
  List<RegularizationRequest> _removeOrMark(Set<String> approvedCodes) {
    if (state.filter == RegInboxFilter.pending) {
      return state.requests
          .where((r) => !approvedCodes.contains(r.code))
          .toList(growable: false);
    }
    // Fire-and-forget refresh so the history shows the real approver and time
    // rather than a locally-invented copy. The summary message survives it.
    Future.microtask(() => load(keepMessage: true));
    return state.requests;
  }

  /// The raiser revising their own pending request.
  Future<void> edit(
    String code, {
    required DateTime attendanceDate,
    DateTime? signOutLocal,
    String? reason,
  }) async {
    emit(state.copyWith(busyCode: code, message: ''));
    try {
      await _editRequest(RegEditInput(
        code: code,
        attendanceDate: attendanceDate,
        signOutLocal: signOutLocal,
        reason: reason,
      ));
      emit(state.copyWith(clearBusyCode: true, message: 'Request updated'));
      await load(keepMessage: true);
    } on RegAlreadyApprovedException catch (error) {
      // An edit that lost to an approval must say so — a silent no-op would
      // leave the user believing their change applied.
      emit(state.copyWith(clearBusyCode: true, message: error.message));
      await load(keepMessage: true);
    } catch (error) {
      emit(state.copyWith(
        clearBusyCode: true,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  void clearMessage() {
    if (state.message.isEmpty) return;
    emit(state.copyWith(message: ''));
  }
}
