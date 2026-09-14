import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/logger_service.dart';

import '../../core/config/reg_config.dart';
import '../../presentation/gate/reg_sign_in_gate.dart';
import '../datasources/reg_api_paths.dart';

/// Installs the sign-in gate (spec §8.3) at the network boundary.
///
/// ### Why an interceptor
///
/// `StaffSignInForm` is constructed from **11 places**, and kiosk v2 signs in
/// through a different repository entirely — but all 12 paths land on just
/// three URLs. Intercepting there covers every one of them, changes **zero**
/// existing files, and makes bypass structurally impossible: a 13th sign-in
/// entry point added next quarter inherits the gate without anyone
/// remembering to add it.
///
/// The alternatives were worse. Editing the forms means 11 changes and misses
/// kiosk. Decorating the repositories means forwarding 50 methods
/// (`AttendanceRepository` has 46, kiosk 4) across two classes.
///
/// ### Keeping it honest
///
/// Interceptors deserve suspicion, so this one is deliberately dull: it
/// matches three URL suffixes, passes everything else straight through, and
/// holds no logic of its own — every decision belongs to
/// [RegSignInGate], whose implementation is a plain injectable class testable without
/// Dio or widgets. It also puts the §9.1 pre-check and the §8.3 `409` backstop
/// in the same file (`onRequest` / `onError`) rather than in two mechanisms
/// that can drift.
class RegSignInGateInterceptor extends Interceptor {
  RegSignInGateInterceptor(this._gate);

  final RegSignInGate _gate;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!RegApiPaths.isStaffSignIn(options.path)) {
      return handler.next(options);
    }

    final codes = _staffCodesFrom(options.data);
    if (codes.isEmpty) {
      // Nothing to check against — let the server's guard decide (§8.3).
      return handler.next(options);
    }

    final byAdmin = !RegApiPaths.isSelfSignIn(options.path);

    try {
      // —— Bulk (§5.1c, C9a–C9d) ——
      if (codes.length > 1) {
        final outcome = await _gate.guardBulk(codes);
        if (outcome.isEmpty) {
          return handler.reject(_rejection(options, 'Sign-in cancelled.'));
        }
        // Narrow the payload rather than failing the request. This is what
        // makes bulk sign-in partial-success: 40 clear staff are never held
        // up because 10 forgot to sign out.
        if (outcome.allowed.length != codes.length) {
          options.data = _withStaffCodes(options.data, outcome.allowed);
        }
        return handler.next(options);
      }

      // —— Single ——
      if (RegConfig.preCheckSingleSignIn) {
        final outcome = await _gate.guardSingle(codes.first, byAdmin: byAdmin);
        if (outcome.isBlocked) {
          return handler.reject(_rejection(options, 'Sign-in cancelled.'));
        }
      }
      return handler.next(options);
    } catch (error, stack) {
      // The gate must never be the reason a sign-in fails. If our own check
      // breaks, fall through and let the server's guard (§8.3) hold the line.
      AppLogger.e('[Reg] gate pre-check failed, proceeding: $error', stack);
      return handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!RegApiPaths.isStaffSignIn(err.requestOptions.path)) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    final codes = _staffCodesFrom(options.data);
    final byAdmin = !RegApiPaths.isSelfSignIn(options.path);

    try {
      final resolved = await _gate.handleConflict(
        err,
        byAdmin: byAdmin,
        staffCode: codes.length == 1 ? codes.first : '',
      );
      if (!resolved) return handler.next(err);

      // The gate is satisfied now, so replay the original sign-in — the user
      // does not have to tap sign-in a second time.
      final retried = await _retry(options);
      return handler.resolve(retried);
    } catch (error, stack) {
      AppLogger.e('[Reg] 409 recovery failed: $error', stack);
      return handler.next(err);
    }
  }

  /// Replays [options] on a bare Dio.
  ///
  /// A fresh client is used on purpose: re-entering the app's interceptor
  /// chain would run this interceptor again and could loop. Auth headers are
  /// already on [options] from the first attempt, so the replay carries them.
  Future<Response<dynamic>> _retry(RequestOptions options) {
    return Dio().fetch<dynamic>(options);
  }

  DioException _rejection(RequestOptions options, String message) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.cancel,
      error: message,
      message: message,
    );
  }

  /// Reads the staff codes out of a sign-in body.
  ///
  /// The admin/bulk endpoint sends `staffCodes: [...]` **and** a `staffCode`
  /// (the acting admin), so the list is checked first — reading `staffCode`
  /// there would gate the admin instead of the people being signed in.
  List<String> _staffCodesFrom(Object? data) {
    if (data is! Map) return const [];

    final many = data['staffCodes'];
    if (many is List) {
      final codes = many
          .map((e) => (e ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (codes.isNotEmpty) return codes;
    }

    final one = (data['staffCode'] ?? '').toString().trim();
    return one.isEmpty ? const [] : <String>[one];
  }

  /// Returns a copy of [data] with `staffCodes` narrowed to [allowed],
  /// dropping any per-staff maps for the staff being held back so the server
  /// is not told about classrooms for people it is not signing in.
  Object? _withStaffCodes(Object? data, List<String> allowed) {
    if (data is! Map) return data;
    final next = Map<String, dynamic>.from(data);
    next['staffCodes'] = allowed;

    final byStaff = next['classroomCodeByStaffCode'];
    if (byStaff is Map) {
      next['classroomCodeByStaffCode'] = <String, dynamic>{
        for (final entry in byStaff.entries)
          if (allowed.contains(entry.key.toString()))
            entry.key.toString(): entry.value,
      };
    }
    return next;
  }
}
