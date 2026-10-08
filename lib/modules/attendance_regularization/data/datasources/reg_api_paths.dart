import '../../core/config/reg_config.dart';

/// The seven regularization endpoints, plus the sign-in URLs the gate watches.
///
/// Three endpoints serve both personas through one call — the token decides
/// what comes back, so the client never picks a path based on who is logged in.
abstract final class RegApiPaths {
  const RegApiPaths._();

  static const String base = '/api/v1/staff-attendance-regularizations';

  /// `{}` checks the caller; `{staffCodes:[…]}` checks a roster. Same
  /// `{blocked, clear}` response either way.
  static const String openSessionsCheck = '$base/open-sessions/check';

  /// Staff land `PENDING`; an admin is the approver, so theirs is applied.
  static const String raise = base;
  static const String raiseBatch = '$base/raise-batch';

  /// Own rows for staff, the whole school for an admin.
  static const String list = base;

  static const String approveSelected = '$base/approve-selected';

  static String approve(String code) => '$base/$code/approve';

  /// The raiser only — an edit overwrites `requestedSignOutTime`, so an admin
  /// editing someone else's request would erase what they asked for.
  static String edit(String code) => '$base/$code';

  // —— sign-in guard ——

  /// The sign-in resource, without `/api/v1` and without the microservice
  /// segment the gateway inserts.
  ///
  /// Matching on the tail is not a shortcut. The same sign-in is
  /// `/api/v1/staff-attendance-records/sign-in` against a local service and
  /// `/api/v1/attendance/staff-attendance-records/sign-in` behind the UAT/DEV
  /// gateway, and `ApiPaths.url` rewrites it on the way out — so a full-path
  /// match silently stops gating the moment the app points at a gateway env,
  /// which is exactly what happened.
  static const String _signIn = 'staff-attendance-records/sign-in';
  static const String _signInSelf = '$_signIn/self';

  /// Concrete examples of each shape, for callers and tests.
  static const String signInAdmin = '/api/v1/$_signIn';
  static const String signInSelf = '/api/v1/$_signInSelf';
  static const String signInKiosk = '/api/v1/attendance/$_signIn';

  /// Every staff sign-in in the app lands on one of these, which is why the
  /// gate is one interceptor rather than an edit in 11 widgets.
  static bool isStaffSignIn(String path) {
    final clean = _pathOf(path);
    return clean.endsWith(_signInSelf) || clean.endsWith(_signIn);
  }

  /// True when the **token already names the subject**, so the gate asks about
  /// the caller rather than about somebody else.
  ///
  /// Read from the URL, not a client flag, so it cannot disagree with the role
  /// the server infers.
  static bool isSelfSignIn(String path) => _pathOf(path).endsWith(_signInSelf);

  /// A kiosk posts to the same URL an admin does once the gateway prefix is
  /// applied, so the method in the body is the only thing that separates them.
  ///
  /// It matters because a kiosk is not an approver: its corrections land
  /// `PENDING`, like any staff member's.
  static bool isKioskSignIn(Object? body) =>
      body is Map &&
      '${body['method'] ?? ''}'.trim().toUpperCase() == RegMethod.kiosk;

  static String _pathOf(String path) => path.split('?').first;
}
