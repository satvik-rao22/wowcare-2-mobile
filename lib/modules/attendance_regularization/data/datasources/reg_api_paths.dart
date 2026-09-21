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

  /// Every staff sign-in in the app lands on one of these three, which is why
  /// the gate is one interceptor rather than an edit in 11 widgets.
  static const String signInAdmin = '/api/v1/staff-attendance-records/sign-in';
  static const String signInSelf =
      '/api/v1/staff-attendance-records/sign-in/self';
  static const String signInKiosk =
      '/api/v1/attendance/staff-attendance-records/sign-in';

  /// Suffix match, so it holds for bare paths and absolute URLs alike.
  static bool isStaffSignIn(String path) {
    final clean = path.split('?').first;
    return clean.endsWith(signInSelf) ||
        clean.endsWith(signInKiosk) ||
        clean.endsWith(signInAdmin);
  }

  /// Read from the URL, not a client flag, so it cannot disagree with the role
  /// the server infers. Kiosk counts as self: its corrections land `PENDING`.
  static bool isSelfSignIn(String path) {
    final clean = path.split('?').first;
    return clean.endsWith(signInSelf) || clean.endsWith(signInKiosk);
  }

  /// A kiosk has no staff record, so `{}` is a 400 for it.
  static bool gateNeedsStaffCodes(String path) =>
      path.split('?').first.endsWith(signInKiosk);
}
