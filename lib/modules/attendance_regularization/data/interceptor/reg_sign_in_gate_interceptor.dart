import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/logger_service.dart';

import '../../core/config/reg_config.dart';
import '../../presentation/gate/reg_sign_in_gate.dart';
import '../datasources/reg_api_paths.dart';

/// Installs the sign-in gate at the network boundary.
///
/// `StaffSignInForm` is built from 11 places and kiosk signs in through a
/// different repository, but all of them land on three URLs. Intercepting there
/// covers every one, changes no existing file, and makes bypass impossible — a
/// new sign-in path inherits the gate without anyone remembering to add it.
///
/// Deliberately dull: it matches three URL suffixes and holds no logic of its
/// own. Every decision belongs to [RegSignInGate].
class RegSignInGateInterceptor extends Interceptor {
  RegSignInGateInterceptor(this._gate, this._dio);

  final RegSignInGate _gate;

  /// The client this is attached to, so a replay keeps the rest of the chain —
  /// notably the token refresh. Mirrors `SessionExpiredInterceptor`.
  final Dio _dio;

  /// Marks a replay so it passes straight through and cannot loop.
  static const String _replayFlag = 'reg.replay';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!RegApiPaths.isStaffSignIn(options.path) || _isReplay(options)) {
      return handler.next(options);
    }

    final codes = _staffCodesFrom(options.data);
    if (codes.isEmpty) return handler.next(options);

    final byAdmin = !RegApiPaths.isSelfSignIn(options.path);

    try {
      if (codes.length > 1) {
        // Without the pre-check the server still answers with `blocked`, and
        // onResponse picks it up from there.
        if (!RegConfig.preCheckBulkSignIn) return handler.next(options);

        final outcome = await _gate.guardBulk(codes);
        if (outcome.isEmpty) {
          return handler.reject(_rejection(options, 'Sign-in cancelled.'));
        }
        // Narrow rather than fail: the clear staff are never held up by
        // someone else's forgotten sign-out.
        if (outcome.allowed.length != codes.length) {
          options.data = _withStaffCodes(options.data, outcome.allowed);
        }
        return handler.next(options);
      }

      if (RegConfig.preCheckSingleSignIn) {
        final outcome = await _gate.guardSingle(codes.first, byAdmin: byAdmin);
        if (outcome.isBlocked) {
          return handler.reject(_rejection(options, 'Sign-in cancelled.'));
        }
      }
      return handler.next(options);
    } catch (error, stack) {
      // The gate must never be why a sign-in fails; the server guard holds.
      AppLogger.e('[Reg] gate pre-check failed, proceeding: $error', stack);
      return handler.next(options);
    }
  }

  /// A bulk sign-in is partial success: anyone still owing a correction comes
  /// back under `blocked` while everybody else is signed in.
  ///
  /// Without this they would vanish silently — the host reads only `success`
  /// and `message`, so the admin would see a clean result while ten people
  /// stayed out.
  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (!RegApiPaths.isStaffSignIn(options.path) || _isReplay(options)) {
      return handler.next(response);
    }

    final blocked = _blockedFrom(response.data);
    if (blocked.isEmpty) return handler.next(response);

    try {
      final cleared = await _gate.resolveBlocked(
        blocked,
        byAdmin: !RegApiPaths.isSelfSignIn(options.path),
      );
      if (cleared.isEmpty) {
        // Skipped — say so rather than letting a clean "signed in" stand.
        return handler.next(
          _withMessage(
            response,
            '${blocked.length} still need yesterday closed.',
          ),
        );
      }

      final retried = await _retry(
        options,
        data: _withStaffCodes(options.data, cleared),
      );
      return handler.resolve(_merge(response, retried));
    } catch (error, stack) {
      AppLogger.e('[Reg] blocked-response recovery failed: $error', stack);
      return handler.next(response);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!RegApiPaths.isStaffSignIn(options.path) || _isReplay(options)) {
      return handler.next(err);
    }

    final codes = _staffCodesFrom(options.data);

    try {
      final resolved = await _gate.handleConflict(
        err,
        byAdmin: !RegApiPaths.isSelfSignIn(options.path),
        staffCode: codes.length == 1 ? codes.first : '',
      );
      if (!resolved) return handler.next(err);
      // The user does not have to tap sign-in a second time.
      return handler.resolve(await _retry(options));
    } catch (error, stack) {
      AppLogger.e('[Reg] 409 recovery failed: $error', stack);
      return handler.next(err);
    }
  }

  /// Replayed through the attached client so auth refresh still applies, and
  /// flagged so this interceptor lets it past instead of gating it again.
  Future<Response<dynamic>> _retry(RequestOptions options, {Object? data}) {
    final replay = options.copyWith(
      data: data ?? options.data,
      extra: <String, dynamic>{...options.extra, _replayFlag: true},
    );
    return _dio.fetch<dynamic>(replay);
  }

  bool _isReplay(RequestOptions options) => options.extra[_replayFlag] == true;

  DioException _rejection(RequestOptions options, String message) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: message,
        message: message,
      );

  /// The admin endpoint sends `staffCodes` **and** the acting admin's own
  /// `staffCode`, so the list wins — otherwise the admin gets gated instead of
  /// the people being signed in.
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

  List<Map<String, dynamic>> _blockedFrom(Object? data) {
    if (data is! Map) return const [];
    final payload = data['data'];
    final blocked = payload is Map ? payload['blocked'] : data['blocked'];
    if (blocked is! List) return const [];
    return blocked
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  /// Narrows `staffCodes`, dropping the per-staff classroom entries for anyone
  /// held back so the server is not told about people it is not signing in.
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

  Response<dynamic> _withMessage(Response<dynamic> response, String message) {
    final data = response.data;
    if (data is! Map) return response;
    response.data = Map<String, dynamic>.from(data)..['message'] = message;
    return response;
  }

  /// Folds the retry's newly signed-in staff back into the first response, so
  /// a caller reading `signedIn` sees everyone who ended up in.
  Response<dynamic> _merge(Response<dynamic> first, Response<dynamic> second) {
    final a = first.data;
    final b = second.data;
    if (a is! Map || b is! Map) return second;

    final firstData = a['data'];
    final secondData = b['data'];
    if (firstData is! Map || secondData is! Map) return second;

    final merged = Map<String, dynamic>.from(secondData);
    merged['signedIn'] = [
      ...?(firstData['signedIn'] as List?),
      ...?(secondData['signedIn'] as List?),
    ];
    merged['blocked'] = secondData['blocked'] ?? const [];

    second.data = Map<String, dynamic>.from(b)..['data'] = merged;
    return second;
  }
}
