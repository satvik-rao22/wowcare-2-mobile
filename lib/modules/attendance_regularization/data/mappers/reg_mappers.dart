import '../../core/config/reg_config.dart';
import '../../core/utils/reg_time_zone.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/reg_batch_gate.dart';
import '../../domain/entities/reg_batch_result.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/entities/reg_page.dart';
import '../../domain/entities/reg_raise_input.dart';
import '../../domain/entities/regularization_request.dart';

/// Wire ⇄ domain translation for every regularization endpoint (spec §9).
///
/// **No DTO layer.** The wire shape is nearly 1:1 with the entities, there is
/// no codegen in this project, and `attendance_v2` already maps raw JSON
/// straight to entities (`overview_mapper`, `day_detail_mapper`). Adding
/// intermediate DTO classes here would be a few hundred lines of pure
/// restatement with nothing to absorb.
///
/// Both directions take an explicit school IANA `zone`: the API speaks UTC,
/// the UI speaks school-local wall-clock (§10.1). The repository resolves the
/// zone once per call and passes it in, so nothing here reaches for ambient
/// state and every function is directly testable.
abstract final class RegMappers {
  const RegMappers._();

  // ——————————————————————————————————————————————————————————————
  // Envelope handling
  // ——————————————————————————————————————————————————————————————

  /// Pulls the `data` payload out of the standard `{success, data}` envelope,
  /// tolerating a response that is already unwrapped.
  static Object? payload(Map<String, dynamic>? body) {
    if (body == null) return null;
    return body.containsKey('data') ? body['data'] : body;
  }

  /// Reads a list of objects out of a response.
  ///
  /// Tolerates both paginated (`data.content`) and flat (`data`) shapes —
  /// which of the two the list endpoints use is still an open question with
  /// backend, and guessing wrong would otherwise mean an empty screen rather
  /// than a loud failure.
  static List<Map<String, dynamic>> listOf(Map<String, dynamic>? body) {
    final data = payload(body);
    if (data is List) return _asMaps(data);
    if (data is Map) {
      for (final key in const ['content', 'items', 'results']) {
        final nested = data[key];
        if (nested is List) return _asMaps(nested);
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> _asMaps(List raw) => raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  static Map<String, dynamic>? _mapOf(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static String _str(Object? v) => (v ?? '').toString().trim();

  static int _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_str(v)) ?? 0;
  }

  static bool _bool(Object? v) {
    if (v is bool) return v;
    final s = _str(v).toLowerCase();
    return s == 'true' || s == '1';
  }

  /// Reads the first present key — the contract renamed several fields
  /// (`requestedSignOutAt` → `requestedSignOutTime`, etc.), so accepting the
  /// current name first and the previous one as a fallback means a
  /// mid-migration backend does not blank the screen.
  static Object? _first(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && _str(v).isNotEmpty) return v;
    }
    return null;
  }

  // ——————————————————————————————————————————————————————————————
  // Incoming — §9.1 / §9.1b
  // ——————————————————————————————————————————————————————————————

  /// One open-session item (§9.1), or one `blocked` entry of the batch gate
  /// (§9.1b) — the batch shape is the same object plus `staffCode`/`staffName`.
  static MissedSignout toMissedSignout(
    Map<String, dynamic> m, {
    required String zone,
  }) {
    final date = RegTimeZone.dateOnly(_str(m['attendanceDate']));
    final pendingCode = _str(_first(m, ['pendingRequestCode', 'requestCode']));
    return MissedSignout(
      attendanceCode: _str(_first(m, ['attendanceCode', 'recordCode'])),
      // A gate item without a date is unusable, but defaulting to "today"
      // would make it silently non-gating (§4 only gates past days), so fall
      // back to the epoch and let it show up as obviously wrong instead.
      attendanceDate: date ?? DateTime.fromMillisecondsSinceEpoch(0),
      signedInAt: RegTimeZone.schoolLocal(_str(m['signedInAt']), zone),
      signedInByCode: _str(m['signedInByCode']).isEmpty
          ? null
          : _str(m['signedInByCode']),
      suggestedSignOutTime: RegTimeZone.schoolLocal(
        _str(_first(m, ['suggestedSignOutTime', 'suggestedSignOutAt'])),
        zone,
      ),
      classroomCode:
          _str(m['classroomCode']).isEmpty ? null : _str(m['classroomCode']),
      hasPendingRequest: _bool(m['hasPendingRequest']),
      pendingRequestCode: pendingCode.isEmpty ? null : pendingCode,
      staffCode: _str(m['staffCode']),
      staffName: _str(m['staffName']),
    );
  }

  /// §9.1b — the `blocked` / `clear` split.
  static RegBatchGate toBatchGate(
    Map<String, dynamic>? body, {
    required String zone,
  }) {
    final data = _mapOf(payload(body));
    if (data == null) return const RegBatchGate.empty();

    final blockedRaw = data['blocked'];
    final clearRaw = data['clear'];
    return RegBatchGate(
      blocked: blockedRaw is List
          ? _asMaps(blockedRaw)
              .map((m) => toMissedSignout(m, zone: zone))
              .toList(growable: false)
          : const [],
      clear: clearRaw is List
          ? clearRaw.map(_str).where((s) => s.isNotEmpty).toList(growable: false)
          : const [],
    );
  }

  // ——————————————————————————————————————————————————————————————
  // Incoming — §7.2 row
  // ——————————————————————————————————————————————————————————————

  /// One `staff_attendance_regularization` row (§7.2).
  ///
  /// [fallbackStaffName] covers the open backend question in §9.5: the inbox
  /// DTO is not documented to include `staffName`, and a blank name in the
  /// admin list is worse than showing the code.
  static RegularizationRequest toRequest(
    Map<String, dynamic> m, {
    required String zone,
    String fallbackStaffName = '',
  }) {
    final staffCode = _str(m['staffCode']);
    final name = _str(m['staffName']);
    final date = RegTimeZone.dateOnly(_str(m['attendanceDate']));

    final requested = RegTimeZone.schoolLocal(
      _str(_first(m, ['requestedSignOutTime', 'requestedSignOutAt'])),
      zone,
    );
    final approved = RegTimeZone.schoolLocal(
      _str(_first(m, [
        'approvedSignOutTime',
        'appliedSignOutAt',
        'approvedSignOutAt',
      ])),
      zone,
    );

    return RegularizationRequest(
      code: _str(m['code']),
      staffCode: staffCode,
      staffName: name.isNotEmpty
          ? name
          : (fallbackStaffName.isNotEmpty ? fallbackStaffName : staffCode),
      attendanceCode: _str(_first(m, ['attendanceCode', 'targetRecordCode'])),
      attendanceDate: date ?? DateTime.fromMillisecondsSinceEpoch(0),
      // `requested_sign_out_time` is non-null in the schema; if it is missing
      // the row is malformed, and falling back to the approved time (else the
      // epoch) keeps the list rendering instead of throwing mid-page.
      requestedSignOutTime:
          requested ?? approved ?? DateTime.fromMillisecondsSinceEpoch(0),
      reason: _str(m['reason']),
      status: regStatusFromWire(_str(m['status'])),
      raisedByCode: _str(_first(m, ['raisedByCode', 'createdByCode'])),
      createdAt: RegTimeZone.schoolLocal(_str(m['createdAt']), zone) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: RegTimeZone.schoolLocal(_str(m['updatedAt']), zone),
      approvedSignOutTime: approved,
      approvalByCode: _str(_first(m, ['approvalByCode', 'decidedByCode']))
              .isEmpty
          ? null
          : _str(_first(m, ['approvalByCode', 'decidedByCode'])),
      approvalByName: _str(_first(m, ['approvalByName', 'decidedByName']))
              .isEmpty
          ? null
          : _str(_first(m, ['approvalByName', 'decidedByName'])),
      approvalAt: RegTimeZone.schoolLocal(
        _str(_first(m, ['approvalAt', 'decidedAt'])),
        zone,
      ),
      approvalNote: _str(_first(m, ['approvalNote', 'decisionNote'])).isEmpty
          ? null
          : _str(_first(m, ['approvalNote', 'decisionNote'])),
    );
  }

  /// A single request response (§9.2, §9.4, §9.6).
  static RegularizationRequest toSingleRequest(
    Map<String, dynamic>? body, {
    required String zone,
  }) {
    final data = _mapOf(payload(body));
    if (data == null) {
      throw const FormatException('Expected a regularization request object');
    }
    return toRequest(data, zone: zone);
  }

  // ——————————————————————————————————————————————————————————————
  // Incoming — pagination (§9.3, §9.5)
  // ——————————————————————————————————————————————————————————————

  /// One page of requests.
  ///
  /// `total` is read from whichever of the common Spring keys is present;
  /// when none is, it falls back to what has been seen so far so that
  /// [RegPage.hasMore] stops rather than looping forever.
  static RegPage<RegularizationRequest> toPage(
    Map<String, dynamic>? body, {
    required String zone,
    required int page,
    required int size,
  }) {
    final items = listOf(body)
        .map((m) => toRequest(m, zone: zone))
        .toList(growable: false);

    final data = _mapOf(payload(body));
    final total = data == null
        ? items.length
        : _int(_first(data, [
              'totalElements',
              'total',
              'totalCount',
              'count',
            ]) ??
            (page * size + items.length));

    return RegPage<RegularizationRequest>(
      items: items,
      page: page,
      size: size,
      total: total == 0 ? items.length : total,
    );
  }

  // ——————————————————————————————————————————————————————————————
  // Incoming — batch results (§9.2b, §9.7)
  // ——————————————————————————————————————————————————————————————

  /// `{applied|approved, skipped[]}` — the same shape from both batch
  /// endpoints, so one mapper serves both.
  static RegBatchResult toBatchResult(Map<String, dynamic>? body) {
    final data = _mapOf(payload(body));
    if (data == null) return const RegBatchResult.empty();

    final count = _int(_first(data, ['applied', 'approved', 'count']));
    final skippedRaw = data['skipped'];
    final skipped = skippedRaw is List
        ? _asMaps(skippedRaw)
            .map((m) => RegSkipped(
                  key: _str(_first(m, ['code', 'attendanceCode', 'key'])),
                  reason: _str(m['reason']).isEmpty
                      ? 'already decided'
                      : _str(m['reason']),
                ))
            .toList(growable: false)
        : const <RegSkipped>[];

    return RegBatchResult(count: count, skipped: skipped);
  }

  // ——————————————————————————————————————————————————————————————
  // Outgoing — request bodies
  // ——————————————————————————————————————————————————————————————

  /// §9.2 raise body. No `confirmedSuggestedTime`: the server no longer tracks
  /// whether the suggestion was kept (§7.5), and `reason` is required either
  /// way (§8.2).
  static Map<String, dynamic> raiseBody(
    RegRaiseInput input, {
    required String zone,
  }) {
    return <String, dynamic>{
      'staffCode': input.staffCode,
      'attendanceDate': RegTimeZone.dateToWire(input.attendanceDate),
      'attendanceCode': input.attendanceCode,
      'requestedSignOutTime':
          RegTimeZone.toUtcIso(input.signOutLocal, zone),
      'reason': input.reason.trim(),
      'method': RegConfig.method,
      'timeZone': RegTimeZone.resolveZone(zone),
    };
  }

  /// §9.2b batch raise body. The shared `reason` covers every item; an item
  /// carrying its own overrides it.
  static Map<String, dynamic> raiseBatchBody(
    List<RegRaiseInput> items, {
    required String sharedReason,
    required String zone,
  }) {
    final shared = sharedReason.trim();
    return <String, dynamic>{
      'timeZone': RegTimeZone.resolveZone(zone),
      'reason': shared,
      'method': RegConfig.method,
      'items': [
        for (final item in items)
          <String, dynamic>{
            'staffCode': item.staffCode,
            'attendanceCode': item.attendanceCode,
            'attendanceDate': RegTimeZone.dateToWire(item.attendanceDate),
            'requestedSignOutTime':
                RegTimeZone.toUtcIso(item.signOutLocal, zone),
            // Only send a per-item reason when it actually differs, so the
            // payload stays readable and the shared value remains the default.
            if (item.reason.trim().isNotEmpty &&
                item.reason.trim() != shared)
              'reason': item.reason.trim(),
          },
      ],
    };
  }

  /// §9.4 edit body. Only the fields being changed are sent — an omitted field
  /// leaves the stored value untouched. `timeZone` goes only with a time.
  static Map<String, dynamic> editBody(
    RegEditInput input, {
    required String zone,
  }) {
    final body = <String, dynamic>{};
    if (input.signOutLocal != null) {
      body['requestedSignOutTime'] =
          RegTimeZone.toUtcIso(input.signOutLocal!, zone);
      body['timeZone'] = RegTimeZone.resolveZone(zone);
    }
    final reason = input.reason?.trim();
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    return body;
  }

  /// §9.6 approve body. Omitting `signOutTime` approves **as submitted**;
  /// supplying it approves with a modification.
  static Map<String, dynamic> approveBody({
    DateTime? signOutLocal,
    String note = '',
    required String zone,
  }) {
    final body = <String, dynamic>{
      'timeZone': RegTimeZone.resolveZone(zone),
    };
    if (signOutLocal != null) {
      body['signOutTime'] = RegTimeZone.toUtcIso(signOutLocal, zone);
    }
    if (note.trim().isNotEmpty) {
      body['note'] = note.trim();
    }
    return body;
  }

  /// §9.7 bulk approve body. `codes` is required — there is deliberately no
  /// "approve all pending".
  static Map<String, dynamic> approveSelectedBody({
    required String schoolCode,
    required List<String> codes,
  }) {
    return <String, dynamic>{
      'schoolCode': schoolCode,
      'codes': codes,
    };
  }

  /// §9.1b batch gate body.
  static Map<String, dynamic> batchGateBody(List<String> staffCodes) =>
      <String, dynamic>{'staffCodes': staffCodes};
}
