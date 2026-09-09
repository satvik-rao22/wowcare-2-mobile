import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_description_limits.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_patch_attachments.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_school_time.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_selected_date_prefill.dart';
import 'package:wowcare/presentation/features/activities/utils/resolve_logged_in_staff_code.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_item_edit_mappers.dart'
    show activityItemFromActivityDetail, studentDataMapsForActivityEdit;
import 'package:wowcare/presentation/features/activities/view/activity_feed_card_permissions.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart'
    show ActivityItem;
import 'package:wowcare/presentation/features/activities/widgets/activity_edit_student_scope_checkboxes.dart';
import 'activity_editor_cubit.dart';
import 'activity_form_outcome.dart';

export 'activity_form_outcome.dart';

part 'bottle_activity_state.dart';

/// ViewModel for [BottleActivityScreen]. Mirrors [MedicationActivityCubit] but
/// for the Bottle form: the description is optional, an ounce amount is
/// required (read from the picker widget and passed in by the view), and the
/// update path patches attachments. Data access goes through the shared
/// [ActivityEditorCubit] seam; the attendance-window dialog is delegated to the
/// view via `onValidateAttendanceWindow`.
class BottleActivityCubit extends Cubit<BottleActivityState> {
  BottleActivityCubit({
    required ActivityEditorCubit editor,
    required StorageService storageService,
  }) : _editor = editor,
       _storageService = storageService,
       super(const BottleActivityState());

  final ActivityEditorCubit _editor;
  final StorageService _storageService;

  bool _isEdit = false;
  bool _readOnly = false;
  bool _createdFromSelection = false;
  ActivityItem? _activityData;

  DateTime? _activityDate;
  TimeOfDay? _activityTime;
  String? _staffPresentCode;

  bool get _layoutAsEdit => _isEdit || _readOnly;

  DateTime? get activityDate => _activityDate;
  TimeOfDay? get activityTime => _activityTime;
  String? get staffPresentCode => _staffPresentCode;
  bool get isEdit => _isEdit;
  bool get readOnly => _readOnly;

  ActivityItem get effectiveActivity =>
      state.liveActivity ?? _activityData ?? ActivityItem.empty;

  bool showAdminApproveRejectActions({required bool isAdminPersona}) {
    if (!_isEdit || _readOnly) return false;
    if (!state.isAdminDesignation) return false;
    return canAdminApproveOrRejectActivityItem(
      effectiveActivity,
      isAdminPersona: isAdminPersona,
    );
  }

  @override
  Future<void> close() async {
    await _editor.close();
    await super.close();
  }

  // ─── Bootstrap ─────────────────────────────────────────────────────────────

  void init({
    required bool isEdit,
    required bool readOnly,
    ActivityItem? activityData,
    List<Map<String, dynamic>>? selectedStudents,
  }) {
    _isEdit = isEdit;
    _readOnly = readOnly;
    _activityData = activityData;
    // ignore: discarded_futures
    bootstrapActivitySchoolTimezone();

    if (selectedStudents != null) {
      _createdFromSelection = true;
      final data = List<Map<String, dynamic>>.from(selectedStudents);
      final names = data.map((s) => s['name'] as String).toList();
      _activityDate = resolveSelectedAttendanceDate(data) ?? _activityDate;
      emit(state.copyWith(selectedStudentsData: data, selectedStudents: names));
      // ignore: discarded_futures
      _loadActivityContextForCreate(data);
    } else if (_layoutAsEdit) {
      final activity = activityData!;
      emit(
        state.copyWith(
          liveActivity: activity,
          requireAdminApproval: _isAdminApprovalRequired(activity),
          selectedStudents: List<String>.from(activity.studentList),
          selectedStudentsData: studentDataMapsForActivityEdit(activity),
          activityTypeCode: activity.activityTypeCode,
          detailAttachmentRows: (activity.snapshotAttachments ?? const [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        ),
      );
      final iso = activity.activityDateIso;
      if (iso != null && iso.trim().isNotEmpty) {
        try {
          final dt = activityDateTimeForDisplayFromIso(iso.trim());
          _activityDate = DateTime(dt.year, dt.month, dt.day);
          _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      // ignore: discarded_futures
      _prefetchActivityForEdit();
    }
    // ignore: discarded_futures
    _loadStaffContext();
  }

  bool _isAdminApprovalRequired(ActivityItem activity) {
    final status = (activity.approvalStatus ?? '').trim().toUpperCase();
    return status.isNotEmpty && status != 'NOT_REQUIRED';
  }

  static String? _staffDisplayFromParameterRows(
    List<Map<String, dynamic>> rows,
  ) {
    for (final p in rows) {
      final pn = (p['parameterName'] ?? '').toString().toLowerCase();
      if (!pn.contains('staff')) continue;
      final dt = (p['dataType'] ?? '').toString().toUpperCase();
      if (dt == 'DATE' || dt == 'TIME') continue;
      for (final key in <String>[
        'selectedOptionLabel',
        'optionLabel',
        'valueText',
      ]) {
        final v = (p[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static String? _staffCodeFromParameterRows(List<Map<String, dynamic>> rows) {
    for (final p in rows) {
      final pn = (p['parameterName'] ?? '').toString().trim().toLowerCase();
      if (pn != 'staff present') continue;
      final v =
          (p['selectedOptionCode'] ?? p['valueText'] ?? p['valueNumber'] ?? '')
              .toString()
              .trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  Future<void> _loadStaffContext() async {
    final staffType =
        (await _storageService.getString(StorageKeys.staffType) ?? '').trim();
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    final organizationCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();
    final staffCode = await resolveLoggedInStaffCode();
    final apiDisplayName = await resolveLoggedInStaffDisplayNameFromApi(
      staffCode: staffCode,
    );

    if (isClosed) return;
    _staffPresentCode = (staffCode ?? '').trim().isEmpty
        ? null
        : staffCode!.trim();
    emit(
      state.copyWith(
        staffName: apiDisplayName.isNotEmpty ? apiDisplayName : 'Staff',
        staffType: staffType.toUpperCase(),
        staffCode: staffCode,
        schoolCode: schoolCode.isNotEmpty ? schoolCode : null,
        organizationCode: organizationCode.isNotEmpty ? organizationCode : null,
      ),
    );
  }

  Future<void> _loadActivityContextForCreate(
    List<Map<String, dynamic>> selectedStudents,
  ) async {
    if (selectedStudents.isEmpty) return;
    final first = selectedStudents.first;
    final dynamic classroomCodeDynamic =
        first['classroomCode'] ?? first['classroomcode'];
    final classroomCode = classroomCodeDynamic is String
        ? classroomCodeDynamic.trim()
        : '';
    if (classroomCode.isEmpty) return;

    try {
      final List<ActivitySetting> settings = await _editor
          .getClassroomActivitySettings(classroomCode: classroomCode);
      ActivitySetting? bottleSetting;
      for (final s in settings) {
        if (s.activityTypeName.toLowerCase().contains('bottle')) {
          bottleSetting = s;
          break;
        }
      }
      if (bottleSetting != null && !isClosed) {
        emit(state.copyWith(activityTypeCode: bottleSetting.activityTypeCode));
      }
    } catch (_) {
      // Best-effort: activity-type code stays null and submit surfaces it.
    }
  }

  Future<void> _prefetchActivityForEdit() async {
    if (!_layoutAsEdit) return;
    final code = _activityData?.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    emit(state.copyWith(loadingActivityDetail: true));
    try {
      final detail = await _editor.getActivity(code: code);
      if (isClosed) return;
      final item = activityItemFromActivityDetail(
        detail,
        viewerDisplayName: state.staffName,
      );
      var staffLabel = _staffDisplayFromParameterRows(detail.parameterValues);
      if (staffLabel == null || staffLabel.isEmpty) {
        final cb = detail.createdBy.trim();
        if (cb.isNotEmpty && cb.toLowerCase() != 'system') {
          staffLabel = cb;
        }
      }
      _staffPresentCode = _staffCodeFromParameterRows(detail.parameterValues);
      final nextIso = item.activityDateIso;
      if (nextIso != null && nextIso.trim().isNotEmpty) {
        try {
          final dt = activityDateTimeForDisplayFromIso(nextIso.trim());
          _activityDate = DateTime(dt.year, dt.month, dt.day);
          _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      final singleStudent = (_activityData?.studentList.length ?? 0) <= 1;
      emit(
        state.copyWith(
          liveActivity: item,
          requireAdminApproval: _isAdminApprovalRequired(item),
          activityTypeCode: item.activityTypeCode,
          staffPresentLabelForEdit: staffLabel,
          detailAttachmentRows: detail.attachments
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          selectedStudents: singleStudent
              ? List<String>.from(item.studentList)
              : null,
          selectedStudentsData: singleStudent
              ? studentDataMapsForActivityEdit(item)
              : null,
          loadingActivityDetail: false,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loadingActivityDetail: false));
    }
  }

  // ─── Form mutations ────────────────────────────────────────────────────────

  void setActivityDate(DateTime? date) => _activityDate = date;
  void setActivityTime(TimeOfDay? time) => _activityTime = time;

  void setStaffPresentCode(String? code) {
    _staffPresentCode = (code ?? '').trim().isNotEmpty
        ? code!.trim()
        : (_staffPresentCode ?? state.staffCode);
  }

  void setRequireAdminApproval(bool value) {
    emit(state.copyWith(requireAdminApproval: value));
  }

  void setScopedEditStudentIndices(Set<int> indices) {
    emit(state.copyWith(scopedEditStudentIndices: Set<int>.from(indices)));
  }

  void removeStudent(String name) {
    final next = List<String>.from(state.selectedStudents)..remove(name);
    final nextData = List<Map<String, dynamic>>.from(state.selectedStudentsData)
      ..removeWhere((m) => (m['name'] as String?) == name);
    emit(
      state.copyWith(selectedStudents: next, selectedStudentsData: nextData),
    );
  }

  Future<bool> verifyPickedStaffSignedIn({
    required bool isEdit,
    required bool isAdminDesignation,
    required String? pickedStaffCode,
    required String? ownStaffCode,
  }) => _editor.verifyPickedStaffSignedIn(
    isEdit: isEdit,
    isAdminDesignation: isAdminDesignation,
    pickedStaffCode: pickedStaffCode,
    ownStaffCode: ownStaffCode,
  );

  // ─── Submit ──────────────────────────────────────────────────────────────

  Future<ActivityFormOutcome> submitCreate({
    required String description,
    required double? amountOz,
    required Future<bool> Function() onValidateAttendanceWindow,
  }) async {
    if (state.isSubmitting) return const ActivityFormOutcome.noop();
    if (_layoutAsEdit) return const ActivityFormOutcome.noop();

    emit(state.copyWith(isSubmitting: true));
    try {
      final preflight = await _preflight(
        amountOz: amountOz,
        description: description,
        onValidateAttendanceWindow: onValidateAttendanceWindow,
      );
      if (preflight != null) return preflight;

      final desc = description.trim();
      final classroomCode = _classroomCodeFromSelection();
      if (classroomCode.isEmpty) {
        return const ActivityFormOutcome.error(
          'Missing classroom information for activity',
        );
      }
      final studentCodes = _studentCodesFromSelection();
      if (studentCodes.isEmpty) {
        return const ActivityFormOutcome.error(
          'Unable to resolve student codes for activity',
        );
      }

      final staffCode = state.staffCode ?? await resolveLoggedInStaffCode();
      final schoolCode = state.schoolCode;
      final organizationCode = state.organizationCode;
      if (staffCode == null ||
          schoolCode == null ||
          organizationCode == null ||
          staffCode.isEmpty ||
          schoolCode.isEmpty ||
          organizationCode.isEmpty) {
        return const ActivityFormOutcome.error(
          'Missing staff or school information. Please re-login and try again.',
        );
      }

      final activityTypeCode = state.activityTypeCode;
      if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
        return _typeError;
      }

      if (_createdFromSelection) {
        final prefilled = resolveSelectedAttendanceDate(
          state.selectedStudentsData,
        );
        if (prefilled != null) _activityDate = prefilled;
      }
      final resolvedActivityTime = await resolveActivityDateTime(
        date: _activityDate!,
        time: _activityTime!,
      );
      final activityDateIso = resolvedActivityTime.iso;

      final details = await _editor.getActivityTypeDetails(
        code: activityTypeCode,
      );
      final parameterValues = _buildParameterValues(
        details,
        desc,
        staffCode,
        amountOz!,
        resolvedActivityTime.localTimeHms,
      );

      final message = await _editor.createActivity(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: desc,
        requireAdminApproval: state.showRequireAdminApprovalToggle
            ? state.requireAdminApproval
            : false,
        parameterValues: parameterValues,
        attachments: const [],
      );
      return ActivityFormOutcome.successExit(message);
    } catch (e) {
      return ActivityFormOutcome.error(ApiErrorHandler.extractErrorMessage(e));
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<ActivityFormOutcome> submitUpdate({
    required String description,
    required double? amountOz,
    required Future<bool> Function() onValidateAttendanceWindow,
  }) {
    return _runUpdate(
      description: description,
      amountOz: amountOz,
      onValidateAttendanceWindow: onValidateAttendanceWindow,
    );
  }

  Future<ActivityFormOutcome> _runUpdate({
    required String description,
    required double? amountOz,
    required Future<bool> Function() onValidateAttendanceWindow,
  }) async {
    if (state.isSubmitting) return const ActivityFormOutcome.noop();
    if (_readOnly) return const ActivityFormOutcome.noop();

    emit(state.copyWith(isSubmitting: true));
    try {
      final fallbackActivityCode = effectiveActivity.activityCode?.trim();

      final preflight = await _preflight(
        amountOz: amountOz,
        description: description,
        onValidateAttendanceWindow: onValidateAttendanceWindow,
      );
      if (preflight != null) return preflight;

      final desc = description.trim();
      final classroomCode = _classroomCodeFromSelection();
      if (classroomCode.isEmpty) {
        return const ActivityFormOutcome.error(
          'Missing classroom information for activity',
        );
      }
      final studentCodes = _studentCodesFromSelection();
      if (studentCodes.isEmpty) {
        return const ActivityFormOutcome.error(
          'Unable to resolve student codes for activity',
        );
      }

      final staffCode = state.staffCode ?? await resolveLoggedInStaffCode();
      final schoolCode = state.schoolCode;
      final organizationCode = state.organizationCode;
      if (staffCode == null ||
          schoolCode == null ||
          organizationCode == null ||
          staffCode.isEmpty ||
          schoolCode.isEmpty ||
          organizationCode.isEmpty) {
        return const ActivityFormOutcome.error(
          'Missing staff or school information. Please re-login and try again.',
        );
      }

      final activityTypeCode = state.activityTypeCode;
      if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
        return _typeError;
      }

      final resolvedActivityTime = await resolveActivityDateTime(
        date: _activityDate!,
        time: _activityTime!,
      );
      final activityDateIso = resolvedActivityTime.iso;

      final details = await _editor.getActivityTypeDetails(
        code: activityTypeCode,
      );
      final parameterValues = _buildParameterValues(
        details,
        desc,
        staffCode,
        amountOz!,
        resolvedActivityTime.localTimeHms,
      );

      final remainingNorm = imageDeliveryUrlsFromAttachmentRows(
        state.detailAttachmentRows,
      ).map(normalizeActivityDeliveryUrl).where((e) => e.isNotEmpty).toSet();
      final legacyPhoto = effectiveActivity.photoUrl?.trim();
      if (legacyPhoto != null && legacyPhoto.isNotEmpty) {
        final n = normalizeActivityDeliveryUrl(legacyPhoto);
        if (n.isNotEmpty) remainingNorm.add(n);
      }
      final mergedRows = mergeAttachmentRowsForEditPatch(
        existingRows: state.detailAttachmentRows
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        newUploadRows: const [],
        remainingNormalizedDeliveryUrls: remainingNorm,
      );
      final patchAttachments = attachmentsForActivityPatchRequest(mergedRows);

      final targets = studentMapsForScopedActivityUpdate(
        allStudentMaps: state.selectedStudentsData,
        checkedIndices: state.scopedEditStudentIndices,
      );
      String? lastMessage;
      for (final m in targets) {
        final code =
            (m['activityCode'] as String?)?.trim() ?? fallbackActivityCode;
        if (code == null || code.isEmpty) {
          return const ActivityFormOutcome.error(
            'Missing activity reference for a student. Refresh the feed and try again.',
          );
        }
        lastMessage = await _editor.updateActivity(
          code: code,
          studentCodes: state.selectedStudentsData
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
          description: desc,
          parameterValues: parameterValues,
          attachments: patchAttachments,
        );
      }
      return ActivityFormOutcome.successExit(lastMessage ?? 'Updated');
    } catch (e) {
      return ActivityFormOutcome.error(ApiErrorHandler.extractErrorMessage(e));
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<ActivityFormOutcome> approve({
    required String description,
    required double? amountOz,
    required Future<bool> Function() onValidateAttendanceWindow,
  }) async {
    final code = effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return const ActivityFormOutcome.noop();
    emit(
      state.copyWith(isSavingBeforeApprove: true, isApprovingOrRejecting: true),
    );
    try {
      final updated = await _runUpdate(
        description: description,
        amountOz: amountOz,
        onValidateAttendanceWindow: onValidateAttendanceWindow,
      );
      if (updated.type != ActivityFormResultType.successExit) return updated;
      final msg = await _editor.approveActivity(code: code);
      return ActivityFormOutcome.successPop(msg);
    } catch (e) {
      return ActivityFormOutcome.error(ApiErrorHandler.extractErrorMessage(e));
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            isSavingBeforeApprove: false,
            isApprovingOrRejecting: false,
          ),
        );
      }
    }
  }

  Future<ActivityFormOutcome> reject() async {
    final code = effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return const ActivityFormOutcome.noop();
    emit(state.copyWith(isApprovingOrRejecting: true));
    try {
      final msg = await _editor.rejectActivity(code: code);
      return ActivityFormOutcome.successPop(msg);
    } catch (e) {
      return ActivityFormOutcome.error(ApiErrorHandler.extractErrorMessage(e));
    } finally {
      if (!isClosed) emit(state.copyWith(isApprovingOrRejecting: false));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static const _typeError = ActivityFormOutcome.error(
    'Unable to determine activity type for Bottle. Please check activity settings.',
  );

  /// Shared front-of-submit validation (students, attendance window, amount,
  /// optional description, date/time). Returns a non-null outcome to abort.
  Future<ActivityFormOutcome?> _preflight({
    required double? amountOz,
    required String description,
    required Future<bool> Function() onValidateAttendanceWindow,
  }) async {
    if (state.selectedStudents.isEmpty) {
      return const ActivityFormOutcome.warning(
        'Please select at least one student',
      );
    }
    if (!await onValidateAttendanceWindow()) {
      return const ActivityFormOutcome.noop();
    }
    if (amountOz == null) {
      return const ActivityFormOutcome.warning(
        'Please enter a valid amount (0.5 – 20.0 oz)',
      );
    }
    final desc = description.trim();
    if (desc.isNotEmpty && desc.length > ActivityDescriptionLimits.maxLength) {
      return ActivityFormOutcome.warning(
        ActivityDescriptionLimits.maxLengthMessage,
      );
    }
    if (_activityDate == null || _activityTime == null) {
      return const ActivityFormOutcome.warning('Please select date and time');
    }
    return null;
  }

  String _classroomCodeFromSelection() {
    final classroomCodeDynamic =
        state.selectedStudentsData.first['classroomCode'] ??
        state.selectedStudentsData.first['classroomcode'];
    return classroomCodeDynamic is String ? classroomCodeDynamic.trim() : '';
  }

  List<String> _studentCodesFromSelection() {
    return state.selectedStudentsData
        .map((s) => (s['studentCode'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();
  }

  List<ActivityParameterValue> _buildParameterValues(
    dynamic details,
    String description,
    String staffCode,
    double amountOz,
    String localTimeHms,
  ) {
    String? findParamCode(String contains) {
      final target = contains.toLowerCase();
      for (final p in details.parameters) {
        if (p.parameterName.toLowerCase().contains(target)) return p.code;
      }
      return null;
    }

    final dateParamCode = findParamCode('date');
    final timeParamCode = findParamCode('time');
    final staffParamCode = findParamCode('staff');
    final descParamCode = findParamCode('description');
    final amountParamCode =
        findParamCode('amount') ??
        findParamCode('ounce') ??
        findParamCode('oz') ??
        findParamCode('consumed');

    String two(int v) => v.toString().padLeft(2, '0');
    final localDate =
        '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
    final localTime = localTimeHms;
    final staffPresentCode = (_staffPresentCode ?? staffCode).trim();

    return <ActivityParameterValue>[
      if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
        ActivityParameterValue(parameterCode: dateParamCode, value: localDate),
      if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
        ActivityParameterValue(parameterCode: timeParamCode, value: localTime),
      if (staffParamCode != null &&
          staffParamCode.trim().isNotEmpty &&
          staffPresentCode.isNotEmpty)
        ActivityParameterValue(
          parameterCode: staffParamCode,
          value: staffPresentCode,
        ),
      if (descParamCode != null &&
          descParamCode.trim().isNotEmpty &&
          description.isNotEmpty)
        ActivityParameterValue(
          parameterCode: descParamCode,
          value: description,
        ),
      if (amountParamCode != null && amountParamCode.trim().isNotEmpty)
        ActivityParameterValue(
          parameterCode: amountParamCode,
          value: amountOz.toString(),
        ),
    ];
  }
}
