import 'package:dio/dio.dart';

import '../../core/config/reg_config.dart';
import '../../core/utils/reg_time_zone.dart';
import '../../domain/policy/reg_time_policy.dart';
import 'reg_remote_datasource.dart';

/// One in-memory `staff_attendance_record`, reduced to the fields the gate
/// cares about (spec §7.3).
class MockAttendanceRow {
  MockAttendanceRow({
    required this.attendanceCode,
    required this.staffCode,
    required this.staffName,
    required this.attendanceDate,
    required this.signedInAtLocal,
    this.signedOutAtLocal,
    this.signedOutMethod,
    this.classroomCode = 'CLS_MOCK_A',
    this.schoolCode = 'SCH_MOCK',
    this.regularizationCode,
  });

  final String attendanceCode;
  final String staffCode;
  final String staffName;

  /// School-local calendar date.
  final DateTime attendanceDate;

  /// School-local wall-clock — the mock converts to UTC on the way out.
  final DateTime signedInAtLocal;

  DateTime? signedOutAtLocal;

  /// `null` (open), `SYSTEM` (scheduler guess), `REGULARIZED` (approved
  /// correction), or a human method like `APP`.
  String? signedOutMethod;

  final String classroomCode;
  final String schoolCode;
  String? regularizationCode;

  /// §9.1 detection: a day's last session that no human closed.
  ///
  /// `total_worked_minutes` is deliberately not part of this — §9.1 explains
  /// that testing minutes makes detection fragile, and `SYSTEM` is
  /// unambiguous on its own because only the scheduler ever writes it.
  bool get isUnresolved =>
      signedOutAtLocal == null || signedOutMethod == 'SYSTEM';
}

/// A stateful, in-memory stand-in for the whole regularization API (spec §9).
///
/// This is **not** a fixture list. It holds attendance rows and request rows
/// and enforces the locked business rules, so the real end-to-end loop —
/// gate fires → raise → sign-in unblocks → admin approves → gate clears —
/// runs in the actual app with no backend at all.
///
/// It returns the same JSON envelopes the server will, so `RegMappers` is
/// exercised on this path too and mapping bugs surface now rather than on
/// cutover day.
///
/// ### Rules enforced
/// | Rule | Behaviour |
/// |---|---|
/// | §4 | last session per `(staff, date)` only |
/// | §9.1 | open **or** `SYSTEM`, past days only |
/// | §8.2 | `reason` mandatory, trimmed |
/// | §8.2b | admin raise → `APPROVED` + applied, `approvalByCode == raisedByCode` |
/// | §8.5 | after sign-in, within the day window |
/// | §8.6 | idempotent raise and approve; edit on approved → `409` |
/// | §8.7 | apply writes `REGULARIZED` onto the row, which clears the gate |
/// | §9.2b / §9.7 | `{applied|approved, skipped[]}` |
///
/// Delete this file at cutover; nothing imports it except
/// `regularization_di.dart`.
class RegMockDataSource implements RegRemoteDataSource {
  RegMockDataSource({
    this.zone = 'America/New_York',
    this.schoolCode = 'SCH_MOCK',
    String actingStaffCode = 'STF_ME',
    String actingUserCode = 'USR_ME',
    bool actingAsAdmin = false,
    this.autoSeedUnknownStaff = true,
    List<MockAttendanceRow>? rows,
  })  : _actingStaffCode = actingStaffCode,
        _actingUserCode = actingUserCode,
        _actingAsAdmin = actingAsAdmin {
    _rows.addAll(rows ?? _seedRows(actingStaffCode));
  }

  final String zone;
  final String schoolCode;

  /// Give any staff code we have never seen an unresolved yesterday.
  ///
  /// Without this the mock only knows about its seeded codes, and running the
  /// app as a real logged-in user would show no gate at all — which defeats
  /// the point of having a mock you can demo against. Turn it off in tests
  /// that assert on a specific set of rows.
  final bool autoSeedUnknownStaff;

  /// Staff codes already auto-seeded, so resolving a day does not immediately
  /// hand the same person a fresh one.
  final Set<String> _autoSeeded = {};

  /// Who the "authenticated principal" is. §8.2b keys auto-approval off the
  /// **role**, never a request field, so the mock does the same: flipping
  /// [actingAsAdmin] is the only way to get the admin branch.
  String _actingStaffCode;
  String _actingUserCode;
  bool _actingAsAdmin;

  final List<MockAttendanceRow> _rows = [];

  /// Request rows, keyed by `code`, stored in wire shape.
  final Map<String, Map<String, dynamic>> _requests = {};

  int _seq = 0;

  /// Set to make the next call fail, for building error states against the
  /// real UI.
  Object? failNext;

  /// Overrides [RegConfig.mockLatency] for a single test.
  Duration? latency;

  // ——————————————————————————————————————————————————————————————
  // Test / dev controls
  // ——————————————————————————————————————————————————————————————

  void actAsStaff({String staffCode = 'STF_ME', String userCode = 'USR_ME'}) {
    _actingStaffCode = staffCode;
    _actingUserCode = userCode;
    _actingAsAdmin = false;
  }

  void actAsAdmin({String userCode = 'USR_ADMIN'}) {
    _actingUserCode = userCode;
    _actingAsAdmin = true;
  }

  bool get isActingAsAdmin => _actingAsAdmin;

  List<MockAttendanceRow> get rows => List.unmodifiable(_rows);

  Map<String, Map<String, dynamic>> get requests => Map.unmodifiable(_requests);

  MockAttendanceRow? rowFor(String attendanceCode) =>
      _rows.where((r) => r.attendanceCode == attendanceCode).firstOrNull;

  void addRow(MockAttendanceRow row) => _rows.add(row);

  void reset() {
    _rows
      ..clear()
      ..addAll(_seedRows(_actingStaffCode));
    _requests.clear();
    _autoSeeded.clear();
    _seq = 0;
    failNext = null;
  }

  /// Seeds [staffCode] an unresolved yesterday the first time it is queried.
  void _ensureSeeded(String staffCode) {
    if (!autoSeedUnknownStaff) return;
    final code = staffCode.trim();
    if (code.isEmpty || _autoSeeded.contains(code)) return;
    _autoSeeded.add(code);
    if (_rows.any((r) => r.staffCode == code)) return;

    final d = DateTime.now().subtract(const Duration(days: 1));
    final date = DateTime(d.year, d.month, d.day);
    _rows.add(MockAttendanceRow(
      attendanceCode: 'STAR_MOCK_AUTO_${_rows.length}',
      staffCode: code,
      staffName: 'Staff $code',
      attendanceDate: date,
      signedInAtLocal: DateTime(date.year, date.month, date.day, 7, 45),
      schoolCode: schoolCode,
    ));
  }

  /// Default seed: the acting staff has yesterday still open, and two
  /// colleagues are unresolved too — one open, one scheduler-closed — so the
  /// bulk gate has something to show.
  static List<MockAttendanceRow> _seedRows(String actingStaffCode) {
    final today = DateTime.now();
    DateTime dayAt(int daysAgo, int h, int m) {
      final d = today.subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, h, m);
    }

    DateTime dateOf(int daysAgo) {
      final d = today.subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day);
    }

    return [
      // Yesterday, never signed out — the classic gate case.
      MockAttendanceRow(
        attendanceCode: 'STAR_MOCK_ME_1',
        staffCode: actingStaffCode,
        staffName: 'You',
        attendanceDate: dateOf(1),
        signedInAtLocal: dayAt(1, 7, 37),
      ),
      // Two days ago, closed properly — must NOT gate.
      MockAttendanceRow(
        attendanceCode: 'STAR_MOCK_ME_0',
        staffCode: actingStaffCode,
        staffName: 'You',
        attendanceDate: dateOf(2),
        signedInAtLocal: dayAt(2, 7, 40),
        signedOutAtLocal: dayAt(2, 17, 5),
        signedOutMethod: 'APP',
      ),
      // A colleague the scheduler auto-closed on a guess — still gates (§1).
      MockAttendanceRow(
        attendanceCode: 'STAR_MOCK_A',
        staffCode: 'STF_A',
        staffName: 'Sara Malik',
        attendanceDate: dateOf(1),
        signedInAtLocal: dayAt(1, 7, 30),
        signedOutAtLocal: dayAt(1, 17, 30),
        signedOutMethod: 'SYSTEM',
      ),
      // A colleague still open.
      MockAttendanceRow(
        attendanceCode: 'STAR_MOCK_B',
        staffCode: 'STF_B',
        staffName: 'Leo Martins',
        attendanceDate: dateOf(1),
        signedInAtLocal: dayAt(1, 7, 45),
      ),
      // A colleague who is clear.
      MockAttendanceRow(
        attendanceCode: 'STAR_MOCK_C',
        staffCode: 'STF_C',
        staffName: 'Aisha Rahman',
        attendanceDate: dateOf(1),
        signedInAtLocal: dayAt(1, 7, 50),
        signedOutAtLocal: dayAt(1, 17, 2),
        signedOutMethod: 'APP',
      ),
    ];
  }

  // ——————————————————————————————————————————————————————————————
  // Plumbing
  // ——————————————————————————————————————————————————————————————

  Future<void> _tick() async {
    final delay = latency ?? RegConfig.mockLatency;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
  }

  Never _fail(int status, String message, {Map<String, dynamic>? extra}) {
    throw DioException(
      requestOptions: RequestOptions(path: 'mock'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: 'mock'),
        statusCode: status,
        data: <String, dynamic>{
          'success': false,
          'message': message,
          ...?extra,
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  Map<String, dynamic> _ok(Object? data) =>
      <String, dynamic>{'success': true, 'data': data};

  String? _utc(DateTime? local) =>
      local == null ? null : RegTimeZone.toUtcIso(local, zone);

  DateTime? _local(Object? utcIso) =>
      RegTimeZone.schoolLocal((utcIso ?? '').toString(), zone);

  static String _str(Object? v) => (v ?? '').toString().trim();

  static int _int(Object? v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_str(v)) ?? fallback;
  }

  DateTime get _todayLocal {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _nextCode() {
    _seq++;
    return 'SREG_${_seq.toString().padLeft(4, '0')}';
  }

  // ——————————————————————————————————————————————————————————————
  // Detection (§4, §9.1)
  // ——————————————————————————————————————————————————————————————

  /// The unresolved past days for [staffCode], reducing each date to its last
  /// session first (§4) and keeping only rows no human closed.
  List<MockAttendanceRow> _unresolvedFor(String staffCode) {
    _ensureSeeded(staffCode);
    final byDate = <String, MockAttendanceRow>{};
    for (final row in _rows) {
      if (row.staffCode != staffCode) continue;
      if (!row.attendanceDate.isBefore(_todayLocal)) continue; // §4: past only
      final key = RegTimeZone.dateToWire(row.attendanceDate);
      final current = byDate[key];
      // Last session = greatest signed_in_at for that (staff, date).
      if (current == null ||
          row.signedInAtLocal.isAfter(current.signedInAtLocal)) {
        byDate[key] = row;
      }
    }
    return byDate.values.where((r) => r.isUnresolved).toList()
      ..sort((a, b) => a.attendanceDate.compareTo(b.attendanceDate));
  }

  Map<String, dynamic>? _pendingFor(String attendanceCode) {
    for (final r in _requests.values) {
      if (_str(r['attendanceCode']) == attendanceCode &&
          _str(r['status']) == 'PENDING') {
        return r;
      }
    }
    return null;
  }

  Map<String, dynamic>? _anyRequestFor(String attendanceCode) {
    for (final r in _requests.values) {
      if (_str(r['attendanceCode']) == attendanceCode) return r;
    }
    return null;
  }

  Map<String, dynamic> _openSessionJson(MockAttendanceRow row) {
    final pending = _pendingFor(row.attendanceCode);
    return <String, dynamic>{
      'attendanceCode': row.attendanceCode,
      'attendanceDate': RegTimeZone.dateToWire(row.attendanceDate),
      'signedInAt': _utc(row.signedInAtLocal),
      'signedInByCode': 'USR_MOCK_SIGNER',
      // Resolution order (§9.1): the scheduler's own guess if it closed the
      // row, else the school's end time, else the 19:00 cap.
      'suggestedSignOutTime': _utc(
        row.signedOutMethod == 'SYSTEM' && row.signedOutAtLocal != null
            ? row.signedOutAtLocal
            : RegTimePolicy.fallbackCapFor(row.attendanceDate),
      ),
      'classroomCode': row.classroomCode,
      'hasPendingRequest': pending != null,
      'pendingRequestCode': pending == null ? null : _str(pending['code']),
      'staffCode': row.staffCode,
      'staffName': row.staffName,
    };
  }

  // ——————————————————————————————————————————————————————————————
  // §8.7 apply
  // ——————————————————————————————————————————————————————————————

  /// Commits an approved correction onto the attendance row.
  ///
  /// Overwriting `signed_out_method` with `REGULARIZED` is what clears the
  /// gate — a `SYSTEM` row stops matching detection the moment it is applied
  /// (§7.3).
  void _apply(Map<String, dynamic> request, DateTime approvedLocal) {
    final row = rowFor(_str(request['attendanceCode']));
    if (row == null) return;
    row.signedOutAtLocal = approvedLocal;
    row.signedOutMethod = 'REGULARIZED';
    row.regularizationCode = _str(request['code']);
  }

  /// Validates a proposed time against the row it targets (§8.5).
  void _validateAgainstRow(MockAttendanceRow row, DateTime signOutLocal) {
    final error = RegTimePolicy.validateSignOut(
      signOutLocal: signOutLocal,
      attendanceDate: row.attendanceDate,
      signedInAt: row.signedInAtLocal,
    );
    if (error != null) _fail(400, error);
  }

  // ——————————————————————————————————————————————————————————————
  // §9.1 / §9.1b
  // ——————————————————————————————————————————————————————————————

  @override
  Future<Map<String, dynamic>> getOpenSessions({
    required String staffCode,
  }) async {
    await _tick();
    final unresolved = _unresolvedFor(staffCode);
    // §9.1 returns [] rather than 404 when there is nothing open.
    return _ok(unresolved.map(_openSessionJson).toList());
  }

  @override
  Future<Map<String, dynamic>> getOpenSessionsBatch({
    required Map<String, dynamic> body,
  }) async {
    await _tick();
    final codes = (body['staffCodes'] as List? ?? const [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();

    final blocked = <Map<String, dynamic>>[];
    final clear = <String>[];
    for (final code in codes) {
      final unresolved = _unresolvedFor(code);
      // A staff who already raised is not blocked (§8.3) — they may sign in.
      final blocking = unresolved
          .where((r) => _pendingFor(r.attendanceCode) == null)
          .toList();
      if (blocking.isEmpty) {
        clear.add(code);
      } else {
        // At most one entry per (staff, date); the invariant means one day.
        blocked.add(_openSessionJson(blocking.first));
      }
    }
    return _ok(<String, dynamic>{'blocked': blocked, 'clear': clear});
  }

  // ——————————————————————————————————————————————————————————————
  // §9.2 / §9.2b
  // ——————————————————————————————————————————————————————————————

  @override
  Future<Map<String, dynamic>> raise({
    required Map<String, dynamic> body,
  }) async {
    await _tick();
    return _ok(_createOne(body, sharedReason: _str(body['reason'])));
  }

  @override
  Future<Map<String, dynamic>> raiseBatch({
    required Map<String, dynamic> body,
  }) async {
    await _tick();
    // §9.2b is admin-only.
    if (!_actingAsAdmin) _fail(403, 'Only an admin can raise in bulk.');

    final shared = _str(body['reason']);
    final items = (body['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    var applied = 0;
    final skipped = <Map<String, dynamic>>[];
    for (final item in items) {
      final attendanceCode = _str(item['attendanceCode']);
      // Idempotent per item: an existing request is skipped, not an error.
      if (_anyRequestFor(attendanceCode) != null) {
        skipped.add(<String, dynamic>{
          'attendanceCode': attendanceCode,
          'reason': 'already resolved',
        });
        continue;
      }
      _createOne(item, sharedReason: shared);
      applied++;
    }
    return _ok(<String, dynamic>{'applied': applied, 'skipped': skipped});
  }

  /// Shared create path for §9.2 and each §9.2b item.
  Map<String, dynamic> _createOne(
    Map<String, dynamic> body, {
    required String sharedReason,
  }) {
    final attendanceCode = _str(body['attendanceCode']);
    final row = rowFor(attendanceCode);
    if (row == null) _fail(404, 'Attendance record not found.');

    // §8.2 — reason mandatory, trimmed. A per-item value overrides the shared
    // one; either may satisfy the rule.
    final reason = _str(body['reason']).isNotEmpty
        ? _str(body['reason'])
        : sharedReason;
    final reasonError = RegTimePolicy.validateReason(reason);
    if (reasonError != null) _fail(400, reasonError);

    final requestedLocal = _local(body['requestedSignOutTime']);
    if (requestedLocal == null) _fail(400, 'A sign-out time is required.');
    _validateAgainstRow(row, requestedLocal);

    // §8.6 — a repeat raise returns the existing PENDING request rather than
    // creating a duplicate. The client should then offer edit.
    final existing = _pendingFor(attendanceCode);
    if (existing != null) return existing;

    final code = _nextCode();
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    // §8.2b — the role decides, never a request field. Admin-raised is
    // created and approved in the same step; staff-raised lands PENDING.
    final isAdmin = _actingAsAdmin;
    final request = <String, dynamic>{
      'code': code,
      'staffCode': _str(body['staffCode']).isEmpty
          ? row.staffCode
          : _str(body['staffCode']),
      'staffName': row.staffName,
      'schoolCode': row.schoolCode,
      'attendanceCode': attendanceCode,
      'attendanceDate': RegTimeZone.dateToWire(row.attendanceDate),
      'requestedSignOutTime': _utc(requestedLocal),
      'reason': reason.trim(),
      'status': isAdmin ? 'APPROVED' : 'PENDING',
      'raisedByCode': _actingUserCode,
      'method': _str(body['method']).isEmpty
          ? RegConfig.method
          : _str(body['method']),
      'createdAt': nowUtc,
      'updatedAt': null,
      'approvedSignOutTime': isAdmin ? _utc(requestedLocal) : null,
      // §8.2b: approvalByCode == raisedByCode is what marks an auto-approval,
      // now that `auto_approved` is no longer a column (§7.2).
      'approvalByCode': isAdmin ? _actingUserCode : null,
      'approvalByName': isAdmin ? 'You (admin)' : null,
      'approvalAt': isAdmin ? nowUtc : null,
      'approvalNote': null,
    };
    _requests[code] = request;

    if (isAdmin) _apply(request, requestedLocal);
    return request;
  }

  // ——————————————————————————————————————————————————————————————
  // §9.4 edit
  // ——————————————————————————————————————————————————————————————

  @override
  Future<Map<String, dynamic>> edit({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    await _tick();
    final request = _requests[code];
    if (request == null) _fail(404, 'Request not found.');

    // §8.6 / §9.4 — approval is terminal; an edit that races it loses.
    if (_str(request['status']) == 'APPROVED') {
      _fail(409, 'This request was already approved.');
    }

    if (!body.containsKey('requestedSignOutTime') &&
        !body.containsKey('reason')) {
      _fail(400, 'Nothing to update.');
    }

    if (body.containsKey('reason')) {
      final reason = _str(body['reason']);
      // An edit may replace the reason but never clear it (§8.2).
      final reasonError = RegTimePolicy.validateReason(reason);
      if (reasonError != null) _fail(400, reasonError);
      request['reason'] = reason;
    }

    if (body.containsKey('requestedSignOutTime')) {
      final newLocal = _local(body['requestedSignOutTime']);
      if (newLocal == null) _fail(400, 'A sign-out time is required.');
      final row = rowFor(_str(request['attendanceCode']));
      if (row != null) _validateAgainstRow(row, newLocal);
      request['requestedSignOutTime'] = _utc(newLocal);
    }

    // status stays PENDING — the gate remains satisfied throughout, so the
    // staff is never re-blocked by their own correction (§9.4).
    request['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    return _ok(request);
  }

  // ——————————————————————————————————————————————————————————————
  // §9.3 / §9.5 list
  // ——————————————————————————————————————————————————————————————

  @override
  Future<Map<String, dynamic>> list({
    required Map<String, dynamic> query,
  }) async {
    await _tick();
    final staffCode = _str(query['staffCode']);
    final school = _str(query['schoolCode']);
    final status = _str(query['status']);
    final page = _int(query['page'], 0);
    final size = _int(query['size'], RegConfig.inboxPageSize);
    final sort = _str(query['sort']);

    var all = _requests.values.toList();
    if (staffCode.isNotEmpty) {
      all = all.where((r) => _str(r['staffCode']) == staffCode).toList();
    }
    if (school.isNotEmpty) {
      all = all.where((r) => _str(r['schoolCode']) == school).toList();
    }
    // An absent `status` means all — which is what the admin history tab uses.
    if (status.isNotEmpty) {
      all = all.where((r) => _str(r['status']) == status).toList();
    }

    final ascending = sort.endsWith('asc');
    all.sort((a, b) {
      final c = _str(a['createdAt']).compareTo(_str(b['createdAt']));
      return ascending ? c : -c;
    });

    final total = all.length;
    final start = page * size;
    final slice = start >= total
        ? const <Map<String, dynamic>>[]
        : all.sublist(start, (start + size).clamp(0, total));

    // Paginated envelope — the shape whose variance the mappers tolerate.
    return _ok(<String, dynamic>{
      'content': slice,
      'totalElements': total,
      'number': page,
      'size': size,
    });
  }

  // ——————————————————————————————————————————————————————————————
  // §9.6 / §9.7 approve
  // ——————————————————————————————————————————————————————————————

  @override
  Future<Map<String, dynamic>> approve({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    await _tick();
    if (!_actingAsAdmin) _fail(403, 'Only an admin can approve.');

    final request = _requests[code];
    if (request == null) _fail(404, 'Request not found.');

    // §8.6 — approving an already-approved request is a no-op.
    if (_str(request['status']) == 'APPROVED') return _ok(request);

    final modified = _local(body['signOutTime']);
    final requested = _local(request['requestedSignOutTime']);
    final approvedLocal = modified ?? requested;
    if (approvedLocal == null) _fail(400, 'No time to approve.');

    // §8.5 applies to an admin's modified time too.
    if (modified != null) {
      final row = rowFor(_str(request['attendanceCode']));
      if (row != null) _validateAgainstRow(row, modified);
    }

    _decide(request, approvedLocal, note: _str(body['note']));
    return _ok(request);
  }

  @override
  Future<Map<String, dynamic>> approveSelected({
    required Map<String, dynamic> body,
  }) async {
    await _tick();
    if (!_actingAsAdmin) _fail(403, 'Only an admin can approve.');

    final codes = (body['codes'] as List? ?? const [])
        .map(_str)
        .where((s) => s.isNotEmpty)
        .toList();
    if (codes.isEmpty) _fail(400, 'Select at least one request.');

    var approved = 0;
    final skipped = <Map<String, dynamic>>[];
    for (final code in codes) {
      final request = _requests[code];
      if (request == null) {
        skipped.add(<String, dynamic>{'code': code, 'reason': 'not found'});
        continue;
      }
      // §10.3 — snapshot-based: an item another admin already handled is
      // skipped, not an error that fails the batch.
      if (_str(request['status']) == 'APPROVED') {
        skipped
            .add(<String, dynamic>{'code': code, 'reason': 'already decided'});
        continue;
      }
      final requested = _local(request['requestedSignOutTime']);
      if (requested == null) {
        skipped.add(<String, dynamic>{'code': code, 'reason': 'invalid time'});
        continue;
      }
      // Each approved as submitted — modify is the single-approve path.
      _decide(request, requested);
      approved++;
    }
    return _ok(<String, dynamic>{'approved': approved, 'skipped': skipped});
  }

  /// The §8.7 decision + apply, shared by single and bulk approve.
  void _decide(
    Map<String, dynamic> request,
    DateTime approvedLocal, {
    String note = '',
  }) {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    request['status'] = 'APPROVED';
    request['approvedSignOutTime'] = _utc(approvedLocal);
    request['approvalByCode'] = _actingUserCode;
    request['approvalByName'] = 'Mock Admin';
    request['approvalAt'] = nowUtc;
    if (note.trim().isNotEmpty) request['approvalNote'] = note.trim();
    _apply(request, approvedLocal);
  }
}
