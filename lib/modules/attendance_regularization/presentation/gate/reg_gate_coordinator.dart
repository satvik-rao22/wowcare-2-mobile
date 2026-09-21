import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';

import '../../core/config/reg_config.dart';
import '../../core/errors/reg_exceptions.dart';
import '../../data/mappers/reg_mappers.dart';
import '../../data/reg_context.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/entities/reg_raise_input.dart';
import '../../domain/entities/regularization_request.dart';
import '../../domain/usecases/check_gate_usecase.dart';
import '../../domain/usecases/edit_regularization_usecase.dart';
import '../../domain/usecases/raise_regularization_batch_usecase.dart';
import '../../domain/usecases/raise_regularization_usecase.dart';
import '../widgets/reg_bulk_signin_gate_sheet.dart';
import '../widgets/reg_resolve_sheet.dart';
import 'reg_gate_outcome.dart';
import 'reg_sign_in_gate.dart';

/// Every gate decision, in one place — the sign-in interceptor, the dashboard
/// banner and the staff list all come through here.
///
/// It shows UI without being a widget, via [CoreUtils.rootNavigatorKey], the
/// same way this app already handles session expiry and school switching. That
/// is what lets the gate sit at the network boundary, where no caller can
/// forget to invoke it.
class RegGateCoordinator implements RegSignInGate {
  RegGateCoordinator({
    required CheckGateUseCase checkGate,
    required RaiseRegularizationUseCase raise,
    required RaiseRegularizationBatchUseCase raiseBatch,
    required EditRegularizationUseCase edit,
    required RegContext context,
  })  : _checkGate = checkGate,
        _raise = raise,
        _raiseBatch = raiseBatch,
        _edit = edit,
        _context = context;

  final CheckGateUseCase _checkGate;
  final RaiseRegularizationUseCase _raise;
  final RaiseRegularizationBatchUseCase _raiseBatch;
  final EditRegularizationUseCase _edit;
  final RegContext _context;

  /// Stops a dashboard auto-open and a tapped sign-in stacking two mandatory
  /// sheets on each other.
  bool _sheetOpen = false;

  BuildContext? get _ctx => CoreUtils.rootNavigatorKey.currentContext;

  /// The caller's own unresolved day, or `null`. Never shows anything, and
  /// swallows failures — a dashboard card must not break the dashboard.
  Future<MissedSignout?> peek() async {
    try {
      final gate = await _checkGate().timeout(RegConfig.gateCheckTimeout);
      return gate.blocked.isEmpty ? null : gate.blocked.first;
    } catch (error) {
      AppLogger.w('[Reg] gate peek failed: $error');
      return null;
    }
  }

  @override
  Future<RegGateOutcome> guardSingle(
    String staffCode, {
    required bool byAdmin,
    String staffName = '',
  }) async {
    final MissedSignout? open;
    try {
      // An admin signing someone else in names them; a self sign-in never has
      // to know its own code.
      final gate = await _checkGate(staffCodes: byAdmin ? [staffCode] : null)
          .timeout(RegConfig.gateCheckTimeout);
      open = gate.blocked.isEmpty ? null : gate.blocked.first;
    } catch (error) {
      // The gate must never be why a sign-in fails; the server guard holds.
      AppLogger.w('[Reg] gate check failed, proceeding: $error');
      return RegGateOutcome.proceed;
    }

    // Sign-in is allowed once a request exists, approved or not.
    if (open == null || !open.blocksSignIn) return RegGateOutcome.proceed;

    return resolve(
      open,
      byAdmin: byAdmin,
      staffName: staffName.isNotEmpty ? staffName : open.staffName,
      fallbackStaffCode: staffCode,
    );
  }

  /// Opens the sheet for a known day and submits it. Create or edit is chosen
  /// from the day itself, so re-opening a raised day PATCHes rather than
  /// attempting a duplicate create.
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
    if (context == null || !context.mounted || _sheetOpen) {
      // Nowhere to show it. Let the caller through rather than deadlock — the
      // server's 409 is the backstop for exactly this.
      return RegGateOutcome.proceed;
    }

    _sheetOpen = true;
    RegResolveResult? result;
    try {
      result = await showRegResolveSheet(
        context,
        item: item,
        mandatory: mandatory,
        byAdmin: byAdmin,
        staffName: staffName,
        mode: item.resolvesByEdit ? RegResolveMode.edit : RegResolveMode.create,
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

      final request = await _raise(RegRaiseInput(
        staffCode:
            item.staffCode.isNotEmpty ? item.staffCode : fallbackStaffCode,
        attendanceCode: item.attendanceCode,
        attendanceDate: item.attendanceDate,
        signOutLocal: result.signOutLocal,
        reason: result.reason,
      ));

      // The server decides from the token, so read the status rather than
      // guessing from who we think is logged in.
      _toast(request.status.isApproved
          ? 'Sign-out applied · that day is now counted'
          : 'Sent for approval');
      return RegGateOutcome.proceed;
    } catch (error) {
      _toast(_messageFor(error), isError: true);
      // Fail closed: proceeding would sign them in and leave the open day
      // behind, which is the backlog the gate exists to prevent.
      return RegGateOutcome.blocked;
    }
  }

  @override
  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes) async {
    final codes =
        staffCodes.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    if (codes.isEmpty) return const RegBulkGateOutcome(allowed: []);

    if (codes.length == 1) {
      final outcome = await guardSingle(codes.first, byAdmin: true);
      return RegBulkGateOutcome(
        allowed: outcome.isProceed ? codes : const [],
        cleared: outcome.isProceed ? 1 : 0,
        blockedRemaining: outcome.isProceed ? 0 : 1,
      );
    }

    final List<MissedSignout> blocked;
    final List<String> clear;
    try {
      final gate = await _checkGate(staffCodes: codes)
          .timeout(RegConfig.gateCheckTimeout);
      blocked = gate.blocked;
      clear = gate.clear;
    } catch (error) {
      AppLogger.w('[Reg] bulk gate check failed, proceeding: $error');
      return RegBulkGateOutcome.allowAll(codes);
    }
    if (blocked.isEmpty) return RegBulkGateOutcome.allowAll(codes);

    return _closeBlocked(blocked, clear: clear);
  }

  @override
  Future<bool> handleConflict(
    Object error, {
    required bool byAdmin,
    String staffCode = '',
  }) async {
    if (!RegHttpErrors.isRegularizationRequired(error)) return false;

    // The blocked day travels in the error, so the sheet opens with no second
    // call; a body without it falls back to a fresh check.
    final payload = RegHttpErrors.blockedSessionsFrom(error);
    final item = payload.isNotEmpty
        ? (await _toBlocked(payload)).first
        : await peek();

    if (item == null) return false;
    if (!item.blocksSignIn) return true;

    final outcome = await resolve(
      item,
      byAdmin: byAdmin,
      staffName: item.staffName,
      fallbackStaffCode: staffCode,
    );
    return outcome.isProceed;
  }

  @override
  Future<List<String>> resolveBlocked(
    List<Map<String, dynamic>> blocked, {
    required bool byAdmin,
  }) async {
    if (blocked.isEmpty) return const [];
    final items = (await _toBlocked(blocked))
        .where((i) => i.blocksSignIn)
        .toList(growable: false);
    if (items.isEmpty) {
      // Already raised by someone else — they can be signed in as they are.
      return blocked
          .map((m) => (m['staffCode'] ?? '').toString())
          .where((c) => c.isNotEmpty)
          .toList(growable: false);
    }

    if (items.length == 1) {
      final outcome = await resolve(
        items.first,
        byAdmin: byAdmin,
        staffName: items.first.staffName,
      );
      return outcome.isProceed ? [items.first.staffCode] : const [];
    }

    final outcome = await _closeBlocked(items, clear: const []);
    return outcome.allowed;
  }

  /// Shared tail of the bulk paths: one consolidated sheet, then one batch
  /// raise. [clear] staff pass through regardless — that is what makes a bulk
  /// sign-in partial-success rather than all-or-nothing.
  Future<RegBulkGateOutcome> _closeBlocked(
    List<MissedSignout> blocked, {
    required List<String> clear,
  }) async {
    final context = _ctx;
    if (context == null || !context.mounted || _sheetOpen) {
      return RegBulkGateOutcome(
        allowed: clear,
        blockedRemaining: blocked.length,
      );
    }

    _sheetOpen = true;
    List<RegBulkGateItem>? items;
    try {
      items = await showRegBulkSignInGateSheet(
        context,
        blocked: blocked,
        otherCount: clear.length,
      );
    } finally {
      _sheetOpen = false;
    }

    // Skip: the clear staff still sign in; the blocked keep their gate.
    if (items == null || items.isEmpty) {
      return RegBulkGateOutcome(
        allowed: clear,
        blockedRemaining: blocked.length,
      );
    }

    try {
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
        sharedReason: items.first.reason,
      );
      // Admin-raised, so applied items are already approved and skipped ones
      // were already resolved. Both are clear.
      return RegBulkGateOutcome(
        allowed: [...clear, ...items.map((i) => i.staffCode)],
        cleared: result.applied,
        skipped: result.skipped.length,
      );
    } catch (error) {
      _toast(_messageFor(error), isError: true);
      return RegBulkGateOutcome(
        allowed: clear,
        blockedRemaining: blocked.length,
      );
    }
  }

  Future<List<MissedSignout>> _toBlocked(
    List<Map<String, dynamic>> raw,
  ) async {
    final zone = await _context.timeZone();
    return raw
        .map((m) => RegMappers.toMissedSignout(m, zone: zone))
        .toList(growable: false);
  }

  String _messageFor(Object error) {
    if (error is RegAlreadyApprovedException) return error.message;
    final fromServer = RegHttpErrors.messageOf(error);
    return fromServer.isNotEmpty
        ? fromServer
        : ApiErrorHandler.extractErrorMessage(error);
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
