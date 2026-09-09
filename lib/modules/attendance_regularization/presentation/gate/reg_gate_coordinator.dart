import 'package:flutter/material.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';

import '../../core/errors/reg_exceptions.dart';
import '../../data/mappers/reg_mappers.dart';
import '../../data/reg_context.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/entities/reg_raise_input.dart';
import '../../domain/entities/regularization_request.dart';
import '../../domain/usecases/edit_regularization_usecase.dart';
import '../../domain/usecases/get_open_session_usecase.dart';
import '../../domain/usecases/get_open_sessions_batch_usecase.dart';
import '../../domain/usecases/raise_regularization_batch_usecase.dart';
import '../../domain/usecases/raise_regularization_usecase.dart';
import '../widgets/reg_bulk_signin_gate_sheet.dart';
import '../widgets/reg_resolve_sheet.dart';
import 'reg_gate_outcome.dart';
import 'reg_sign_in_gate.dart';

/// Every gate decision in the app, in one class.
///
/// The sign-in interceptor calls it, the dashboard banner calls it, and the
/// staff list calls it. Nothing else needs to — which is what keeps the rule
/// "you cannot sign in until yesterday is closed" in a single place instead of
/// spread across 11 sign-in call sites.
///
/// It shows UI without being a widget, via [CoreUtils.rootNavigatorKey]. That
/// is already how this app handles session expiry, school switching and
/// geofence prompts, so it is an established pattern here rather than a new
/// one — and it is what lets the gate live at the network boundary, where no
/// caller can forget to invoke it.
class RegGateCoordinator implements RegSignInGate {
  RegGateCoordinator({
    required GetOpenSessionUseCase getOpenSession,
    required GetOpenSessionsBatchUseCase getOpenSessionsBatch,
    required RaiseRegularizationUseCase raise,
    required RaiseRegularizationBatchUseCase raiseBatch,
    required EditRegularizationUseCase edit,
    required RegContext context,
  })  : _getOpenSession = getOpenSession,
        _getOpenSessionsBatch = getOpenSessionsBatch,
        _raise = raise,
        _raiseBatch = raiseBatch,
        _edit = edit,
        _context = context;

  final GetOpenSessionUseCase _getOpenSession;
  final GetOpenSessionsBatchUseCase _getOpenSessionsBatch;
  final RaiseRegularizationUseCase _raise;
  final RaiseRegularizationBatchUseCase _raiseBatch;
  final EditRegularizationUseCase _edit;
  final RegContext _context;

  /// Guards against two gates racing — e.g. a dashboard auto-open landing at
  /// the same moment as a tapped sign-in. The second caller proceeds rather
  /// than stacking a second mandatory sheet on top of the first.
  bool _sheetOpen = false;

  BuildContext? get _ctx => CoreUtils.rootNavigatorKey.currentContext;

  // ——————————————————————————————————————————————————————————————
  // Read-only check — no UI
  // ——————————————————————————————————————————————————————————————

  /// The staff's unresolved day, or `null`. Never shows anything.
  ///
  /// Used by the dashboard to decide whether to render a banner, and by the
  /// staff list for its needs-attention strip. Failures are swallowed on
  /// purpose: a dashboard card must not break the dashboard.
  Future<MissedSignout?> peek(String staffCode) async {
    if (staffCode.trim().isEmpty) return null;
    try {
      return await _getOpenSession(staffCode.trim());
    } catch (error) {
      AppLogger.w('[Reg] peek failed: $error');
      return null;
    }
  }

  // ——————————————————————————————————————————————————————————————
  // Single-staff gate (§9.1 → §9.2)
  // ——————————————————————————————————————————————————————————————

  /// Blocks a single sign-in until the staff's unresolved day is raised.
  ///
  /// [byAdmin] comes from the sign-in URL, not a client flag, so it cannot
  /// disagree with the role the server infers from the token — which is what
  /// decides whether §8.2b auto-approves.
  @override
  Future<RegGateOutcome> guardSingle(
    String staffCode, {
    required bool byAdmin,
    String staffName = '',
  }) async {
    final open = await peek(staffCode);

    // §8.3 — nothing open, or a request already exists. Either way sign-in is
    // allowed; a staff who already raised must never be re-prompted.
    if (open == null || !open.blocksSignIn) return RegGateOutcome.proceed;

    return resolve(
      open,
      byAdmin: byAdmin,
      staffName: staffName.isNotEmpty ? staffName : open.staffName,
      mandatory: true,
      fallbackStaffCode: staffCode,
    );
  }

  /// Opens the sheet for a known unresolved day and submits the result.
  ///
  /// Chooses create vs edit from [MissedSignout.resolvesByEdit], so re-opening
  /// the sheet on a day that already has a request PATCHes (§9.4) instead of
  /// attempting a duplicate POST.
  Future<RegGateOutcome> resolve(
    MissedSignout item, {
    required bool byAdmin,
    String staffName = '',
    bool mandatory = true,
    String fallbackStaffCode = '',
    DateTime? initialSignOutLocal,
    String initialReason = '',
  }) async {
    final context = _ctx;
    if (context == null || !context.mounted) {
      // No UI to show the sheet in (backgrounded, or mid-teardown). Let the
      // caller through rather than deadlocking it — the server-side guard
      // (§8.3) is the backstop for exactly this case.
      AppLogger.w('[Reg] no context for the gate sheet — proceeding');
      return RegGateOutcome.proceed;
    }
    if (_sheetOpen) return RegGateOutcome.proceed;

    _sheetOpen = true;
    RegResolveResult? result;
    try {
      result = await showRegResolveSheet(
        context,
        item: item,
        mandatory: mandatory,
        byAdmin: byAdmin,
        staffName: staffName,
        mode: item.resolvesByEdit
            ? RegResolveMode.edit
            : RegResolveMode.create,
        initialSignOutLocal: initialSignOutLocal,
        initialReason: initialReason,
      );
    } finally {
      _sheetOpen = false;
    }

    if (result == null) return RegGateOutcome.blocked;

    try {
      if (item.resolvesByEdit) {
        await _edit(RegEditInput(
          code: item.pendingRequestCode!,
          attendanceDate: item.attendanceDate,
          signOutLocal: result.signOutLocal,
          reason: result.reason,
        ));
        _toast('Request updated');
        return RegGateOutcome.proceed;
      }

      final staffCode = item.staffCode.isNotEmpty
          ? item.staffCode
          : (fallbackStaffCode.isNotEmpty
              ? fallbackStaffCode
              : await _context.staffCode());

      final request = await _raise(RegRaiseInput(
        staffCode: staffCode,
        attendanceCode: item.attendanceCode,
        attendanceDate: item.attendanceDate,
        signOutLocal: result.signOutLocal,
        reason: result.reason,
      ));

      // The response status says what actually happened — staff-raised stays
      // PENDING, admin-raised is already applied (§8.2b). Never guessed
      // client-side: the server decides from the token.
      _toast(request.status == RegStatus.approved
          ? 'Sign-out applied · that day is now counted'
          : 'Sent for approval');
      return RegGateOutcome.proceed;
    } catch (error) {
      _toast(_messageFor(error), isError: true);
      // The correction did not land, so the gate is still unsatisfied. Failing
      // closed here matters: proceeding would let the sign-in through and
      // leave the open day behind, which is the backlog §5.1 exists to
      // prevent.
      return RegGateOutcome.blocked;
    }
  }

  // ——————————————————————————————————————————————————————————————
  // Bulk gate (§9.1b → §9.2b, cases C9a–C9d)
  // ——————————————————————————————————————————————————————————————

  /// Splits a bulk sign-in into who can go now and who must be closed first.
  ///
  /// Returns the staff the caller may sign in. Partial success is the whole
  /// design: the clear staff are always in [RegBulkGateOutcome.allowed], even
  /// when the admin skips the blocked ones.
  @override
  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes) async {
    final codes =
        staffCodes.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    if (codes.isEmpty) return const RegBulkGateOutcome(allowed: []);

    if (codes.length == 1) {
      // A one-person "bulk" sign-in is really a single sign-in; the
      // consolidated sheet would be odd for one row.
      final outcome = await guardSingle(codes.first, byAdmin: true);
      return RegBulkGateOutcome(
        allowed: outcome.isProceed ? codes : const [],
        cleared: outcome.isProceed ? 1 : 0,
        blockedRemaining: outcome.isProceed ? 0 : 1,
      );
    }

    final gate = await _getOpenSessionsBatch(codes);
    if (!gate.hasBlocked) return RegBulkGateOutcome.allowAll(codes);

    final context = _ctx;
    if (context == null || !context.mounted || _sheetOpen) {
      // Can't ask. Sign in whoever is clear and leave the rest gated — better
      // than blocking everyone on a sheet we cannot show.
      return RegBulkGateOutcome(
        allowed: gate.clear,
        blockedRemaining: gate.blocked.length,
      );
    }

    _sheetOpen = true;
    List<RegBulkGateItem>? items;
    try {
      items = await showRegBulkSignInGateSheet(
        context,
        blocked: gate.blocked,
        otherCount: gate.clear.length,
      );
    } finally {
      _sheetOpen = false;
    }

    // C9d — Skip. The clear staff still sign in; the blocked keep their gate.
    if (items == null || items.isEmpty) {
      return RegBulkGateOutcome(
        allowed: gate.clear,
        blockedRemaining: gate.blocked.length,
      );
    }

    try {
      final sharedReason = items.first.reason;
      final result = await _raiseBatch(
        items
            .map((i) => RegRaiseInput(
                  staffCode: i.staffCode,
                  attendanceCode: i.attendanceCode,
                  attendanceDate: i.attendanceDate,
                  signOutLocal: i.signOutLocal,
                  reason: i.reason,
                ))
            .toList(growable: false),
        sharedReason: sharedReason,
      );

      // Admin-raised, so every applied item is already approved (§8.2b) and
      // those staff are now clear. Skipped items were already resolved, which
      // also means they are clear.
      final resolvedCodes =
          items.map((i) => i.staffCode).toList(growable: false);
      return RegBulkGateOutcome(
        allowed: [...gate.clear, ...resolvedCodes],
        cleared: result.count,
        skipped: result.skipped.length,
      );
    } catch (error) {
      _toast(_messageFor(error), isError: true);
      // The batch failed, so nobody in `blocked` is cleared — but the clear
      // staff have nothing to do with that failure and still go through.
      return RegBulkGateOutcome(
        allowed: gate.clear,
        blockedRemaining: gate.blocked.length,
      );
    }
  }

  // ——————————————————————————————————————————————————————————————
  // Server-side backstop (§8.3)
  // ——————————————————————————————————————————————————————————————

  /// Handles a `409 REGULARIZATION_REQUIRED`. Returns true when the sign-in
  /// should be retried.
  ///
  /// This is the defensive path for a sign-in that skipped the pre-check. The
  /// payload carries the open session, so the sheet opens with **no second
  /// round trip** — but if the body does not carry it (shape not yet
  /// confirmed with backend), fall back to a fresh `GET /open-sessions`.
  @override
  Future<bool> handleConflict(
    Object error, {
    required bool byAdmin,
    String staffCode = '',
  }) async {
    if (!RegHttpErrors.isRegularizationRequired(error)) return false;

    final zone = await _context.timeZone();
    final payload = RegHttpErrors.openSessionsFrom(error);

    MissedSignout? item;
    if (payload.isNotEmpty) {
      item = RegMappers.toMissedSignout(payload.first, zone: zone);
    } else {
      final code =
          staffCode.trim().isEmpty ? await _context.staffCode() : staffCode;
      item = await peek(code);
    }
    if (item == null) return false;
    if (!item.blocksSignIn) return true; // already raised — just retry

    final outcome = await resolve(
      item,
      byAdmin: byAdmin,
      staffName: item.staffName,
      mandatory: true,
      fallbackStaffCode: staffCode,
    );
    return outcome.isProceed;
  }

  // ——————————————————————————————————————————————————————————————
  // Helpers
  // ——————————————————————————————————————————————————————————————

  String _messageFor(Object error) {
    if (error is RegAlreadyApprovedException) return error.message;
    return ApiErrorHandler.extractErrorMessage(error);
  }

  void _toast(String message, {bool isError = false}) {
    final context = _ctx;
    if (context == null || !context.mounted || message.trim().isEmpty) return;
    CoreUtils.showTopSnackBarFromSnackBar(
      context: context,
      snackBar: SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }
}
