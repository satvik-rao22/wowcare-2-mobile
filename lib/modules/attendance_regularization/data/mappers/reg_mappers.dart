import '../../core/config/reg_config.dart';
import '../../core/utils/reg_time_zone.dart';
import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/reg_batch_gate.dart';
import '../../domain/entities/reg_batch_result.dart';
import '../../domain/entities/reg_edit_input.dart';
import '../../domain/entities/reg_page.dart';
import '../../domain/entities/reg_raise_input.dart';
import '../../domain/entities/regularization_request.dart';

/// Wire ⇄ domain translation.
///
/// The API speaks UTC; the UI speaks school-local wall-clock, so every read
/// takes the school [zone]. Payloads carry **no** `timeZone` — the school's
/// attendance config defines its own working day.
abstract final class RegMappers {
  const RegMappers._();

  // —— envelope ——

  static Object? payload(Map<String, dynamic>? body) =>
      body == null ? null : (body.containsKey('data') ? body['data'] : body);

  /// Reads `data.content`, falling back to a bare `data` list.
  static List<Map<String, dynamic>> listOf(Map<String, dynamic>? body) {
    final data = payload(body);
    if (data is List) return _asMaps(data);
    if (data is Map) {
      for (final key in const ['content', 'items', 'results']) {
        if (data[key] is List) return _asMaps(data[key] as List);
      }
    }
    return const [];
  }

  // —— reads ——

  /// One `blocked` entry of the gate response.
  static MissedSignout toMissedSignout(
    Map<String, dynamic> m, {
    required String zone,
  }) {
    final pendingCode = _str(m['pendingRequestCode']);
    return MissedSignout(
      attendanceCode: _str(m['attendanceCode']),
      attendanceDate:
          RegTimeZone.dateOnly(_str(m['attendanceDate'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      signedInAt: RegTimeZone.schoolLocal(_str(m['signedInAt']), zone),
      signedInByCode: _nullable(m['signedInByCode']),
      suggestedSignOutTime: RegTimeZone.schoolLocal(
        _str(m['suggestedSignOutTime']),
        zone,
      ),
      classroomCode: _nullable(m['classroomCode']),
      hasPendingRequest: _bool(m['hasPendingRequest']),
      pendingRequestCode: pendingCode.isEmpty ? null : pendingCode,
      staffCode: _str(m['staffCode']),
      staffName: _str(m['staffName']),
    );
  }

  static RegBatchGate toBatchGate(
    Map<String, dynamic>? body, {
    required String zone,
  }) {
    final data = _mapOf(payload(body));
    if (data == null) return const RegBatchGate.empty();
    final blocked = data['blocked'];
    final clear = data['clear'];
    return RegBatchGate(
      blocked: blocked is List
          ? _asMaps(
              blocked,
            ).map((m) => toMissedSignout(m, zone: zone)).toList(growable: false)
          : const [],
      clear: clear is List
          ? clear.map(_str).where((s) => s.isNotEmpty).toList(growable: false)
          : const [],
    );
  }

  /// [fallbackStaffName] covers a list page where the name lookup failed; the
  /// contract says the code stands in rather than the row rendering blank.
  static RegularizationRequest toRequest(
    Map<String, dynamic> m, {
    required String zone,
    String fallbackStaffName = '',
  }) {
    final staffCode = _str(m['staffCode']);
    final name = _str(m['staffName']);
    final requested = RegTimeZone.schoolLocal(
      _str(m['requestedSignOutTime']),
      zone,
    );
    final approved = RegTimeZone.schoolLocal(
      _str(m['approvedSignOutTime']),
      zone,
    );

    return RegularizationRequest(
      code: _str(m['code']),
      staffCode: staffCode,
      staffName: name.isNotEmpty
          ? name
          : (fallbackStaffName.isNotEmpty ? fallbackStaffName : staffCode),
      attendanceCode: _str(m['attendanceCode']),
      attendanceDate:
          RegTimeZone.dateOnly(_str(m['attendanceDate'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      requestedSignOutTime:
          requested ?? approved ?? DateTime.fromMillisecondsSinceEpoch(0),
      reason: _str(m['reason']),
      status: regStatusFromWire(_str(m['status'])),
      raisedByCode: _str(m['raisedByCode']),
      method: _str(m['method']),
      autoApproved: _bool(m['autoApproved']),
      createdAt:
          RegTimeZone.schoolLocal(_str(m['createdAt']), zone) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: RegTimeZone.schoolLocal(_str(m['updatedAt']), zone),
      approvedSignOutTime: approved,
      approvalByCode: _nullable(m['approvalByCode']),
      approvalByName: _nullable(m['approvalByName']),
      approvalAt: RegTimeZone.schoolLocal(_str(m['approvalAt']), zone),
      approvalNote: _nullable(m['approvalNote']),
    );
  }

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

  static RegPage<RegularizationRequest> toPage(
    Map<String, dynamic>? body, {
    required String zone,
    required int page,
    required int size,
  }) {
    final items = listOf(
      body,
    ).map((m) => toRequest(m, zone: zone)).toList(growable: false);
    final data = _mapOf(payload(body));
    final total = data == null
        ? items.length
        : _int(_first(data, ['totalElements', 'total', 'totalCount']));

    return RegPage<RegularizationRequest>(
      items: items,
      page: data == null ? page : _int(data['page'] ?? page),
      size: data == null ? size : _int(data['size'] ?? size),
      total: total == 0 ? items.length : total,
      // Trust the server's flag; fall back to page arithmetic, and never
      // report more on an empty page or "load more" would loop forever.
      hasMore:
          items.isNotEmpty &&
          (data?['hasNext'] as bool? ?? (page + 1) * size < total),
    );
  }

  static RegBatchResult toBatchResult(Map<String, dynamic>? body) {
    final data = _mapOf(payload(body));
    if (data == null) return const RegBatchResult.empty();
    final skipped = data['skipped'];
    return RegBatchResult(
      applied: _int(_first(data, ['applied', 'approved', 'count'])),
      skipped: skipped is List
          ? _asMaps(skipped)
                .map(
                  (m) => RegSkipped(
                    code: _str(m['code']),
                    attendanceCode: _str(m['attendanceCode']),
                    reason: _str(m['reason']).isEmpty
                        ? 'already decided'
                        : _str(m['reason']),
                  ),
                )
                .toList(growable: false)
          : const <RegSkipped>[],
    );
  }

  // —— writes ——

  /// `{}` checks the caller; `staffCodes` checks a roster.
  static Map<String, dynamic> gateBody(List<String>? staffCodes) =>
      (staffCodes == null || staffCodes.isEmpty)
      ? const <String, dynamic>{}
      : <String, dynamic>{'staffCodes': staffCodes};

  static Map<String, dynamic> raiseBody(
    RegRaiseInput input, {
    required String zone,
    String method = RegConfig.method,
  }) {
    return <String, dynamic>{
      'staffCode': input.staffCode,
      'attendanceCode': input.attendanceCode,
      'attendanceDate': RegTimeZone.dateToWire(input.attendanceDate),
      'requestedSignOutTime': RegTimeZone.toUtcIso(input.signOutLocal, zone),
      'reason': input.reason.trim(),
      'method': method,
    };
  }

  static Map<String, dynamic> raiseBatchBody(
    List<RegRaiseInput> items, {
    required String sharedReason,
    required String zone,
  }) {
    final shared = sharedReason.trim();
    return <String, dynamic>{
      'reason': shared,
      'items': [
        for (final item in items)
          <String, dynamic>{
            'staffCode': item.staffCode,
            'attendanceCode': item.attendanceCode,
            'attendanceDate': RegTimeZone.dateToWire(item.attendanceDate),
            'requestedSignOutTime': RegTimeZone.toUtcIso(
              item.signOutLocal,
              zone,
            ),
            // Only when it differs, so the shared value stays the default.
            if (item.reason.trim().isNotEmpty && item.reason.trim() != shared)
              'reason': item.reason.trim(),
          },
      ],
    };
  }

  /// Only the changed fields; an omitted one keeps its stored value.
  static Map<String, dynamic> editBody(
    RegEditInput input, {
    required String zone,
  }) {
    final body = <String, dynamic>{};
    if (input.signOutLocal != null) {
      body['requestedSignOutTime'] = RegTimeZone.toUtcIso(
        input.signOutLocal!,
        zone,
      );
    }
    final reason = input.reason?.trim();
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    return body;
  }

  /// Omitting `signOutTime` approves as submitted.
  static Map<String, dynamic> approveBody({
    DateTime? signOutLocal,
    String note = '',
    required String zone,
  }) {
    return <String, dynamic>{
      if (signOutLocal != null)
        'signOutTime': RegTimeZone.toUtcIso(signOutLocal, zone),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    };
  }

  static Map<String, dynamic> approveSelectedBody(List<String> codes) =>
      <String, dynamic>{'codes': codes};

  // —— helpers ——

  static List<Map<String, dynamic>> _asMaps(List raw) => raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  static Map<String, dynamic>? _mapOf(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static String _str(Object? v) => (v ?? '').toString().trim();

  static String? _nullable(Object? v) {
    final s = _str(v);
    return s.isEmpty || s == 'null' ? null : s;
  }

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

  static Object? _first(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m[k] != null && _str(m[k]).isNotEmpty) return m[k];
    }
    return null;
  }
}
