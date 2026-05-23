import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/shared/common/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/api_error_handler.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/guardian_code_resolver.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_detail.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/entities/activity_type_details.dart';
import '../../../../../domain/features/activity/usecases/approve_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/guardian_parent_signature_usecase.dart';
import '../../../../../domain/features/activity/usecases/reject_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../../../../domain/features/activity/repositories/activity_repository.dart';
import '../../../../../domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import '../../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../../shared/services/image_upload/image_upload_service.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_toggle.dart';
import '../../widgets/activity_edit_student_scope_checkboxes.dart';
import '../../widgets/activity_student_display_tile.dart';
import '../../utils/activity_description_limits.dart';
import '../../utils/activity_selected_date_prefill.dart';
import '../utils/activity_attendance_window_validator.dart';
import '../../utils/activity_school_time.dart';
import '../../utils/activity_staff_display.dart';
import '../../utils/activity_patch_attachments.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../activity_daily_tab.dart';
import '../widgets/activity_admin_approve_reject_bar.dart';

/// Same rules as `rolesJsonIndicatesGuardianLogin` in `login_persona_util.dart`
/// (defined here so hot restart always sees the symbol).
bool incidentRolesJsonIndicatesGuardianLogin(String rolesJson) {
  final raw = rolesJson.trim();
  if (raw.isEmpty) return false;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.any((r) {
        if (r is! Map) return false;
        final role = (r['role'] ?? r['Role'] ?? '').toString().toUpperCase();
        return role.contains('GUARDIAN') || role.contains('PARENT');
      });
    }
  } catch (_) {}
  final u = raw.toUpperCase();
  return u.contains('GUARDIAN') || u.contains('PARENT');
}

class IncidentActivityScreen extends StatefulWidget {
  const IncidentActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData,
    this.readOnly = false,
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  final bool readOnly;

  @override
  State<IncidentActivityScreen> createState() => _IncidentActivityScreenState();
}

class _IncidentActivityScreenState extends State<IncidentActivityScreen> {
  bool get _layoutAsEdit => widget.isEdit || widget.readOnly;
  bool get _canInteract => !widget.readOnly;
  bool get _isAdminDesignation => const {
        'SCHOOL_ADMIN',
        'ORGANIZATION_ADMIN',
        'DIRECTOR',
        'ADMIN',
        'ASSISTANT_DIRECTOR',
        'OWNER',
      }.contains(_staffType.trim().toUpperCase());
  bool get _showRequireAdminApprovalToggle =>
      !_isAdminDesignation && !widget.readOnly;

  /// Incident create: admins only need one "Click to sign" (admin param); avoids
  /// duplicating Staff Present + Admin Present. Edit/read still uses both blocks when needed.
  bool get _mergeAdminSignatureIntoStaffPresent =>
      !_layoutAsEdit && _isAdminDesignation && !widget.readOnly;

  List<Map<String, dynamic>> _selectedStudentsData = [];
  List<String> _selectedStudents = [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addNotesController = TextEditingController();
  bool _firstAidGiven = false;
  bool _isSigned = false;

  DateTime? _activityDate;
  TimeOfDay? _activityTime;
  String? _activityTypeCode;
  String _staffName = '';
  final Map<String, String> _staffDisplayNameByCode = {};
  String _staffType = '';
  bool _requireAdminApproval = true;
  String? _staffCode;
  String? _schoolCode;
  String? _organizationCode;
  bool _isSubmitting = false;
  bool _isAcknowledging = false;
  bool _isApprovingOrRejecting = false;
  bool _isSavingBeforeApprove = false;
  bool _lastUpdateSucceeded = false;
  bool _isAdminSigned = false;
  bool _adminSignedThisSession = false;
  bool _isParentSigned = false;
  String _staffPresentRawValue = '';
  String _staffSignerRawValue = '';
  String _adminSignerRawValue = '';
  String _parentSignerRawValue = '';
  final Map<String, String> _guardianNameByCode = {};
  bool _loadingActivityDetail = false;
  bool _isGuardianPersona = false;
  bool _hasGuardianAcknowledgedLocally = false;
  /// Logged-in guardian record code + display label for Parent Present when API omits valueText.
  String _loggedInGuardianCode = '';
  String _loggedInParentPresentLabel = '';
  ActivityItem? _liveActivity;
  final Set<int> _scopedEditStudentIndices = {};
  List<Map<String, dynamic>> _detailAttachmentRows = [];
  bool _isUploadingMedia = false;
  int _uploadProgressPercent = 0;
  int _uploadCompletedCount = 0;
  int _uploadTotalCount = 0;
  List<File> _newPhotos = [];
  final Map<String, String> _uploadedAssetCodeByPath = {};
  String? _lastUploadContextKey;
  List<String> _remainingExistingPhotoUrls = [];

  bool? _pickFirstAidGivenFromActivityDetail(dynamic detail) {
    bool? parseBool(dynamic raw) {
      if (raw is bool) return raw;
      if (raw == null) return null;
      final text = raw.toString().trim().toLowerCase();
      if (text.isEmpty) return null;
      if (text == 'true' || text == 'yes' || text == 'y' || text == '1') return true;
      if (text == 'false' || text == 'no' || text == 'n' || text == '0') return false;
      return null;
    }

    try {
      final values = (detail?.parameterValues ?? const <dynamic>[]) as List;
      for (final p in values) {
        if (p is! Map) continue;
        final pName = (p['parameterName'] ?? '').toString().trim().toLowerCase();
        if (!(pName.contains('first') && pName.contains('aid'))) continue;

        for (final key in const <String>[
          'valueBool',
          'valueBoolean',
          'value',
          'valueText',
          'selectedOptionLabel',
          'selectedOptionCode',
        ]) {
          final parsed = parseBool(p[key]);
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {
      // Best-effort parsing; fall back to existing state.
    }
    return null;
  }

  int get _uploadedPhotoCount => _newPhotos
      .where((f) => _uploadedAssetCodeByPath.containsKey(f.path))
      .length;

  late final GetClassroomActivitySettingsUseCase _getActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final GuardianParentSignatureUseCase _guardianParentSignatureUseCase;
  late final CreateActivityUseCase _createActivityUseCase;
  late final UpdateActivityUseCase _updateActivityUseCase;
  late final ApproveActivityUseCase _approveActivityUseCase;
  late final RejectActivityUseCase _rejectActivityUseCase;
  late final ImageUploadService _imageUploadService;
  late final GetGuardianNameCodeMapForSchoolUseCase
      _getGuardianNameCodeMapForSchoolUseCase;

  ActivityItem get _effectiveActivity => _liveActivity ?? widget.activityData!;
  bool _isAdminApprovalRequired(ActivityItem activity) {
    final status = (activity.approvalStatus ?? '').trim().toUpperCase();
    return status.isNotEmpty && status != 'NOT_REQUIRED';
  }
  String get _approvalStatus => (_effectiveActivity.approvalStatus ?? '').trim().toUpperCase();
  bool get _isAcknowledged =>
      _hasGuardianAcknowledgedLocally || _approvalStatus == 'ACKNOWLEDGED';
  bool get _hasParentSignedForAction => _isAcknowledged || _isParentSigned;

  bool get _showGuardianAcknowledgeButton {
    if (!widget.readOnly || !_isGuardianPersona) return false;
    final code = (_effectiveActivity.activityCode ?? '').trim();
    if (code.isEmpty) return false;
    return _approvalStatus == 'PARENT_ACKNOWLEDGEMENT_PENDING' || _isAcknowledged;
  }

  Future<String> _resolveParentSignerCode() async {
    final storage = serviceLocator<StorageService>();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
    if (!incidentRolesJsonIndicatesGuardianLogin(rolesRaw)) {
      return '';
    }
    var guardianCode =
        (await refreshGuardianProfileSnapshotForLoggedInUser()).trim();
    if (guardianCode.isEmpty) {
      guardianCode = (await storage.getString(StorageKeys.guardianCode) ?? '').trim();
    }
    return guardianCode;
  }

  /// Logged-in guardian `GUA_…`: storage updated by guardian profile snapshot refresh.
  Future<String> _resolveGuardianCodeForIncidentPayload() async {
    var gc = _loggedInGuardianCode.trim();
    if (gc.isEmpty) {
      gc = (await serviceLocator<StorageService>()
                  .getString(StorageKeys.guardianCode) ??
              '')
          .trim();
    }
    if (gc.isEmpty) {
      gc = (await refreshGuardianProfileSnapshotForLoggedInUser()).trim();
    }
    return gc;
  }

  /// Rewrite parent-sign API text so it always carries `::<base64 utf8 guardianCode>`
  /// when [guardianCode] is known (fixes bare codes, plain names, or legacy payloads).
  String _canonicalGuardianIncidentSignStorage({
    required String raw,
    required String guardianCode,
  }) {
    final g = guardianCode.trim();
    final r = raw.trim();
    if (r.isEmpty || g.isEmpty) return r;

    if (_incidentStoredPayloadEncodesRecordCode(r, g)) return r;

    final trimmedProfile = _loggedInParentPresentLabel.trim();
    final prefix = trimmedProfile.isNotEmpty ? trimmedProfile : g;
    return _buildIncidentSignaturePayload(
      prefixForStorage: prefix,
      signingRecordCode: g,
    );
  }

  /// `GET /api/v2/activities/{code}` for all personas (OpenAPI grouped card by code).
  Future<ActivityDetail> _getActivityDetailRespectingPersona(String code) async {
    final storage = serviceLocator<StorageService>();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
    final isGuardian = incidentRolesJsonIndicatesGuardianLogin(rolesRaw);
    if (mounted) {
      setState(() => _isGuardianPersona = isGuardian);
    }
    return serviceLocator<ActivityRepository>().getActivity(code: code);
  }

  Future<void> _resolveLoggedInGuardianPresentLabel() async {
    final storage = serviceLocator<StorageService>();
    var school = (_schoolCode ?? '').trim();
    if (school.isEmpty) {
      school = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    }
    if (school.isEmpty) {
      if (mounted) {
        setState(() {
          _loggedInGuardianCode = '';
          _loggedInParentPresentLabel = '';
        });
      }
      return;
    }
    final code = (await refreshGuardianProfileSnapshotForLoggedInUser()).trim();
    if (!mounted) return;
    if (code.isEmpty) {
      setState(() {
        _loggedInGuardianCode = '';
        _loggedInParentPresentLabel = '';
      });
      return;
    }
    final labelRaw = await readCachedGuardianProfileDisplayLine();
    final label = (labelRaw ?? '').trim();
    if (!mounted) return;
    setState(() {
      _loggedInGuardianCode = code;
      _loggedInParentPresentLabel = label.isNotEmpty ? label : code;
    });
  }

  Future<void> _resolveLoggedInGuardianPresentIfNeeded() async {
    final storage = serviceLocator<StorageService>();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
    if (!incidentRolesJsonIndicatesGuardianLogin(rolesRaw)) return;
    await _resolveLoggedInGuardianPresentLabel();
  }

  /// Parent "Click to sign" raw from activity detail (skips bare true/false placeholders).
  /// [parentSignParameter] comes from activity-type metadata ([parameterName] as API returns it).
  String _extractParentSignRawFromParameterValues(
    List<Map<String, dynamic>> values, {
    ActivityTypeParameter? parentSignParameter,
  }) {
    if (parentSignParameter == null) return '';
    for (final p in values) {
      if (!_parameterValueMatchesIncidentSchema(p, parentSignParameter)) {
        continue;
      }
      final raw = (p['valueText'] ?? p['value'] ?? '').toString().trim();
      if (raw.isEmpty) continue;
      final lower = raw.toLowerCase();
      if (lower == 'true' || lower == 'false') continue;
      return raw;
    }
    return '';
  }

  /// Match a feed/detail [parameterValues] row to schema by [ActivityTypeParameter.parameterName]
  /// (trim; allow case-only mismatch between detail row and type definition).
  bool _parameterValueMatchesIncidentSchema(
    Map<String, dynamic> pv,
    ActivityTypeParameter? schema,
  ) {
    if (schema == null) return false;
    final pvName = (pv['parameterName'] ?? '').toString().trim();
    final schemaName = schema.parameterName.trim();
    if (pvName.isEmpty || schemaName.isEmpty) return false;
    if (pvName == schemaName) return true;
    return pvName.toLowerCase() == schemaName.toLowerCase();
  }

  /// Same resolution path as guardian labels; prefers [fallback] for technical
  /// guardian record ids when school map has not warmed yet.
  bool _looksLikeGuardianTechnicalId(String signerToken) {
    final u = signerToken.trim().toUpperCase();
    return u.startsWith('GRD_') ||
        u.startsWith('GUA_') ||
        u.startsWith('GUARDIAN_');
  }

  _IncidentSignaturePayload _parseIncidentSignaturePayload(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const _IncidentSignaturePayload(
        signerName: '',
        encodedName: '',
      );
    }
    final parts = value.split('::');
    if (parts.length >= 2) {
      final signerName = parts.first.trim();
      final encodedName = parts.sublist(1).join('::').trim();
      var decodedName = '';
      if (encodedName.isNotEmpty) {
        try {
          decodedName = utf8.decode(base64.decode(encodedName)).trim();
        } catch (_) {
          decodedName = '';
        }
      }
      return _IncidentSignaturePayload(
        signerName: signerName.isNotEmpty ? signerName : decodedName,
        encodedName: encodedName,
      );
    }
    return _IncidentSignaturePayload(signerName: value, encodedName: '');
  }

  /// `{prefixForStorage}::{base64Utf8(signingRecordCode)}` — the encoded segment is
  /// always the canonical **staff code** (`STF_…`) or **guardian record code**, not names.
  String _buildIncidentSignaturePayload({
    required String prefixForStorage,
    required String signingRecordCode,
  }) {
    final prefix = prefixForStorage.trim();
    final code = signingRecordCode.trim();
    if (code.isEmpty) return prefix.isNotEmpty ? prefix : '';
    final encoded = base64Encode(utf8.encode(code));
    if (prefix.isEmpty) return '$code::$encoded';
    return '$prefix::$encoded';
  }

  /// True when [raw]'s trailing segment base64-decodes to [signingRecordCode].
  bool _incidentStoredPayloadEncodesRecordCode(
    String raw,
    String signingRecordCode,
  ) {
    final trimmed = raw.trim();
    final rec = signingRecordCode.trim();
    if (trimmed.isEmpty || rec.isEmpty) return false;
    final p = _parseIncidentSignaturePayload(trimmed);
    if (p.encodedName.isEmpty) return false;
    try {
      final dec = utf8.decode(base64.decode(p.encodedName)).trim();
      return dec == rec;
    } catch (_) {
      return false;
    }
  }

  /// Signing record code: technical prefix before `::`, otherwise the UTF-8
  /// payload of the base64 suffix (`Name::base64(GUA_BCD…)` from API flows).
  String _inferIncidentSigningRecordCodeFromRaw(String raw) {
    final parsed = _parseIncidentSignaturePayload(raw.trim());
    final v = parsed.signerName.trim();
    if (_looksLikeStaffCode(v)) return v;
    if (_looksLikeGuardianTechnicalId(v)) return v;

    final enc = parsed.encodedName.trim();
    if (enc.isEmpty) return '';
    try {
      final dec = utf8.decode(base64.decode(enc)).trim();
      if (dec.isEmpty) return '';
      if (_looksLikeStaffCode(dec)) return dec;
      if (_looksLikeGuardianTechnicalId(dec)) return dec;
    } catch (_) {}
    return '';
  }

  /// Fingerprint for "Signature-ID" — corresponds to base64(signingRecordCode).
  /// Prefers [.encodedName] when present on [rawStoredValue].
  String _incidentSignatureEncodedFingerprint({
    required String rawStoredValue,
    required String signingRecordCode,
  }) {
    final parsed = _parseIncidentSignaturePayload(rawStoredValue.trim());
    final encoded = parsed.encodedName.trim();
    if (encoded.isNotEmpty) return encoded;
    final code = signingRecordCode.trim().isNotEmpty
        ? signingRecordCode.trim()
        : _inferIncidentSigningRecordCodeFromRaw(rawStoredValue.trim());
    if (code.isEmpty) return '';
    try {
      return base64Encode(utf8.encode(code));
    } catch (_) {
      return '';
    }
  }

  String _ensureIncidentSignaturePayload({
    required String rawValue,
    required String fallbackDisplayName,
    required String signingRecordCode,
  }) {
    final raw = rawValue.trim();
    var code = signingRecordCode.trim();
    if (code.isEmpty) code = _inferIncidentSigningRecordCodeFromRaw(raw);
    if (code.isEmpty) return '';
    if (_incidentStoredPayloadEncodesRecordCode(raw, code)) return raw;


    final display = _displaySignerLabel(raw, fallback: fallbackDisplayName).trim();
    final prefix =
        display.isNotEmpty ? display : code;

    return _buildIncidentSignaturePayload(
      prefixForStorage: prefix,
      signingRecordCode: code,
    );
  }

  void _debugIncidentParameterValues(
    String source,
    List<Map<String, dynamic>> parameterValues,
  ) {
    debugPrint(
      '[Incident][$source] parameterValues=${jsonEncode(parameterValues)}',
    );
  }

  bool _looksLikeStaffCode(String value) {
    final signature = _parseIncidentSignaturePayload(value);
    final v = signature.signerName.toUpperCase();
    return v.startsWith('STF_') || v.startsWith('STAFF_');
  }

  Future<void> _primeStaffDisplayNamesFromCodes(Iterable<String> rawCodes) async {
    final codes = rawCodes
        .map((e) => _parseIncidentSignaturePayload(e).signerName)
        .where((e) => e.isNotEmpty && _looksLikeStaffCode(e))
        .toSet()
        .toList();
    if (codes.isEmpty) return;
    final repo = serviceLocator<StaffRepository>();
    await Future.wait(
      codes.map((code) async {
        if (_staffDisplayNameByCode.containsKey(code)) return;
        try {
          final profile = await repo.getStaffProfile(staffCode: code);
          final full = profile.fullName.trim();
          final composed = '${profile.firstName} ${profile.lastName}'.trim();
          final resolved = full.isNotEmpty ? full : composed;
          if (resolved.isNotEmpty) {
            _staffDisplayNameByCode[code] = resolved;
          }
        } catch (_) {}
      }),
    );
  }

  String _displayNameForSignerRaw(String raw, {String fallback = ''}) {
    final signature = _parseIncidentSignaturePayload(raw);
    final v = signature.signerName;
    if (v.isEmpty) return fallback;
    if (_looksLikeStaffCode(v)) {
      final mapped = _staffDisplayNameByCode[v];
      if (mapped != null && mapped.trim().isNotEmpty) return mapped.trim();
    }
    return v;
  }

  String _displaySignerLabel(String raw, {String fallback = ''}) {
    final signature = _parseIncidentSignaturePayload(raw);
    final v = signature.signerName;
    if (v.isEmpty) return fallback;
    if (_looksLikeStaffCode(v)) {
      final name = _displayNameForSignerRaw(v, fallback: '');
      if (name.trim().isNotEmpty) return name.trim();
      return fallback;
    }
    final guardianMapped = _guardianNameByCode[v];
    if (guardianMapped != null && guardianMapped.trim().isNotEmpty) {
      return guardianMapped.trim();
    }
    // Mirror guardian helper: show contextual fallback instead of opaque ids.
    if (fallback.trim().isNotEmpty &&
        _looksLikeGuardianTechnicalId(v) &&
        v.trim() != fallback.trim()) {
      return fallback.trim();
    }
    return v;
  }

  /// Fallback display for parent payloads (approve/reject) when parsing raw signer.
  String _parentIncidentSignatureFallbackDisplay() {
    final a = _loggedInParentPresentLabel.trim();
    if (a.isNotEmpty) return a;
    final b = _loggedInGuardianCode.trim();
    return b;
  }

  Future<void> _primeGuardianNamesFromCodes(Iterable<String> codes) async {
    // Needed for rendering "Parent Present" in view-only mode for any persona
    // (guardian/staff/admin). Do not gate this by _isGuardianPersona.
    var school = (_schoolCode ?? '').trim();
    if (school.isEmpty) {
      final storage = serviceLocator<StorageService>();
      school = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    }
    if (school.isEmpty) return;
    final wanted = codes
        .map((e) => _parseIncidentSignaturePayload(e).signerName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (wanted.isEmpty) return;
    if (wanted.every(_guardianNameByCode.containsKey)) return;
    try {
      final nameToCode = await _getGuardianNameCodeMapForSchoolUseCase(
        schoolCode: school,
      );
      if (!mounted) return;
      _guardianNameByCode
        ..clear();
      for (final entry in nameToCode.entries) {
        final name = entry.key.trim();
        final code = entry.value.trim();
        if (name.isNotEmpty && code.isNotEmpty) {
          _guardianNameByCode[code] = name;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Non-blocking; fallback to showing code.
    }
  }

  List<Map<String, dynamic>> _incidentSignerParameterValuesForPatch({
    required List<ActivityTypeParameter> parameters,
    required String staffPresentCode,
    String? staffSignerCode,
    String? adminSignerCode,
    String? parentSignerCode,
  }) {
    final staffPresentParamCode = _findIncidentParamCodeByName(
      parameters,
      const ['Staff Present'],
      contains: const ['staff present'],
    );
    final staffSignParamCode = _findIncidentParamCodeByName(
      parameters,
      const ['Click to Sign - Staff'],
      contains: const ['click to sign - staff'],
    );
    final adminSignParamCode = _findIncidentParamCodeByName(
      parameters,
      const ['Click to Sign - Admin'],
      contains: const ['click to sign - admin'],
    );
    final parentSignParamCode = _findIncidentParamCodeByName(
      parameters,
      const ['Click to Sign - Parent'],
      contains: const ['click to sign - parent'],
    );
    return <Map<String, dynamic>>[
      if (staffPresentParamCode != null &&
          staffPresentParamCode.trim().isNotEmpty &&
          staffPresentCode.trim().isNotEmpty)
        {'parameterCode': staffPresentParamCode.trim(), 'value': staffPresentCode.trim()},
      if (staffSignParamCode != null && staffSignParamCode.trim().isNotEmpty)
        {'parameterCode': staffSignParamCode.trim(), 'value': (staffSignerCode ?? '').trim()},
      if (adminSignParamCode != null && adminSignParamCode.trim().isNotEmpty)
        {'parameterCode': adminSignParamCode.trim(), 'value': (adminSignerCode ?? '').trim()},
      if (parentSignParamCode != null && parentSignParamCode.trim().isNotEmpty)
        {'parameterCode': parentSignParamCode.trim(), 'value': (parentSignerCode ?? '').trim()},
    ];
  }

  List<Map<String, dynamic>> _scopedStudentsForCreate() {
    if (_selectedStudentsData.length <= 1 || _scopedEditStudentIndices.isEmpty) {
      return List<Map<String, dynamic>>.from(_selectedStudentsData);
    }
    final out = <Map<String, dynamic>>[];
    for (final i in _scopedEditStudentIndices) {
      if (i >= 0 && i < _selectedStudentsData.length) {
        out.add(_selectedStudentsData[i]);
      }
    }
    return out;
  }

  ActivityTypeParameter? _findFirstAidParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      final dt = (p.dataType ?? '').toUpperCase();
      if (dt == 'BOOLEAN' && n.contains('first') && n.contains('aid')) {
        return p;
      }
    }
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('first') && n.contains('aid')) return p;
    }
    return null;
  }

  /// Locate a parameter on the activity type; [exactNames]/[contains] are only for discovery.
  /// Comparison to [parameterValues] rows uses [ActivityTypeParameter.parameterName] as returned by the API.
  ActivityTypeParameter? _findIncidentSchemaParameter(
    List<ActivityTypeParameter> parameters,
    List<String> exactNames, {
    List<String> contains = const <String>[],
  }) {
    for (final p in parameters) {
      final n = p.parameterName.trim().toLowerCase();
      if (exactNames.any((name) => n == name.trim().toLowerCase())) {
        return p;
      }
    }
    for (final part in contains) {
      final target = part.trim().toLowerCase();
      if (target.isEmpty) continue;
      for (final p in parameters) {
        final n = p.parameterName.trim().toLowerCase();
        if (n.contains(target)) {
          return p;
        }
      }
    }
    return null;
  }

  String? _findIncidentParamCodeByName(
    List<ActivityTypeParameter> parameters,
    List<String> exactNames, {
    List<String> contains = const <String>[],
  }) {
    final p = _findIncidentSchemaParameter(
      parameters,
      exactNames,
      contains: contains,
    );
    final c = p?.code.trim();
    if (c == null || c.isEmpty) return null;
    return c;
  }

  /// Dropdown-style parameters must use [selectedOptionCode]; plain BOOLEAN
  /// uses JSON [value] (bool). Display strings like "Yes"/"No" are rejected.
  Map<String, dynamic>? _firstAidParameterEntry(
    ActivityTypeParameter param,
    bool given,
  ) {
    final pc = param.code.trim();
    if (pc.isEmpty) return null;

    String? optionApiCode(ActivityTypeParameterOption o) {
      final c = (o.optionCode ?? o.code).trim();
      return c.isEmpty ? null : c;
    }

    final sorted = List<ActivityTypeParameterOption>.from(param.options)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    if (sorted.isNotEmpty) {
      ActivityTypeParameterOption? byExactLabel(bool affirmative) {
        for (final o in sorted) {
          final label = (o.optionLabel ?? '').toLowerCase().trim();
          if (affirmative) {
            if (label == 'yes' ||
                label == 'true' ||
                label == 'y' ||
                label == '1') {
              return o;
            }
          } else {
            if (label == 'no' ||
                label == 'false' ||
                label == 'n' ||
                label == '0') {
              return o;
            }
          }
        }
        return null;
      }

      ActivityTypeParameterOption? byFuzzyLabel(bool affirmative) {
        for (final o in sorted) {
          final label = (o.optionLabel ?? '').toLowerCase().trim();
          if (affirmative) {
            if (label.contains('yes') || label.contains('administered')) {
              return o;
            }
          } else if (label.contains('no') || label.contains('not')) {
            return o;
          }
        }
        return null;
      }

      final pick = given
          ? (byExactLabel(true) ?? byFuzzyLabel(true))
          : (byExactLabel(false) ?? byFuzzyLabel(false));
      if (pick != null) {
        final oc = optionApiCode(pick);
        if (oc != null) {
          return {'parameterCode': pc, 'selectedOptionCode': oc};
        }
      }
      if (sorted.length == 2) {
        final o = sorted[given ? 1 : 0];
        final oc = optionApiCode(o);
        if (oc != null) {
          return {'parameterCode': pc, 'selectedOptionCode': oc};
        }
      }
    }

    final dt = (param.dataType ?? '').toUpperCase();
    if (dt == 'BOOLEAN') {
      return {'parameterCode': pc, 'value': given};
    }
    return {'parameterCode': pc, 'value': given ? 'Yes' : 'No'};
  }

  @override
  void initState() {
    super.initState();
    bootstrapActivitySchoolTimezone();
    _getActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();
    // Note: hot-reload doesn't rerun DI setup; avoid crashing if not registered yet.
    _guardianParentSignatureUseCase =
        serviceLocator.isRegistered<GuardianParentSignatureUseCase>()
            ? serviceLocator<GuardianParentSignatureUseCase>()
            : GuardianParentSignatureUseCase(serviceLocator<ActivityRepository>());
    _createActivityUseCase = serviceLocator<CreateActivityUseCase>();
    _updateActivityUseCase = serviceLocator<UpdateActivityUseCase>();
    _approveActivityUseCase = serviceLocator<ApproveActivityUseCase>();
    _rejectActivityUseCase = serviceLocator<RejectActivityUseCase>();
    _imageUploadService = serviceLocator<ImageUploadService>();
    _getGuardianNameCodeMapForSchoolUseCase =
        serviceLocator<GetGuardianNameCodeMapForSchoolUseCase>();

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData
          .map((student) => student['name'] as String)
          .toList();
      _activityDate = resolveSelectedAttendanceDate(_selectedStudentsData) ?? _activityDate;
      _loadActivityContextForCreate();
    } else if (_layoutAsEdit) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _requireAdminApproval = _isAdminApprovalRequired(activity);
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text =
          activity.whatHappened ?? activity.description ?? '';
      _addNotesController.text = activity.additionalNotes ?? '';
      // IMPORTANT: For view/edit, first-aid toggle must come from Activity Detail API
      // (parameterValues). Feed snapshot can be stale/absent.
      _isSigned = true;
      _activityTypeCode = activity.activityTypeCode;
      _detailAttachmentRows = (activity.snapshotAttachments ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _remainingExistingPhotoUrls = imageDeliveryUrlsFromAttachmentRows(
        _detailAttachmentRows,
      );
      if (_remainingExistingPhotoUrls.isEmpty &&
          activity.photoUrl != null &&
          activity.photoUrl!.trim().isNotEmpty) {
        _remainingExistingPhotoUrls = [activity.photoUrl!.trim()];
      }
      final iso = activity.activityDateIso;
      if (iso != null && iso.trim().isNotEmpty) {
        try {
          final dt = activityDateTimeForDisplayFromIso(iso.trim());
          _activityDate = DateTime(dt.year, dt.month, dt.day);
          _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _prefetchActivityForEdit();
      });
    }
    _loadStaffContext();
  }

  bool get _showAdminApproveRejectActions {
    if (!widget.isEdit || widget.readOnly) return false;
    if (!_isAdminDesignation) return false;
    return canAdminApproveOrRejectActivityItem(
      _effectiveActivity,
      isAdminPersona: true,
    );
  }

  Future<void> _approvePendingActivity() async {
    if (!_isAdminSigned || !_adminSignedThisSession) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please sign in Admin Present before approving.',
        isWarning: true,
      );
      return;
    }
    final code = _effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() {
      _isSavingBeforeApprove = true;
      _isApprovingOrRejecting = true;
    });
    try {
      await _submitUpdateActivity();
      if (!_lastUpdateSucceeded) return;
      final msg = await _approveActivityUseCase(code: code);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: msg,
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.logApiError(
        ApiErrorHandler.extractErrorMessage(e),
        showOnScreen: true,
        context: context,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingBeforeApprove = false;
          _isApprovingOrRejecting = false;
        });
      }
    }
  }

  Future<void> _rejectPendingActivity() async {
    if (!_isAdminSigned || !_adminSignedThisSession) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please sign in Admin Present before rejecting.',
        isWarning: true,
      );
      return;
    }
    final code = _effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _isApprovingOrRejecting = true);
    try {
      await _patchAdminSignBeforeDecision();
      final msg = await _rejectActivityUseCase(code: code);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: msg,
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.logApiError(
        ApiErrorHandler.extractErrorMessage(e),
        showOnScreen: true,
        context: context,
      );
    } finally {
      if (mounted) setState(() => _isApprovingOrRejecting = false);
    }
  }

  Future<void> _patchAdminSignBeforeDecision() async {
    if (!_isAdminDesignation || !_isAdminSigned) return;
    if (!_layoutAsEdit || widget.readOnly) return;
    final code = (_effectiveActivity.activityCode ?? '').trim();
    if (code.isEmpty) return;

    final activityTypeCode = (_activityTypeCode ?? '').trim();
    if (activityTypeCode.isEmpty) return;
    final details = await _getActivityTypeDetailsUseCase(code: activityTypeCode);
    var staffCode = _staffCode ?? await resolveLoggedInStaffCode();
    staffCode = (staffCode ?? '').trim();
    if (staffCode.isEmpty) return;

    DateTime? d = _activityDate;
    TimeOfDay? t = _activityTime;
    if ((d == null || t == null) &&
        (_effectiveActivity.activityDateIso ?? '').trim().isNotEmpty) {
      try {
        final dt = activityDateTimeForDisplayFromIso(
          _effectiveActivity.activityDateIso!.trim(),
        );
        d ??= DateTime(dt.year, dt.month, dt.day);
        t ??= TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }
    if (d == null || t == null) return;
    final activityDateIso = await activityUtcIsoFromSchoolWallClock(
      date: d,
      time: t,
    );

    final description =
        _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : ((_effectiveActivity.whatHappened ??
              _effectiveActivity.description ??
              '')
              .trim());
    if (description.isEmpty) return;

    final studentCodes = _selectedStudentsData
        .map((e) => (e['studentCode'] ?? e['code'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (studentCodes.isEmpty) {
      final sc = (_effectiveActivity.studentCode ?? '').trim();
      if (sc.isNotEmpty) studentCodes.add(sc);
    }
    // Preserve original PM_045 (Staff Present) from API. Do not replace it
    // with current admin/staff code during approve/reject patches.
    final creatorStaffCodeForIncident = _staffPresentRawValue.trim();
    final signerStaffCode = staffCode.trim();
    final staffSignerValue = _isSigned
        ? _ensureIncidentSignaturePayload(
            rawValue: _staffSignerRawValue.trim().isNotEmpty
                ? _staffSignerRawValue
                : creatorStaffCodeForIncident,
            fallbackDisplayName: _staffName,
            signingRecordCode: signerStaffCode,
          )
        : '';
    final adminSignerValue = _isAdminSigned
        ? _ensureIncidentSignaturePayload(
            rawValue: _adminSignerRawValue.trim().isNotEmpty
                ? _adminSignerRawValue
                : _staffName,
            fallbackDisplayName: _staffName,
            signingRecordCode: signerStaffCode,
          )
        : '';
    final guardianResolved = (await _resolveParentSignerCode()).trim();
    final parentSignerValue = _parentSignerRawValue.trim().isNotEmpty
        ? _ensureIncidentSignaturePayload(
            rawValue: _parentSignerRawValue,
            fallbackDisplayName: _parentIncidentSignatureFallbackDisplay(),
            signingRecordCode:
                guardianResolved.isNotEmpty
                    ? guardianResolved
                    : _inferIncidentSigningRecordCodeFromRaw(
                        _parentSignerRawValue,
                      ),
          )
        : '';
    final parameterValues = _incidentSignerParameterValuesForPatch(
      parameters: details.parameters,
      staffPresentCode: creatorStaffCodeForIncident,
      staffSignerCode: staffSignerValue,
      adminSignerCode: adminSignerValue,
      parentSignerCode: parentSignerValue,
    );
    if (parameterValues.isEmpty) return;
    _debugIncidentParameterValues('adminDecisionPatch', parameterValues);
    final remainingNorm = _remainingExistingPhotoUrls
        .map(normalizeActivityDeliveryUrl)
        .where((e) => e.isNotEmpty)
        .toSet();
    for (final u in videoDeliveryUrlsFromAttachmentRows(_detailAttachmentRows)) {
      final n = normalizeActivityDeliveryUrl(u);
      if (n.isNotEmpty) remainingNorm.add(n);
    }
    final mergedRows = mergeAttachmentRowsForEditPatch(
      existingRows: _detailAttachmentRows
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      newUploadRows: const <Map<String, dynamic>>[],
      remainingNormalizedDeliveryUrls: remainingNorm,
    );
    final patchAttachments = attachmentsForActivityPatchRequest(mergedRows);
    await _updateActivityUseCase(
      code: code,
      studentCodes: studentCodes,
      applyToStudentCodes: studentCodes,
      staffCode: staffCode,
      activityDate: activityDateIso,
      description: description,
      parameterValues: parameterValues,
      attachments: patchAttachments,
    );
    _adminSignerRawValue = staffCode;
  }

  Future<void> _prefetchActivityForEdit() async {
    if (!_layoutAsEdit || !mounted) return;
    final code = widget.activityData?.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _loadingActivityDetail = true);
    try {
      await _resolveLoggedInGuardianPresentIfNeeded();
      if (!mounted) return;
      final canonGc = await _resolveGuardianCodeForIncidentPayload();
      final rolesPrefetch =
          (await serviceLocator<StorageService>().getString(StorageKeys.roles) ??
                  '')
              .trim();
      final guardianViewer =
          incidentRolesJsonIndicatesGuardianLogin(rolesPrefetch);
      final detail = await _getActivityDetailRespectingPersona(code);
      if (!mounted) return;
      final firstAidFromApi = _pickFirstAidGivenFromActivityDetail(detail);
      final item = activityItemFromActivityDetail(
        detail,
        viewerDisplayName: _staffName,
      );

      final activityTypeCode = detail.activityTypeCode.trim();
      var schemaParams = const <ActivityTypeParameter>[];
      if (activityTypeCode.isNotEmpty) {
        try {
          final typeDetails =
              await _getActivityTypeDetailsUseCase(code: activityTypeCode);
          schemaParams = typeDetails.parameters;
        } catch (_) {}
      }

      final staffPresentSchema = _findIncidentSchemaParameter(
        schemaParams,
        const ['Staff Present'],
        contains: const ['staff present'],
      );
      final staffSignSchema = _findIncidentSchemaParameter(
        schemaParams,
        const ['Click to Sign - Staff'],
        contains: const ['click to sign - staff'],
      );
      final adminSignSchema = _findIncidentSchemaParameter(
        schemaParams,
        const ['Click to Sign - Admin'],
        contains: const ['click to sign - admin'],
      );
      final parentSignSchema = _findIncidentSchemaParameter(
        schemaParams,
        const ['Click to Sign - Parent'],
        contains: const ['click to sign - parent'],
      );

      bool? pickBoolSign(ActivityTypeParameter? schemaParam) {
        bool? fromRaw(dynamic raw) {
          if (raw is bool) return raw;
          final text = (raw ?? '').toString().trim().toLowerCase();
          if (text == 'true') return true;
          if (text == 'false') return false;
          return null;
        }

        for (final p in detail.parameterValues) {
          if (!_parameterValueMatchesIncidentSchema(p, schemaParam)) continue;
          for (final key in const <String>[
            'valueBool',
            'valueBoolean',
            'value',
            'valueText',
            'selectedOptionLabel',
          ]) {
            final parsed = fromRaw(p[key]);
            if (parsed != null) return parsed;
            if ((key == 'valueText' || key == 'value') &&
                (p[key] ?? '').toString().trim().isNotEmpty) {
              return true;
            }
          }
        }
        return null;
      }

      final staffSigned = pickBoolSign(staffSignSchema);
      final adminSigned = pickBoolSign(adminSignSchema);
      final parentSigned = pickBoolSign(parentSignSchema);
      final parentActuallySigned = parentSigned == true;
      String pickStaffPresentRawValue() {
        for (final p in detail.parameterValues) {
          if (!_parameterValueMatchesIncidentSchema(p, staffPresentSchema)) {
            continue;
          }
          final raw = (p['valueText'] ?? p['value'] ?? '').toString().trim();
          if (raw.isNotEmpty) return raw;
        }
        return '';
      }
      String pickSignRawValue(ActivityTypeParameter? schemaParam) {
        for (final p in detail.parameterValues) {
          if (!_parameterValueMatchesIncidentSchema(p, schemaParam)) continue;
          final raw = (p['valueText'] ?? p['value'] ?? '').toString().trim();
          if (raw.isNotEmpty) return raw;
        }
        return '';
      }
      final staffPresentRaw = pickStaffPresentRawValue();
      final staffSignRaw = pickSignRawValue(staffSignSchema);
      final adminSignRaw = pickSignRawValue(adminSignSchema);
      final parentSignRaw = pickSignRawValue(parentSignSchema);
      var effectiveParentSignRaw = parentSignRaw.trim();
      if (parentActuallySigned && effectiveParentSignRaw.isEmpty) {
        var gc = canonGc.trim();
        var label = _loggedInParentPresentLabel.trim();
        if (gc.isNotEmpty && label.isEmpty && !guardianViewer) {
          await _primeGuardianNamesFromCodes([gc]);
          if (mounted) {
            label =
                _displaySignerLabel(gc, fallback: gc).trim();
          }
        }
        if (gc.isNotEmpty) {
          effectiveParentSignRaw = label.isNotEmpty
              ? _buildIncidentSignaturePayload(
                  prefixForStorage: label,
                  signingRecordCode: gc,
                )
              : _buildIncidentSignaturePayload(
                  prefixForStorage: gc,
                  signingRecordCode: gc,
                );
        }
      }
      if (effectiveParentSignRaw.isNotEmpty &&
          canonGc.isNotEmpty &&
          guardianViewer &&
          !_incidentStoredPayloadEncodesRecordCode(effectiveParentSignRaw, canonGc)) {
        effectiveParentSignRaw = _canonicalGuardianIncidentSignStorage(
          raw: effectiveParentSignRaw,
          guardianCode: canonGc,
        );
      }
      await _primeStaffDisplayNamesFromCodes([
        staffPresentRaw,
        staffSignRaw,
        adminSignRaw,
      ]);
      final itemApprovalNormalized =
          (item.approvalStatus ?? '').trim().toUpperCase();
      // Pending parent acknowledgement must be reaffirmed explicitly each session:
      // API may carry a staged parent sign value/text; still show unchecked "Click to
      // sign" and require check + Acknowledge (do not derive from prefetched booleans).
      final guardianMustReaffirmPendingParentAck =
          guardianViewer &&
              itemApprovalNormalized == 'PARENT_ACKNOWLEDGEMENT_PENDING';
      setState(() {
        _liveActivity = item;
        _requireAdminApproval = _isAdminApprovalRequired(item);
        if ((widget.activityData?.studentList.length ?? 0) <= 1) {
          _selectedStudents = List<String>.from(item.studentList);
          _selectedStudentsData = studentDataMapsForActivityEdit(item);
        }
        _descriptionController.text =
            item.whatHappened ?? item.description ?? '';
        _addNotesController.text = item.additionalNotes ?? '';
        _isSigned = staffSigned ?? _isSigned;
        _isAdminSigned = adminSigned ?? _isAdminSigned;
        // Force explicit click-to-sign in this screen session for admin actions.
        _adminSignedThisSession = false;
        _isParentSigned = guardianMustReaffirmPendingParentAck
            ? false
            : (parentSigned ?? _isParentSigned);
        _staffPresentRawValue = staffPresentRaw;
        _staffSignerRawValue = staffSignRaw;
        _adminSignerRawValue = adminSignRaw;
        _parentSignerRawValue = effectiveParentSignRaw;
        _hasGuardianAcknowledgedLocally = guardianMustReaffirmPendingParentAck
            ? false
            : parentActuallySigned;
        _firstAidGiven =
            firstAidFromApi ?? (item.firstAidAdministered ?? _firstAidGiven);
        _activityTypeCode = item.activityTypeCode;
        _detailAttachmentRows = detail.attachments
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _remainingExistingPhotoUrls = imageDeliveryUrlsFromAttachmentRows(
          _detailAttachmentRows,
        );
        if (_remainingExistingPhotoUrls.isEmpty &&
            item.photoUrl != null &&
            item.photoUrl!.trim().isNotEmpty) {
          _remainingExistingPhotoUrls = [item.photoUrl!.trim()];
        }
        final nextIso = item.activityDateIso;
        if (nextIso != null && nextIso.trim().isNotEmpty) {
          try {
            final dt = activityDateTimeForDisplayFromIso(nextIso.trim());
            _activityDate = DateTime(dt.year, dt.month, dt.day);
            _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
          } catch (_) {}
        }
      });
      unawaited(
        _primeGuardianNamesFromCodes([effectiveParentSignRaw]).catchError((_) {}),
      );
    } catch (e) {
      CoreUtils.logApiError('Prefetch activity for edit: $e');
    } finally {
      if (mounted) setState(() => _loadingActivityDetail = false);
    }
  }

  Future<void> _loadStaffContext() async {
    final storage = serviceLocator<StorageService>();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '').trim();
    final staffType =
        (await storage.getString(StorageKeys.staffType) ?? '').trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final organizationCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final staffCode = await resolveLoggedInStaffCode();
    final resolvedDisplayName = await resolveLoggedInStaffDisplayNameFromApi(
      staffCode: staffCode,
    );

    if (!mounted) return;
    setState(() {
      _staffName = resolvedDisplayName.isNotEmpty ? resolvedDisplayName : 'Staff';
      _staffType = staffType.toUpperCase();
      _isGuardianPersona = incidentRolesJsonIndicatesGuardianLogin(rolesRaw);
      _staffCode = staffCode;
      _schoolCode = schoolCode.isNotEmpty ? schoolCode : null;
      _organizationCode = organizationCode.isNotEmpty ? organizationCode : null;
    });
    unawaited(
      _primeGuardianNamesFromCodes([_parentSignerRawValue]).catchError((_) {}),
    );
    if (incidentRolesJsonIndicatesGuardianLogin(rolesRaw)) {
      unawaited(_resolveLoggedInGuardianPresentLabel().catchError((_) {}));
    } else if (mounted) {
      setState(() {
        _loggedInGuardianCode = '';
        _loggedInParentPresentLabel = '';
      });
    }
  }

  Future<void> _onAcknowledgePressed() async {
    if (_isAcknowledging || !_showGuardianAcknowledgeButton) return;
    final code = (_effectiveActivity.activityCode ?? '').trim();
    if (code.isEmpty) return;
    if (!_hasParentSignedForAction) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please click to sign',
        isWarning: true,
      );
      return;
    }

    setState(() => _isAcknowledging = true);
    try {
      if (!_isGuardianPersona) return;
      final parentSignerCode = await _resolveParentSignerCode();
      if (parentSignerCode.isEmpty) {
        throw Exception('Unable to resolve guardian code');
      }
      final activityTypeCode = (_activityTypeCode ?? '').trim();
      if (activityTypeCode.isEmpty) {
        throw Exception('Unable to resolve activity type for parent signature');
      }
      final details = await _getActivityTypeDetailsUseCase(code: activityTypeCode);
      final parentSignSchema = _findIncidentSchemaParameter(
        details.parameters,
        const ['Click to Sign - Parent'],
        contains: const ['click to sign - parent'],
      );
      final parentSignParamCode = parentSignSchema?.code.trim();
      if (parentSignParamCode == null || parentSignParamCode.isEmpty) {
        throw Exception('Parent signature parameter is not configured');
      }
      var signaturePayload = _parentSignerRawValue.trim();
      final g = parentSignerCode.trim();
      if (signaturePayload.isEmpty ||
          !_incidentStoredPayloadEncodesRecordCode(signaturePayload, g)) {
        final label = _loggedInParentPresentLabel.trim().isNotEmpty
            ? _loggedInParentPresentLabel.trim()
            : g;
        signaturePayload = _buildIncidentSignaturePayload(
          prefixForStorage: label,
          signingRecordCode: g,
        );
      }
      await _guardianParentSignatureUseCase(
        code: code,
        parameterCode: parentSignParamCode.trim(),
        guardianCode: parentSignerCode,
        signatureValue: signaturePayload,
      );
      if (!mounted) return;

      await _primeGuardianNamesFromCodes([parentSignerCode]);

      var refreshedParentRaw = '';
      try {
        final refreshed = await _getActivityDetailRespectingPersona(code);
        if (!mounted) return;
        refreshedParentRaw = _extractParentSignRawFromParameterValues(
          refreshed.parameterValues,
          parentSignParameter: parentSignSchema,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _hasGuardianAcknowledgedLocally = true;
        _isParentSigned = true;
        if (refreshedParentRaw.trim().isNotEmpty) {
          _parentSignerRawValue = _canonicalGuardianIncidentSignStorage(
            raw: refreshedParentRaw.trim(),
            guardianCode: parentSignerCode.trim(),
          );
        } else {
          final profileLine = _loggedInParentPresentLabel.trim();
          final displayName = profileLine.isNotEmpty
              ? profileLine
              : _displaySignerLabel(
                  parentSignerCode,
                  fallback: parentSignerCode,
                ).trim();
          final g = parentSignerCode.trim();
          if (displayName.isNotEmpty && g.isNotEmpty) {
            _parentSignerRawValue = _buildIncidentSignaturePayload(
              prefixForStorage: displayName,
              signingRecordCode: g,
            );
          } else {
            _parentSignerRawValue =
                g.isNotEmpty
                    ? _buildIncidentSignaturePayload(
                        prefixForStorage: g,
                        signingRecordCode: g,
                      )
                    : '';
          }
        }
      });
      unawaited(
        _primeGuardianNamesFromCodes([_parentSignerRawValue]).catchError((_) {}),
      );
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Acknowledged successfully',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.logApiError(
        ApiErrorHandler.extractErrorMessage(e),
        showOnScreen: true,
        context: context,
      );
    } finally {
      if (mounted) {
        setState(() => _isAcknowledging = false);
      }
    }
  }

  Future<void> _loadActivityContextForCreate() async {
    if (widget.selectedStudents == null || widget.selectedStudents!.isEmpty) {
      return;
    }
    final first = widget.selectedStudents!.first;
    final dynamic classroomCodeDynamic =
        first['classroomCode'] ?? first['classroomcode'];
    final classroomCode = classroomCodeDynamic is String
        ? classroomCodeDynamic.trim()
        : '';
    if (classroomCode.isEmpty) return;

    try {
      final List<ActivitySetting> settings = await _getActivitySettingsUseCase(
        classroomCode: classroomCode,
      );
      ActivitySetting? incidentSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('incident')) {
          incidentSetting = s;
          break;
        }
      }
      if (incidentSetting != null && mounted) {
        setState(() {
          _activityTypeCode = incidentSetting!.activityTypeCode;
        });
      }
    } catch (e) {
      CoreUtils.logApiError(
        'Failed to load activity settings for Incident: $e',
      );
    }
  }

  Future<void> _submitCreateActivity() async {
    if (_isSubmitting) return;
    if (_layoutAsEdit) return;

    if (_selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isWarning: true,
      );
      return;
    }
    final isWithinAttendanceWindow = await validateStudentsWithinAttendanceWindow(
      context: context,
      students: _selectedStudentsData,
      selectedDate: _activityDate,
      selectedTime: _activityTime,
    );
    if (!isWithinAttendanceWindow) return;


    final whatHappened = _descriptionController.text.trim();
    if (whatHappened.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter what happened',
        isWarning: true,
      );
      return;
    }
    if (whatHappened.length < 5) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'What happened must be at least 5 characters',
        isWarning: true,
      );
      return;
    }
    if (whatHappened.length > ActivityDescriptionLimits.maxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ActivityDescriptionLimits.maxLengthMessage,
        isWarning: true,
      );
      return;
    }

    if (_isAdminDesignation) {
      if (!_isAdminSigned) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please sign in Admin Present.',
          isWarning: true,
        );
        return;
      }
    } else {
      if (!_isSigned) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please click to sign',
          isWarning: true,
        );
        return;
      }
    }
    if (_activityDate == null || _activityTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select date and time',
        isWarning: true,
      );
      return;
    }

    if (_uploadedPhotoCount != _newPhotos.length || _isUploadingMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please wait for all photos to finish uploading',
        isWarning: true,
      );
      return;
    }

    final classroomCodeDynamic =
        _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode = classroomCodeDynamic is String
        ? classroomCodeDynamic.trim()
        : '';

    if (classroomCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Missing classroom information for activity',
        isError: true,
      );
      return;
    }

    final scopedStudents = _scopedStudentsForCreate();
    final studentCodes = scopedStudents
        .map((s) => (s['studentCode'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();

    if (studentCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve student codes for activity',
        isError: true,
      );
      return;
    }

    var staffCode = _staffCode ?? await resolveLoggedInStaffCode();
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;

    if (staffCode == null ||
        schoolCode == null ||
        organizationCode == null ||
        staffCode.isEmpty ||
        schoolCode.isEmpty ||
        organizationCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Missing staff or school information. Please re-login and try again.',
        isError: true,
      );
      return;
    }

    final activityTypeCode = _activityTypeCode;
    if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to determine activity type for Incident. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final additionalNotes = _addNotesController.text.trim();
    if (additionalNotes.length > ActivityDescriptionLimits.maxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ActivityDescriptionLimits.maxLengthMessage,
        isWarning: true,
      );
      return;
    }

    // Ensure the API payload uses the attendance date chosen on student selection.
    final prefilled = widget.selectedStudents != null
        ? resolveSelectedAttendanceDate(_selectedStudentsData)
        : null;
    if (prefilled != null) {
      _activityDate = prefilled;
    }
    final activityDateIso = await activityUtcIsoFromSchoolWallClock(
      date: _activityDate!,
      time: _activityTime!,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final attachments = await _ensureIncidentMediaUploaded(
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );

      final details = await _getActivityTypeDetailsUseCase(
        code: activityTypeCode,
      );

      final dateParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Date'],
        contains: const ['date'],
      );
      final timeParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Time'],
        contains: const ['time'],
      );
      final staffParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Staff Present'],
        contains: const ['staff present'],
      );
      final whatParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['What happened?'],
        contains: const ['what happened', 'description'],
      );
      final notesParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Additional Notes'],
        contains: const ['additional'],
      );
      final staffSignParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Click to Sign - Staff'],
        contains: const ['click to sign - staff'],
      );
      final adminSignParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Click to Sign - Admin'],
        contains: const ['click to sign - admin'],
      );
      final parentSignParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Click to Sign - Parent'],
        contains: const ['click to sign - parent'],
      );
      final firstAidParam = _findFirstAidParameter(details.parameters);
      final firstAidEntry = firstAidParam == null
          ? null
          : _firstAidParameterEntry(firstAidParam, _firstAidGiven);

      final sameWhatAndNotes =
          whatParamCode != null &&
          notesParamCode != null &&
          whatParamCode.trim() == notesParamCode.trim();

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';

      final whatValueForParam = sameWhatAndNotes && additionalNotes.isNotEmpty
          ? '$whatHappened\n\n$additionalNotes'
          : whatHappened;

      final parentSignerCode = await _resolveParentSignerCode();
      final createStaffCode = staffCode.trim();
      final staffSignValue = (_isSigned && !_isAdminDesignation)
          ? _buildIncidentSignaturePayload(
              prefixForStorage: _staffName,
              signingRecordCode: createStaffCode,
            )
          : '';
      final adminSignValue = (_isAdminSigned && _isAdminDesignation)
          ? _buildIncidentSignaturePayload(
              prefixForStorage: _staffName,
              signingRecordCode: createStaffCode,
            )
          : '';
      final gCode = parentSignerCode.trim();
      final parentSignValue = _isParentSigned && gCode.isNotEmpty
          ? _buildIncidentSignaturePayload(
              prefixForStorage: _displaySignerLabel(
                parentSignerCode,
                fallback: parentSignerCode.trim(),
              ),
              signingRecordCode: gCode,
            )
          : '';
      final parameterValues = <Map<String, dynamic>>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          {'parameterCode': dateParamCode, 'value': localDate},
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          {'parameterCode': timeParamCode, 'value': localTime},
        if (staffParamCode != null &&
            staffParamCode.trim().isNotEmpty &&
            staffCode.trim().isNotEmpty)
          {'parameterCode': staffParamCode, 'value': staffCode},
        if (whatParamCode != null && whatParamCode.trim().isNotEmpty)
          {'parameterCode': whatParamCode, 'value': whatValueForParam},
        if (firstAidEntry != null) firstAidEntry,
        if (notesParamCode != null &&
            notesParamCode.trim().isNotEmpty &&
            !sameWhatAndNotes)
          {'parameterCode': notesParamCode, 'value': additionalNotes},
        if (staffSignParamCode != null && staffSignParamCode.trim().isNotEmpty)
          {
            'parameterCode': staffSignParamCode,
            'value': staffSignValue,
          },
        if (_isAdminDesignation &&
            adminSignParamCode != null &&
            adminSignParamCode.trim().isNotEmpty)
          {
            'parameterCode': adminSignParamCode,
            'value': adminSignValue,
          },
        if (parentSignParamCode != null &&
            parentSignParamCode.trim().isNotEmpty)
          {
            'parameterCode': parentSignParamCode,
            'value': parentSignValue,
          },
      ];
      _debugIncidentParameterValues('create', parameterValues);

      final message = await _createActivityUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: whatHappened,
        requireAdminApproval: _showRequireAdminApprovalToggle
            ? _requireAdminApproval
            : false,
        parameterValues: parameterValues,
        attachments: attachments,
      );

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );

      CoreUtils.exitActivityFlow(context);
    } catch (e) {
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitUpdateActivity() async {
    if (_isSubmitting) return;
    if (widget.readOnly) return;
    _lastUpdateSucceeded = false;

    final fallbackActivityCode = _effectiveActivity.activityCode?.trim();

    if (_selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isWarning: true,
      );
      return;
    }
    final isWithinAttendanceWindow = await validateStudentsWithinAttendanceWindow(
      context: context,
      students: _selectedStudentsData,
      selectedDate: _activityDate,
      selectedTime: _activityTime,
    );
    if (!isWithinAttendanceWindow) return;


    final whatHappened = _descriptionController.text.trim();
    if (whatHappened.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter what happened',
        isWarning: true,
      );
      return;
    }
    if (whatHappened.length < 5) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'What happened must be at least 5 characters',
        isWarning: true,
      );
      return;
    }
    if (whatHappened.length > ActivityDescriptionLimits.maxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ActivityDescriptionLimits.maxLengthMessage,
        isWarning: true,
      );
      return;
    }

    if (!_isSigned) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please click to sign',
        isWarning: true,
      );
      return;
    }
    if (_isAdminDesignation && !_isAdminSigned) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please sign in Admin Present before saving.',
        isWarning: true,
      );
      return;
    }
    if (_isAdminDesignation && !_adminSignedThisSession) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please sign in Admin Present before saving.',
        isWarning: true,
      );
      return;
    }

    if (_activityDate == null || _activityTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select date and time',
        isWarning: true,
      );
      return;
    }

    if (_newPhotos.isNotEmpty && _uploadedPhotoCount != _newPhotos.length) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please wait for all photos to finish uploading',
        isWarning: true,
      );
      return;
    }
    if (_isUploadingMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please wait for media uploads to finish',
        isWarning: true,
      );
      return;
    }

    final classroomCodeDynamic =
        _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode = classroomCodeDynamic is String
        ? classroomCodeDynamic.trim()
        : '';

    if (classroomCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Missing classroom information for activity',
        isError: true,
      );
      return;
    }

    final scopeMapsForUpload = studentMapsForScopedActivityUpdate(
      allStudentMaps: _selectedStudentsData,
      checkedIndices: _scopedEditStudentIndices,
    );
    final studentCodes = scopeMapsForUpload
        .map((s) => (s['studentCode'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();

    if (studentCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve student codes for activity',
        isError: true,
      );
      return;
    }

    var staffCode = _staffCode ?? await resolveLoggedInStaffCode();
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;

    if (staffCode == null ||
        schoolCode == null ||
        organizationCode == null ||
        staffCode.isEmpty ||
        schoolCode.isEmpty ||
        organizationCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Missing staff or school information. Please re-login and try again.',
        isError: true,
      );
      return;
    }

    final activityTypeCode = _activityTypeCode;
    if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to determine activity type for Incident. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final additionalNotes = _addNotesController.text.trim();
    if (additionalNotes.length > ActivityDescriptionLimits.maxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ActivityDescriptionLimits.maxLengthMessage,
        isWarning: true,
      );
      return;
    }

    final activityDateIso = await activityUtcIsoFromSchoolWallClock(
      date: _activityDate!,
      time: _activityTime!,
    );

    setState(() => _isSubmitting = true);
    try {
      final newAttachments = await _ensureIncidentMediaUploaded(
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );

      final remainingNorm = _remainingExistingPhotoUrls
          .map(normalizeActivityDeliveryUrl)
          .where((e) => e.isNotEmpty)
          .toSet();
      for (final u in videoDeliveryUrlsFromAttachmentRows(_detailAttachmentRows)) {
        final n = normalizeActivityDeliveryUrl(u);
        if (n.isNotEmpty) remainingNorm.add(n);
      }
      final legacyVideo = _effectiveActivity.videoUrl?.trim();
      if (legacyVideo != null && legacyVideo.isNotEmpty) {
        remainingNorm.add(normalizeActivityDeliveryUrl(legacyVideo));
      }
      final mergedRows = mergeAttachmentRowsForEditPatch(
        existingRows: _detailAttachmentRows
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        newUploadRows: newAttachments,
        remainingNormalizedDeliveryUrls: remainingNorm,
      );
      final patchAttachments =
          attachmentsForActivityPatchRequest(mergedRows);

      final details = await _getActivityTypeDetailsUseCase(
        code: activityTypeCode,
      );

      final dateParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Date'],
        contains: const ['date'],
      );
      final timeParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Time'],
        contains: const ['time'],
      );
      final staffParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Staff Present'],
        contains: const ['staff present'],
      );
      final whatParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['What happened?'],
        contains: const ['what happened', 'description'],
      );
      final notesParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Additional Notes'],
        contains: const ['additional'],
      );
      final staffSignParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Click to Sign - Staff'],
        contains: const ['click to sign - staff'],
      );
      final adminSignParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Click to Sign - Admin'],
        contains: const ['click to sign - admin'],
      );
      final parentSignParamCode = _findIncidentParamCodeByName(
        details.parameters,
        const ['Click to Sign - Parent'],
        contains: const ['click to sign - parent'],
      );
      final firstAidParam = _findFirstAidParameter(details.parameters);
      final firstAidEntry = firstAidParam == null
          ? null
          : _firstAidParameterEntry(firstAidParam, _firstAidGiven);

      final sameWhatAndNotes =
          whatParamCode != null &&
          notesParamCode != null &&
          whatParamCode.trim() == notesParamCode.trim();

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';

      final whatValueForParam = sameWhatAndNotes && additionalNotes.isNotEmpty
          ? '$whatHappened\n\n$additionalNotes'
          : whatHappened;

      final parentSignerCode = await _resolveParentSignerCode();
      // Preserve original PM_045 (Staff Present) from API on edit save.
      final creatorStaffCodeForIncident = _staffPresentRawValue.trim();
      final resolvedAdminSignerCode = _isAdminDesignation
          ? (_isAdminSigned
                ? (_adminSignerRawValue.trim().isNotEmpty
                      ? _adminSignerRawValue.trim()
                      : staffCode.trim())
                : '')
          : _adminSignerRawValue.trim();
      final resolvedParentSignerCode = _isGuardianPersona
          ? (_isParentSigned ? parentSignerCode.trim() : '')
          : _parentSignerRawValue.trim();
      final updateStaffCode = staffCode.trim();
      final resolvedStaffSignerValue = _isSigned
          ? (() {
              final raw = _staffSignerRawValue.trim();
              if (_incidentStoredPayloadEncodesRecordCode(raw, updateStaffCode)) {
                return raw;
              }
              return _buildIncidentSignaturePayload(
                prefixForStorage: _displaySignerLabel(
                  raw,
                  fallback: _staffName,
                ),
                signingRecordCode: updateStaffCode,
              );
            })()
          : '';
      final resolvedAdminSignerValue = resolvedAdminSignerCode.trim().isNotEmpty
          ? (() {
              final raw = _adminSignerRawValue.trim();
              if (_incidentStoredPayloadEncodesRecordCode(raw, updateStaffCode)) {
                return raw;
              }
              return _buildIncidentSignaturePayload(
                prefixForStorage: _displaySignerLabel(
                  raw,
                  fallback: _staffName,
                ),
                signingRecordCode: updateStaffCode,
              );
            })()
          : '';
      final pvc = resolvedParentSignerCode.trim();
      final resolvedParentSignerValue = pvc.isNotEmpty
          ? (() {
              final raw = _parentSignerRawValue.trim();
              if (_incidentStoredPayloadEncodesRecordCode(raw, pvc)) {
                return raw;
              }
              return _buildIncidentSignaturePayload(
                prefixForStorage: _displaySignerLabel(
                  raw,
                  fallback: pvc,
                ),
                signingRecordCode: pvc,
              );
            })()
          : '';
      final parameterValues = <Map<String, dynamic>>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          {'parameterCode': dateParamCode, 'value': localDate},
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          {'parameterCode': timeParamCode, 'value': localTime},
        if (staffParamCode != null &&
            staffParamCode.trim().isNotEmpty &&
            creatorStaffCodeForIncident.isNotEmpty)
          {'parameterCode': staffParamCode, 'value': creatorStaffCodeForIncident},
        if (whatParamCode != null && whatParamCode.trim().isNotEmpty)
          {'parameterCode': whatParamCode, 'value': whatValueForParam},
        if (firstAidEntry != null) firstAidEntry,
        if (notesParamCode != null &&
            notesParamCode.trim().isNotEmpty &&
            !sameWhatAndNotes)
          {'parameterCode': notesParamCode, 'value': additionalNotes},
        if (staffSignParamCode != null && staffSignParamCode.trim().isNotEmpty)
          {
            'parameterCode': staffSignParamCode,
            'value': resolvedStaffSignerValue,
          },
        if (adminSignParamCode != null && adminSignParamCode.trim().isNotEmpty)
          {
            'parameterCode': adminSignParamCode,
            'value': resolvedAdminSignerValue,
          },
        if (parentSignParamCode != null &&
            parentSignParamCode.trim().isNotEmpty)
          {
            'parameterCode': parentSignParamCode,
            'value': resolvedParentSignerValue,
          },
      ];
      _debugIncidentParameterValues('update', parameterValues);

      final targets = studentMapsForScopedActivityUpdate(
        allStudentMaps: _selectedStudentsData,
        checkedIndices: _scopedEditStudentIndices,
      );
      String? lastMessage;
      for (final m in targets) {
        final code = (m['activityCode'] as String?)?.trim() ??
            fallbackActivityCode;
        if (code == null || code.isEmpty) {
          if (!mounted) return;
          CoreUtils.showTopSnackBar(
            context: context,
            message:
                'Missing activity reference for a student. Refresh the feed and try again.',
            isError: true,
          );
          return;
        }
        lastMessage = await _updateActivityUseCase(
          code: code,
          studentCodes: _selectedStudentsData
              .map((e) => (e['studentCode'] as String?)?.trim())
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList(),
          applyToStudentCodes: targets
              .map((e) => (e['studentCode'] as String?)?.trim())
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList(),
          staffCode: staffCode,
          activityDate: activityDateIso,
          description: whatHappened,
          parameterValues: parameterValues,
          attachments: patchAttachments,
        );
        try {
          await _getActivityDetailRespectingPersona(code);
        } catch (_) {}
      }

      if (!mounted) return;
      _lastUpdateSucceeded = true;
      if (!_isSavingBeforeApprove) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: lastMessage ?? 'Updated',
          isSuccess: true,
        );
        CoreUtils.exitActivityFlow(context);
      }
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onSaveOrAddPressed() async {
    if (_isSubmitting || _isUploadingMedia) return;
    if (widget.readOnly) return;
    if (widget.isEdit) {
      await _submitUpdateActivity();
      return;
    }

    await _submitCreateActivity();
  }

  Future<List<Map<String, dynamic>>> _ensureIncidentMediaUploaded({
    required String classroomCode,
    required String activityTypeCode,
    required String organizationCode,
    required String schoolCode,
    required List<String> studentCodes,
  }) async {
    if (_newPhotos.isEmpty) return const [];

    final normalizedStudentCodes =
        studentCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          ..sort();
    final uploadContextKey = [
      organizationCode.trim(),
      schoolCode.trim(),
      classroomCode.trim(),
      normalizedStudentCodes.join(','),
    ].join('|');
    if (_lastUploadContextKey != uploadContextKey) {
      _uploadedAssetCodeByPath.clear();
      _lastUploadContextKey = uploadContextKey;
    }

    // Incident activity backend can reject SHARED attachments for some activity
    // type configs, so always upload as PER_STUDENT.
    const bindingMode = 'PER_STUDENT';
    const ownerType = 'STUDENT';
    final ownerCode = studentCodes.first;
    final missingPhotos = _newPhotos
        .where((f) => !_uploadedAssetCodeByPath.containsKey(f.path))
        .toList();

    if (missingPhotos.isNotEmpty) {
      setState(() {
        _isUploadingMedia = true;
        _uploadProgressPercent = 0;
        _uploadCompletedCount = 0;
        _uploadTotalCount = missingPhotos.length;
      });
      try {
        final uploadSession = await _imageUploadService
            .createActivityUploadSession(
              organizationCode: organizationCode,
              schoolCode: schoolCode,
              classroomCode: classroomCode,
              activityTypeCode: activityTypeCode,
              bindingMode: bindingMode,
              studentCodes: studentCodes,
            );

        final sessionAssetCodes = <String>[];
        for (var i = 0; i < missingPhotos.length; i++) {
          final photo = missingPhotos[i];
          final fileIndex = i + 1;
          final totalFiles = missingPhotos.length;
          final fileName = photo.uri.pathSegments.isNotEmpty
              ? photo.uri.pathSegments.last
              : 'photo.jpg';
          final contentLengthBytes = await photo.length();
          final checksumSha256 =
              await _imageUploadService.computeFileChecksumSha256(photo);
          final presign = await _imageUploadService.createAssetPresign(
            sessionCode: uploadSession.sessionCode,
            documentApiBasePath: uploadSession.documentApiBasePath,
            fileName: fileName,
            contentType: 'image/jpeg',
            contentLengthBytes: contentLengthBytes,
            checksumSha256: checksumSha256,
            mediaType: 'IMAGE',
            ownerType: ownerType,
            ownerCode: ownerCode,
          );
          await _imageUploadService.uploadFileToPresignedUrl(
            file: photo,
            presignedPutUrl: presign.presignedPutUrl,
            requiredHeaders: presign.requiredHeaders,
            fallbackContentType: 'image/jpeg',
            onProgress: (_, __, percent) {
              if (!mounted) return;
              final overallFraction =
                  ((fileIndex - 1) + (percent / 100)) / totalFiles;
              final overallPercent =
                  (overallFraction * 100).clamp(0, 100).round();
              final displayPercent =
                  overallPercent >= 100 ? 99 : overallPercent;
              setState(() => _uploadProgressPercent = displayPercent);
            },
          );
          await _imageUploadService.completeAssetUpload(
            sessionCode: uploadSession.sessionCode,
            assetCode: presign.assetCode,
            documentApiBasePath: uploadSession.documentApiBasePath,
          );
          if (mounted) {
            setState(() => _uploadCompletedCount = fileIndex);
          }
          _uploadedAssetCodeByPath[photo.path] = presign.assetCode;
          sessionAssetCodes.add(presign.assetCode);
        }
        await _imageUploadService.waitUntilAssetsReady(
          sessionCode: uploadSession.sessionCode,
          expectedAssetCodes: sessionAssetCodes,
        );
        if (mounted) {
          setState(() => _uploadProgressPercent = 100);
        }
      } finally {
        if (mounted) setState(() => _isUploadingMedia = false);
      }
    }

    final attachments = <Map<String, dynamic>>[];
    for (final photo in _newPhotos) {
      final assetCode = _uploadedAssetCodeByPath[photo.path];
      if (assetCode != null && assetCode.isNotEmpty) {
        attachments.add({
          'assetCode': assetCode,
          'studentCode': ownerCode,
          'bindingMode': bindingMode,
        });
      }
    }
    return attachments;
  }

  void _onMediaChanged(
    List<File> photos,
    File? video,
    List<String> remainingExistingPhotoUrls,
    String? remainingExistingVideoUrl,
  ) {
    final normalizedPhotos = widget.isEdit && photos.length > 1
        ? <File>[photos.last]
        : photos;
    final photoCount =
        normalizedPhotos.length + remainingExistingPhotoUrls.length;
    final videoCount =
        (video != null ? 1 : 0) +
        ((remainingExistingVideoUrl != null &&
                remainingExistingVideoUrl.trim().isNotEmpty)
            ? 1
            : 0);
    if (photoCount > 1 &&
        !(widget.isEdit &&
            photos.isNotEmpty &&
            remainingExistingPhotoUrls.isNotEmpty)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Only 1 photo can be selected.',
        isError: true,
      );
      return;
    }
    if (widget.isEdit && videoCount > 1) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Maximum 1 video can be attached.',
        isError: true,
      );
      return;
    }
    setState(() {
      _newPhotos = normalizedPhotos;
      _remainingExistingPhotoUrls = (widget.isEdit &&
              normalizedPhotos.isNotEmpty)
          ? const []
          : List<String>.from(remainingExistingPhotoUrls);
      _uploadedAssetCodeByPath.removeWhere((path, _) {
        final stillPhoto = _newPhotos.any((f) => f.path == path);
        return !stillPhoto;
      });
    });
    _uploadMediaOnSelection();
  }

  Future<void> _uploadMediaOnSelection() async {
    if (widget.readOnly || _newPhotos.isEmpty || _isUploadingMedia) {
      return;
    }
    if (_selectedStudentsData.isEmpty) return;

    final activityTypeCode = _activityTypeCode;
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;
    final classroomCodeDynamic =
        _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode = classroomCodeDynamic is String
        ? classroomCodeDynamic.trim()
        : '';
    final studentCodes = _selectedStudentsData
        .map((s) => (s['studentCode'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();

    if (activityTypeCode == null ||
        activityTypeCode.isEmpty ||
        schoolCode == null ||
        schoolCode.isEmpty ||
        organizationCode == null ||
        organizationCode.isEmpty ||
        classroomCode.isEmpty ||
        studentCodes.isEmpty) {
      return;
    }

    try {
      await _ensureIncidentMediaUploaded(
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Photo(s) uploaded successfully',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(error),
        isError: true,
      );
    }
  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);
      _selectedStudentsData.removeWhere((m) => (m['name'] as String?) == name);

      // If no students left, go back to previous screen
      if (_selectedStudents.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: 'Incident',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            if (_layoutAsEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Students involved'),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.primaryColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_layoutAsEdit) const SizedBox(height: 12),
            if (_layoutAsEdit &&
                !(widget.isEdit &&
                    !widget.readOnly &&
                    _selectedStudents.length > 1))
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: responsive.isTablet ? 3 : 2,
                  crossAxisSpacing: responsive.isTablet ? 16 : 12,
                  mainAxisSpacing: responsive.isTablet ? 16 : 12,
                  mainAxisExtent: 50,
                ),
                itemCount: _selectedStudents.length,
                itemBuilder: (context, index) {
                  return ActivityStudentDisplayTile(
                    name: _selectedStudents[index],
                  );
                },
              )
            else if (!_layoutAsEdit)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: responsive.isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: responsive.isTablet ? 3.8 : 3.0,
                ),
                itemCount: _selectedStudents.length,
                itemBuilder: (context, index) {
                  final String name = _selectedStudents[index];
                  return SelectedStudentTile(
                    name: name,
                    onTap: () => _removeStudent(name),
                  );
                },
              ),
            if (!widget.readOnly && _selectedStudents.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ActivityEditStudentScopeCheckboxes(
                  studentNames: _selectedStudents,
                  checkedIndices: _scopedEditStudentIndices,
                  onChanged: (next) => setState(() {
                    _scopedEditStudentIndices
                      ..clear()
                      ..addAll(next);
                  }),
                ),
              ),
            ],
            SizedBox(height: responsive.verticalSpacing,),
            Row(
              children: [
                Flexible(
                  child: _layoutAsEdit
                      ? DateWidget(
                          isEditable: false,
                          isRequired: true,
                          initialDate: _effectiveActivity.date,
                          onDateChanged: (d) => _activityDate = d,
                        )
                      : DateWidget(
                          isEditable: false,
                          isRequired: true,
                          initialDate: formatSelectedDateForDateWidget(_activityDate),
                          onDateChanged: (d) => _activityDate = d,
                        ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _layoutAsEdit
                      ? TimeWidget(
                          isEditable: _canInteract,
                          isRequired: true,
                          prefilledTime: _effectiveActivity.time,
                          onTimeChanged: (t) => _activityTime = t,
                        )
                      : TimeWidget(
                          isRequired: true,
                          isEditable: true,
                          onTimeChanged: (t) => _activityTime = t,
                        ),
                ),
              ],
            ),
            SizedBox(height: responsive.verticalSpacing),
            InputWidget(
              controller: _descriptionController,
              label: 'What happened?',
              isRequired: true,
              height: 100,
              readOnly: !_canInteract,
              maxLength: ActivityDescriptionLimits.maxLength,
            ),
            SizedBox(height: responsive.verticalSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First Aid Administered',
                  style: TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 10.0 : 8.0),
                IgnorePointer(
                  ignoring: !_canInteract,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'No',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff573353),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomToggle(
                        label: '',
                        isToggled: _firstAidGiven,
                        onToggle: (v) => setState(() => _firstAidGiven = v),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Yes',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff573353),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.verticalSpacing),
            Builder(
              builder: (context) {
                // View-only layout: show the same signer blocks for all personas
                // (guardian/staff/admin) with interactions disabled.
                final isReadOnlyView = widget.readOnly;
                if (isReadOnlyView) {
                  final staffSignerCode = _staffSignerRawValue.trim();
                  final adminSignerCode = _adminSignerRawValue.trim();
                  final parentSignerCode = _parentSignerRawValue.trim();
                  final staffPresentReadLabel =
                      _displaySignerLabel(staffSignerCode, fallback: '');
                  final adminPresentReadLabel =
                      _displaySignerLabel(adminSignerCode, fallback: '');
                  final profileGuardianLine = _loggedInParentPresentLabel.trim();
                  final parentPresentReadLabel =
                      (_isGuardianPersona && profileGuardianLine.isNotEmpty)
                          ? profileGuardianLine
                          : _displaySignerLabel(
                              parentSignerCode,
                              fallback: profileGuardianLine,
                            );
                  final showStaffSignedBlock = staffSignerCode.isNotEmpty;
                  final showAdminSignedBlock = adminSignerCode.isNotEmpty;
                  final showParentSignedBlock = parentSignerCode.isNotEmpty ||
                      (_isGuardianPersona &&
                          _approvalStatus == 'PARENT_ACKNOWLEDGEMENT_PENDING');
                  return Column(
                    children: [
                      if (showStaffSignedBlock)
                        StaffPresentWidget(
                          key: const ValueKey('incident_parent_view_staff_present'),
                          fieldLabel: 'Staff Present',
                          staffName: staffPresentReadLabel,
                          isEditable: false,
                          isAlreadySigned: true,
                          clickToSignEditable: false,
                          showSignCheckbox: true,
                          showStaffDropdown: false,
                          incidentActivity: true,
                          signatureEncodedValue:
                              _incidentSignatureEncodedFingerprint(
                            rawStoredValue: staffSignerCode,
                            signingRecordCode:
                                _inferIncidentSigningRecordCodeFromRaw(
                              staffSignerCode,
                            ),
                          ),
                        ),
                      if (showStaffSignedBlock && showAdminSignedBlock)
                        const SizedBox(height: 16),
                      if (showAdminSignedBlock)
                        StaffPresentWidget(
                          key: const ValueKey('incident_parent_view_admin_present'),
                          fieldLabel: 'Admin Present',
                          staffName: adminPresentReadLabel,
                          isEditable: false,
                          isAlreadySigned: true,
                          clickToSignEditable: false,
                          showSignCheckbox: true,
                          showStaffDropdown: false,
                          incidentActivity: true,
                          signatureEncodedValue:
                              _incidentSignatureEncodedFingerprint(
                            rawStoredValue: adminSignerCode,
                            signingRecordCode:
                                _inferIncidentSigningRecordCodeFromRaw(
                              adminSignerCode,
                            ),
                          ),
                        ),
                      if ((showStaffSignedBlock || showAdminSignedBlock) &&
                          showParentSignedBlock)
                        const SizedBox(height: 16),
                      if (showParentSignedBlock)
                        StaffPresentWidget(
                          key: const ValueKey('incident_parent_sign_only'),
                          fieldLabel: 'Parent Present',
                          // Never show logged-in staff/admin name here.
                          staffName: parentPresentReadLabel,
                          isEditable: false,
                          isAlreadySigned: _hasParentSignedForAction,
                          clickToSignEditable: !_isAcknowledged,
                          matchStaffDirectoryForDisplay: false,
                          showStaffDropdown: false,
                          showSignCheckbox: true,
                          incidentActivity: true,
                          onSigned: (value) {
                            setState(() {
                              _isParentSigned = value;
                              if (!value) {
                                _parentSignerRawValue = '';
                              }
                            });
                            if (!value || !mounted) return;
                            () async {
                              var gc = _loggedInGuardianCode.trim();
                              if (gc.isEmpty) {
                                gc = (await serviceLocator<StorageService>()
                                            .getString(StorageKeys.guardianCode) ??
                                        '')
                                    .trim();
                              }
                              if (!mounted || !_isParentSigned) return;
                              final label = _loggedInParentPresentLabel.trim();
                              final prefix = label.isNotEmpty ? label : gc;
                              setState(() {
                                _parentSignerRawValue = gc.isNotEmpty
                                    ? _buildIncidentSignaturePayload(
                                        prefixForStorage:
                                            prefix.isNotEmpty ? prefix : gc,
                                        signingRecordCode: gc,
                                      )
                                    : '';
                              });
                            }();
                          },
                          signatureEncodedValue:
                              _incidentSignatureEncodedFingerprint(
                            rawStoredValue: parentSignerCode,
                            signingRecordCode:
                                _inferIncidentSigningRecordCodeFromRaw(
                              parentSignerCode,
                            ),
                          ),
                        ),
                    ],
                  );
                }
                final isAdminPersona =
                    _isAdminDesignation;
                final lockToLoggedInStaff = _canInteract && !isAdminPersona;
                final showStaffPresentBlock = !(_layoutAsEdit &&
                    _isAdminDesignation &&
                    _staffSignerRawValue.trim().isEmpty);
                if (!showStaffPresentBlock) {
                  return const SizedBox.shrink();
                }
                final staffPresentEditLabel = _layoutAsEdit
                    ? _displaySignerLabel(
                        _staffPresentRawValue,
                        fallback: '',
                      )
                    : (lockToLoggedInStaff
                          ? _staffName
                          : staffPresentLabelForActivity(
                              layoutAsEdit: _layoutAsEdit,
                              activityCreatedBy: _layoutAsEdit
                                  ? (_effectiveActivity.staffPresent ??
                                      _effectiveActivity.createdBy)
                                  : '',
                              loggedInDisplayName: _staffName,
                            ));
                return StaffPresentWidget(
                  key: const ValueKey('incident_staff_present'),
                  staffName: staffPresentEditLabel,
                  isEditable:
                      lockToLoggedInStaff ? false : _canInteract,
                  isAlreadySigned: _mergeAdminSignatureIntoStaffPresent
                      ? _isAdminSigned
                      : _isSigned,
                  clickToSignEditable: _canInteract,
                  showSignCheckbox: !_isGuardianPersona &&
                      (!_isAdminDesignation ||
                          _mergeAdminSignatureIntoStaffPresent),
                  showStaffDropdown: !_isAdminDesignation,
                  prefillWithStaffName: !_layoutAsEdit && _isAdminDesignation,
                  incidentActivity: true,
                  onSigned: (value) {
                    setState(() {
                      final sc = (_staffCode ?? '').trim();
                      if (_mergeAdminSignatureIntoStaffPresent) {
                        _isAdminSigned = value;
                        _adminSignedThisSession = value;
                        final prefix =
                            _staffName.trim().isEmpty ? 'Admin' : _staffName.trim();
                        _adminSignerRawValue = value
                            ? _buildIncidentSignaturePayload(
                                prefixForStorage: prefix,
                                signingRecordCode: sc,
                              )
                            : '';
                      } else {
                        _isSigned = value;
                        _staffSignerRawValue = value
                            ? _buildIncidentSignaturePayload(
                                prefixForStorage: _staffName,
                                signingRecordCode: sc,
                              )
                            : '';
                      }
                    });
                  },
                  signatureEncodedValue:
                      _incidentSignatureEncodedFingerprint(
                    rawStoredValue: _mergeAdminSignatureIntoStaffPresent
                        ? _adminSignerRawValue
                        : _staffSignerRawValue,
                    signingRecordCode: (_staffCode ?? '').trim(),
                  ),
                );
              },
            ),
            if (_layoutAsEdit && _isAdminDesignation && !widget.readOnly)
              const SizedBox(height: 16),
            if (_layoutAsEdit && _isAdminDesignation && !widget.readOnly)
              StaffPresentWidget(
                key: const ValueKey('incident_admin_present'),
                fieldLabel: 'Admin Present',
                staffName: _staffName.trim().isEmpty ? 'Admin' : _staffName,
                isEditable: false,
                isAlreadySigned: _isAdminSigned,
                clickToSignEditable: _canInteract,
                showSignCheckbox: !_isGuardianPersona,
                incidentActivity: true,
                onSigned: (value) {
                  setState(() {
                    _isAdminSigned = value;
                    _adminSignedThisSession = value;
                    final sc = (_staffCode ?? '').trim();
                    _adminSignerRawValue = value
                        ? _buildIncidentSignaturePayload(
                            prefixForStorage: _staffName.trim().isEmpty
                                ? 'Admin'
                                : _staffName.trim(),
                            signingRecordCode: sc,
                          )
                        : '';
                  });
                },
                signatureEncodedValue:
                    _incidentSignatureEncodedFingerprint(
                  rawStoredValue: _adminSignerRawValue,
                  signingRecordCode: (_staffCode ?? '').trim(),
                ),
              ),
            SizedBox(height: responsive.verticalSpacing),
            InputWidget(
              controller: _addNotesController,
              hint: 'Enter note',
              label: 'Additional Notes',
              height: 100,
              readOnly: !_canInteract,
              maxLength: ActivityDescriptionLimits.maxLength,
            ),
            if (_showRequireAdminApprovalToggle)
              const SizedBox(height: 4),
            if (_showRequireAdminApprovalToggle)
              AbsorbPointer(
                absorbing: true,
                child: CustomToggle(
                  label: 'Requires Admin Approval',
                  isToggled: _requireAdminApproval,
                  labelOnLeftSide: true,
                  onToggle: (value) {
                    setState(() {
                      _requireAdminApproval = value;
                    });
                  },
                ),
              ),
            SizedBox(height: responsive.verticalSpacing),
            if (_layoutAsEdit)
              MediaUploader(
                isRequired: false,
                allowVideo: false,
                allowPhoto: true,
                readOnly: widget.readOnly,
                isPictureBox: false,
                limit: 1,
                autoReplaceFirstPhotoWhenMaxReached: widget.isEdit,
                photoSizeLimit: 20,
                initialPhotoUrls: _remainingExistingPhotoUrls.isNotEmpty
                    ? List<String>.from(_remainingExistingPhotoUrls)
                    : (_effectiveActivity.photoUrl != null &&
                            _effectiveActivity.photoUrl!.trim().isNotEmpty
                        ? [_effectiveActivity.photoUrl!.trim()]
                        : const []),
                label: 'Photos',
                onMediaChanged: _onMediaChanged,
              )
            else
              MediaUploader(
                isRequired: false,
                allowVideo: false,
                allowPhoto: true,
                readOnly: widget.readOnly,
                isPictureBox: false,
                limit: 1,
                photoSizeLimit: 20,
                label: 'Photos',
                onMediaChanged: _onMediaChanged,
              ),
            if (_newPhotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildUploadStatus(),
            ],
            SizedBox(height: responsive.verticalSpacing),
          ],
        ),
      ),
      bottomBar: widget.readOnly
          ? SafeArea(
              child: _showGuardianAcknowledgeButton
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: CustomButtonLayout(
                        confirmButtonLabel: _isAcknowledged ? 'Acknowledged' : 'Acknowledge',
                        onPressedConfirm: _isAcknowledged
                            ? null
                            : _onAcknowledgePressed,
                        showCancelButton: false,
                        isForm: false,
                        isLoading: _isAcknowledging,
                      ),
                    )
                  : const SizedBox.shrink(),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActivityAdminApproveRejectBar(
                      visible: _showAdminApproveRejectActions,
                      isLoading: _isApprovingOrRejecting ||
                          _isSubmitting ||
                          _isUploadingMedia ||
                          _loadingActivityDetail,
                      onApprove: _approvePendingActivity,
                      onReject: _rejectPendingActivity,
                    ),
                    if (!_showAdminApproveRejectActions)
                      CustomButtonLayout(
                      confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                      onPressedConfirm: _onSaveOrAddPressed,
                      showCancelButton: false,
                      isForm: false,
                      isLoading: _isSubmitting ||
                          _isApprovingOrRejecting ||
                          _isUploadingMedia ||
                          _loadingActivityDetail,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadStatus() {
    if (_isUploadingMedia) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: (_uploadProgressPercent / 100).clamp(0.0, 1.0),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Uploading photos... $_uploadProgressPercent% ($_uploadCompletedCount/$_uploadTotalCount)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      );
    }

    if (_uploadTotalCount > 0 &&
        _uploadCompletedCount == _uploadTotalCount &&
        _uploadProgressPercent == 100) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Uploaded $_uploadCompletedCount/$_uploadTotalCount',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      );
    }

    final uploadsSynced = _newPhotos.isEmpty ||
        _uploadedPhotoCount == _newPhotos.length;
    final createSatisfied = true;

    if (uploadsSynced && createSatisfied) {
      final parts = <String>[];
      if (_newPhotos.isNotEmpty) {
        parts.add('${_uploadedPhotoCount}/${_newPhotos.length} photo(s)');
      }
      final label = parts.isEmpty ? 'Ready' : parts.join(', ');
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Uploaded $label',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      );
    }

    final buf = StringBuffer()
      ..write(
        'Photos $_uploadedPhotoCount/${_newPhotos.length}',
      );
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            buf.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncidentSignaturePayload {
  const _IncidentSignaturePayload({
    required this.signerName,
    required this.encodedName,
  });

  final String signerName;
  final String encodedName;
}



