import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/api_paths.dart';

/// The five `x-role` buckets the backend validates against. Finer backend roles
/// (TEACHER, DIRECTOR, ASSOCIATE_TEACHER …) are normalised into one of these so
/// `x-role` is always one of the accepted values.
enum _RoleBucket {
  guardian,
  staff,
  schoolAdmin,
  organizationAdmin,
  kiosk,
  unknown,
}

/// Adds the Authorization Bearer token and the **wowcare header contract** to
/// every authenticated request:
///
/// Always: `x-organization-code`, `x-role`, `x-channel` (=`mobile`),
/// `x-sub-channel` (=`wowcare`).
///
/// Role-conditional (driven by the validated `x-role`):
/// - GUARDIAN            → `x-guardian-code` + `x-school-code`
/// - STAFF / SCHOOL_ADMIN → `x-staff-code` + `x-school-code`
/// - ORGANIZATION_ADMIN  → `x-staff-code` + `x-school-code` (when a school is selected)
/// - KIOSK               → none (defaults only)
///
/// A missing/invalid required header makes the backend reject the request 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final StorageService _storage;

  /// This is the wowcare mobile app, so the channel pair is fixed.
  static const String _channel = 'mobile';
  static const String _subChannel = 'wowcare';

  static final _skipAuthPaths = [
    ApiPaths.authLogin,
    ApiPaths.authForgotPassword,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    final shouldSkip = _skipAuthPaths.any((p) => path.contains(p));
    if (shouldSkip) {
      handler.next(options);
      return;
    }

    // Token refresh rides the gateway's RELAXED path and must stay there.
    //
    // Strict validation is keyed on the PRESENCE of `x-sub-channel`: send it
    // and the gateway then demands the full role-scoped matrix (x-role +
    // x-staff-code/x-guardian-code + x-school-code). A PARTIAL strict set is
    // 4xx'd — which the 401 handler would turn into a logout loop. So refresh
    // sends Content-Type only, exactly like the web client's `refreshSession`,
    // which uses a raw fetch to bypass its own header injection.
    //
    // Matched by suffix, not by the full ApiPaths constant: on UAT the path is
    // `/api/v1/user/auth/refresh`, which does NOT contain `/api/v1/auth/refresh`
    // — the same reason [_skipAuthPaths] silently no-ops on UAT.
    if (path.contains('/auth/refresh')) {
      handler.next(options);
      return;
    }

    // If the request already has an explicit Authorization header (e.g. login-context
    // right after login with the fresh token), keep it and avoid overriding.
    final existingAuth =
        options.headers['Authorization'] ?? options.headers['authorization'];

    final token = (await _storage.getString(StorageKeys.accessToken) ?? '')
        .trim();

    // Always add baseline JSON headers. Only attach Authorization when missing.
    final baseHeaders = ApiHeaders.authorizedJson(token);
    // Normalize common JSON header casing so upstream services consistently receive them.
    options.headers['Content-Type'] =
        options.headers['Content-Type'] ??
        options.headers['content-type'] ??
        baseHeaders['Content-Type'];
    options.headers['accept'] =
        options.headers['accept'] ?? baseHeaders['accept'];
    if ((existingAuth == null || existingAuth.toString().trim().isEmpty) &&
        baseHeaders['Authorization'] != null) {
      options.headers['Authorization'] = baseHeaders['Authorization'];
    }

    // ── Resolve scope ────────────────────────────────────────────────────────
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final schoolCodeFromQuery = (options.queryParameters['schoolCode'] ?? '')
        .toString()
        .trim();
    final resolvedSchoolCode = schoolCode.isNotEmpty
        ? schoolCode
        : schoolCodeFromQuery;

    final staffCode = (await _storage.getString(StorageKeys.staffCode) ?? '')
        .trim();
    final guardianCode =
        (await _storage.getString(StorageKeys.guardianCode) ?? '').trim();

    var rawRole = (await _storage.getString(StorageKeys.activeSchoolRole) ?? '')
        .trim();
    if (rawRole.isEmpty) rawRole = await _firstRoleFromRolesList();
    final bucket = _bucketFor(rawRole);

    // ── Always-required headers ──────────────────────────────────────────────
    if (organizationCode.isNotEmpty) {
      _setMulti(
        options,
        organizationCode,
        lower: 'x-organization-code',
        pascal: 'X-Organization-Code',
        camel: 'organizationCode',
      );
    }
    final roleHeader = _roleHeaderValue(bucket);
    if (roleHeader.isNotEmpty) {
      options.headers['x-role'] = roleHeader;
      options.headers['X-Role'] = roleHeader;
    }
    options.headers['x-channel'] = _channel;
    options.headers['X-Channel'] = _channel;
    options.headers['x-sub-channel'] = _subChannel;
    options.headers['X-Sub-Channel'] = _subChannel;

    // ── Role-conditional headers ─────────────────────────────────────────────
    final staffHeader = staffCode.isNotEmpty ? staffCode : '-';
    // Mirror the staff `-` placeholder for guardians: send the real code once
    // resolved, otherwise a `-` so the bootstrap call (`/guardian/profile`,
    // which is what RESOLVES the code) isn't rejected for a "missing header"
    // before it can return the code. Real (post-bootstrap) requests are
    // unaffected — they carry the actual guardianCode.
    final guardianHeader = guardianCode.isNotEmpty ? guardianCode : '-';
    switch (bucket) {
      case _RoleBucket.guardian:
        _setMulti(
          options,
          guardianHeader,
          lower: 'x-guardian-code',
          pascal: 'X-Guardian-Code',
          camel: 'guardianCode',
        );
        _setSchool(options, resolvedSchoolCode);
        break;
      case _RoleBucket.staff:
      case _RoleBucket.schoolAdmin:
        _setStaff(options, staffHeader);
        _setSchool(options, resolvedSchoolCode);
        break;
      case _RoleBucket.organizationAdmin:
        // Org admins still operate within a selected school, and many
        // school-scoped endpoints (attendance sign-in/status, expected/summary
        // cards, classroom list, …) REQUIRE `x-school-code` or they reject with
        // 400 "Headers values not found". Send it whenever a school is selected;
        // _setSchool no-ops when there's no school, so pure org-level calls are
        // unaffected.
        _setStaff(options, staffHeader);
        _setSchool(options, resolvedSchoolCode);
        break;
      case _RoleBucket.kiosk:
        // Defaults only — no staff / guardian / school codes.
        _setSchool(options, resolvedSchoolCode);
        break;
      case _RoleBucket.unknown:
        // Role not resolved yet — fall back to the prior behaviour so requests
        // aren't broken before the persona role is known.
        _setStaff(options, staffHeader);
        _setSchool(options, resolvedSchoolCode);
        break;
    }

    handler.next(options);
  }

  void _setStaff(RequestOptions options, String code) {
    // The staff-code bootstrap (`/staff/code` → `/staff/staff/code` on UAT) is
    // the call that RESOLVES the staff code, so it must NOT carry one. Sending a
    // placeholder (`-`) makes the gateway reject it with "Staff code does not
    // belong to the authenticated user" before it can return the real code.
    if (options.path.contains('staff/code')) return;
    _setMulti(
      options,
      code,
      lower: 'x-staff-code',
      pascal: 'X-Staff-Code',
      camel: 'staffCode',
    );
  }

  void _setSchool(RequestOptions options, String code) {
    if (code.isEmpty) return;
    _setMulti(
      options,
      code,
      lower: 'x-school-code',
      pascal: 'X-School-Code',
      camel: 'schoolCode',
    );
  }

  /// Sets the lowercase contract header plus the legacy Pascal/camel variants
  /// some services still read.
  void _setMulti(
    RequestOptions options,
    String value, {
    required String lower,
    required String pascal,
    required String camel,
  }) {
    options.headers[lower] = value;
    options.headers[pascal] = value;
    options.headers[camel] = value;
  }

  /// Normalises any backend role string into one of the five contract buckets.
  _RoleBucket _bucketFor(String role) {
    final r = role.toUpperCase();
    if (r.isEmpty) return _RoleBucket.unknown;
    if (r.contains('KIOSK')) return _RoleBucket.kiosk;
    if (r.contains('GUARDIAN') || r.contains('PARENT')) {
      return _RoleBucket.guardian;
    }
    if (r.contains('ORGANIZATION_ADMIN') || r.contains('ORG_ADMIN')) {
      return _RoleBucket.organizationAdmin;
    }
    if (r.contains('SCHOOL_ADMIN')) return _RoleBucket.schoolAdmin;
    // STAFF / TEACHER / DIRECTOR / ASSOCIATE_TEACHER / ASSISTANT_DIRECTOR / …
    return _RoleBucket.staff;
  }

  String _roleHeaderValue(_RoleBucket bucket) {
    switch (bucket) {
      case _RoleBucket.guardian:
        return 'GUARDIAN';
      case _RoleBucket.staff:
        return 'STAFF';
      case _RoleBucket.schoolAdmin:
        return 'SCHOOL_ADMIN';
      case _RoleBucket.organizationAdmin:
        return 'ORGANIZATION_ADMIN';
      case _RoleBucket.kiosk:
        return 'KIOSK';
      case _RoleBucket.unknown:
        return '';
    }
  }

  /// Fallback when [StorageKeys.activeSchoolRole] isn't set yet: the active
  /// school is stored first in [StorageKeys.roles].
  Future<String> _firstRoleFromRolesList() async {
    final raw = (await _storage.getString(StorageKeys.roles) ?? '').trim();
    if (raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return ((decoded.first as Map)['role'] ?? '').toString().trim();
      }
    } catch (_) {}
    return '';
  }
}
