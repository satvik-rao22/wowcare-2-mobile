import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import '../../core/config/reg_config.dart';
import '../../core/errors/reg_exceptions.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/usecases/edit_regularization_usecase.dart';
import '../../domain/usecases/get_requests_usecase.dart';
import '../gate/reg_gate_coordinator.dart';
import 'reg_my_requests_state.dart';

/// Drives the staff's "My regularizations" screen.
///
/// There is no cancel action: a wrong request is **edited** while pending
/// (§8.4, §9.4). That is why [edit] exists and `cancel` does not.
class RegMyRequestsCubit extends Cubit<RegMyRequestsState> {
  RegMyRequestsCubit({
    required GetRequestsUseCase getRequests,
    required EditRegularizationUseCase editRequest,
    required RegGateCoordinator gate,
  })  : _getRequests = getRequests,
        _editRequest = editRequest,
        _gate = gate,
        super(const RegMyRequestsState());

  final GetRequestsUseCase _getRequests;
  final EditRegularizationUseCase _editRequest;
  final RegGateCoordinator _gate;

  /// First load: the list and the gate banner together, so the screen settles
  /// once rather than flickering in two stages.
  ///
  /// [keepMessage] is set by actions that reload immediately after reporting
  /// their outcome — otherwise the reload would wipe the very message the user
  /// needs to read.
  Future<void> load({bool keepMessage = false}) async {
    emit(state.copyWith(
      status: RegListStatus.loading,
      message: keepMessage ? null : '',
    ));
    try {
      // Started together, awaited separately: parallel without losing the
      // static types that `Future.wait` on mixed futures would erase.
      final pageFuture =
          _getRequests(page: 0, size: RegConfig.myRequestsPageSize);
      final gateFuture = _gate.peek();
      final page = await pageFuture;
      final gate = await gateFuture;

      emit(state.copyWith(
        status: RegListStatus.loaded,
        requests: page.items,
        gate: gate,
        clearGate: gate == null,
        hasMore: page.hasMore,
        page: 0,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: RegListStatus.error,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _getRequests(
        page: state.page + 1,
        size: RegConfig.myRequestsPageSize,
      );
      emit(state.copyWith(
        requests: [...state.requests, ...next.items],
        page: next.page,
        hasMore: next.hasMore,
        loadingMore: false,
      ));
    } catch (error) {
      // Keep what is already on screen — a failed page 2 must not blank the
      // list the user is reading.
      emit(state.copyWith(
        loadingMore: false,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  /// Opens the gate sheet for the unresolved day (create or edit, chosen from
  /// the gate item) and refreshes on success.
  Future<void> resolveGate() async {
    final gate = state.gate;
    if (gate == null) return;
    final outcome =
        await _gate.resolve(gate, byAdmin: false, mandatory: false);
    if (outcome.isProceed) await load();
  }

  /// §9.4 — revise a pending request in place.
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
      emit(state.copyWith(clearBusy: true, message: 'Request updated'));
      await load(keepMessage: true);
    } on RegAlreadyApprovedException catch (error) {
      // §10.3 — the edit lost a race with an approval. Say so and reload:
      // a silent no-op would leave the user believing their change applied.
      emit(state.copyWith(clearBusy: true, message: error.message));
      await load(keepMessage: true);
    } catch (error) {
      emit(state.copyWith(
        clearBusy: true,
        message: ApiErrorHandler.extractErrorMessage(error),
      ));
    }
  }

  void clearMessage() {
    if (state.message.isEmpty) return;
    emit(state.copyWith(message: ''));
  }
}
