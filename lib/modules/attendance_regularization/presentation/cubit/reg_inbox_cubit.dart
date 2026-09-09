import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../core/config/reg_config.dart';
import '../../data/reg_context.dart';
import '../../domain/entities/regularization_request.dart';
import '../../domain/usecases/approve_request_usecase.dart';
import '../../domain/usecases/approve_selected_usecase.dart';
import '../../domain/usecases/get_school_requests_usecase.dart';
import '../controllers/reg_inbox_filter.dart';
import 'reg_inbox_state.dart';
import 'reg_my_requests_state.dart' show RegListStatus;

/// Drives the admin's regularization list — the pending queue **and** the
/// approved history, from the one §9.5 endpoint.
class RegInboxCubit extends Cubit<RegInboxState> {
  RegInboxCubit({
    required GetSchoolRequestsUseCase getSchoolRequests,
    required ApproveRequestUseCase approveRequest,
    required ApproveSelectedUseCase approveSelected,
    required RegContext context,
  })  : _getSchoolRequests = getSchoolRequests,
        _approveRequest = approveRequest,
        _approveSelected = approveSelected,
        _context = context,
        super(const RegInboxState());

  final GetSchoolRequestsUseCase _getSchoolRequests;
  final ApproveRequestUseCase _approveRequest;
  final ApproveSelectedUseCase _approveSelected;
  final RegContext _context;

  String _schoolCode = '';

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode.isNotEmpty) return _schoolCode;
    _schoolCode = await _context.schoolCode();
    return _schoolCode;
  }

  /// [keepMessage] is set by actions that reload right after reporting their
  /// outcome, so the reload does not wipe the message being shown.
  Future<void> load({bool keepMessage = false}) async {
    emit(state.copyWith(
      status: RegListStatus.loading,
      message: keepMessage ? null : '',
    ));
    try {
      final schoolCode = await _resolveSchoolCode();
      if (schoolCode.isEmpty) {
        emit(state.copyWith(
          status: RegListStatus.error,
          message: 'No school selected.',
        ));
        return;
      }
      final page = await _getSchoolRequests(
        schoolCode: schoolCode,
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
      final next = await _getSchoolRequests(
        schoolCode: await _resolveSchoolCode(),
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
    // Guard at the cubit as well as the widget: only a pending row on the
    // pending tab is ever selectable.
    if (!state.filter.supportsSelection) return;
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
    if (!state.filter.supportsSelection) return;
    final selectable =
        state.selectableRequests.map((r) => r.code).toSet();
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

  void clearMessage() {
    if (state.message.isEmpty) return;
    emit(state.copyWith(message: ''));
  }
}
