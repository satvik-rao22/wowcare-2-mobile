/// Every path this module talks to (spec §9), in one place.
///
/// Paths are `/api/v1/…` with no microservice segment — the host is chosen
/// from the first resource segment by `ApiPaths.urlWithBase`, the same way
/// `attendance_v2`'s datasource resolves its endpoints.
abstract final class RegApiPaths {
  const RegApiPaths._();

  static const String base = '/api/v1/staff-attendance-regularizations';

  /// §9.1 — `GET ?staffCode={code}`. The gate for one staff.
  static const String openSessions = '$base/open-sessions';

  /// §9.1b — `POST`. The gate for many staff, for bulk sign-in.
  static const String openSessionsBatch = '$base/open-sessions/batch';

  /// §9.2 — `POST`. Raise a request.
  static const String raise = base;

  /// §9.2b — `POST`. Raise many (admin only).
  static const String raiseBatch = '$base/raise-batch';

  /// §9.3 (`staffCode`) and §9.5 (`schoolCode`) — `GET`. One endpoint; the
  /// scope and filters live in the query string.
  static const String list = base;

  /// §9.7 — `POST`. Approve a chosen set.
  static const String approveSelected = '$base/approve-selected';

  /// §9.4 — `PATCH /{code}`. Revise a pending request. Replaces cancel (§8.4).
  static String edit(String code) => '$base/$code';

  /// §9.6 — `POST /{code}/approve`.
  static String approve(String code) => '$base/$code/approve';

  // ——————————————————————————————————————————————————————————————
  // Sign-in guard (§8.3)
  // ——————————————————————————————————————————————————————————————

  /// The three URLs every staff sign-in in the app funnels into.
  ///
  /// There are 11 `StaffSignInForm` call sites plus kiosk v2, but only these
  /// three endpoints — which is why the gate is installed as one Dio
  /// interceptor rather than edited into a dozen widgets.
  ///
  /// Note the kiosk path carries an extra `/attendance/` segment; it is a
  /// genuinely different endpoint reached through a different repository.
  static const String signInAdmin = '/api/v1/staff-attendance-records/sign-in';
  static const String signInSelf =
      '/api/v1/staff-attendance-records/sign-in/self';
  static const String signInKiosk =
      '/api/v1/attendance/staff-attendance-records/sign-in';

  /// True when [path] is one of the staff sign-in endpoints.
  ///
  /// Matched by suffix so it holds whether the caller passed a bare path or a
  /// fully-qualified URL (the kiosk datasource builds an absolute URL, the
  /// rest go through `ApiPaths.urlWithBase`).
  static bool isStaffSignIn(String path) {
    final clean = path.split('?').first;
    // `signInSelf` ends with `/sign-in/self`, so check it before the prefix
    // match on `/sign-in` to keep the self/admin distinction intact.
    return clean.endsWith(signInSelf) ||
        clean.endsWith(signInKiosk) ||
        clean.endsWith(signInAdmin);
  }

  /// True when the staff is signing **themselves** in, rather than an admin
  /// doing it for them.
  ///
  /// Read from the URL rather than a client flag so it cannot disagree with
  /// the role the server will infer from the token. This is what decides admin
  /// vs staff copy in the gate sheet — and, because §8.2b keys auto-approval
  /// off the authenticated role, whether the correction lands `PENDING` or
  /// applied.
  ///
  /// Kiosk counts as **self**: the person at the device authenticated with
  /// their own PIN and is signing themselves in, so the server sees a staff
  /// principal and the request must land `PENDING` like any other self
  /// sign-in.
  static bool isSelfSignIn(String path) {
    final clean = path.split('?').first;
    return clean.endsWith(signInSelf) || clean.endsWith(signInKiosk);
  }
}
