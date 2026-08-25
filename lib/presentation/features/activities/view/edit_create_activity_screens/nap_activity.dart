import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import '../../../../../app/di/di.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/api_error_handler.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../core/util/user_details_school_roles.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/entities/activity_type_details.dart';
import '../../cubit/activity_editor_cubit.dart';
import '../../cubit/nap_activity_cubit.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../utils/activity_description_limits.dart';
import '../../utils/activity_selected_date_prefill.dart';
import '../utils/activity_attendance_window_validator.dart';
import '../../utils/activity_school_time.dart';
import '../../utils/activity_staff_display.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../../widgets/activity_edit_student_scope_checkboxes.dart';
import '../../widgets/activity_student_display_tile.dart';
import '../activity_daily_tab.dart';
import '../widgets/activity_admin_approve_reject_bar.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class NapActivityScreen extends StatelessWidget {
  const NapActivityScreen({
    super.key,
    this.selectedStudents,
    this.activityData,
    this.isEdit = false,
    this.readOnly = false,
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ActivityEditorCubit>(
          create: (_) => serviceLocator<ActivityEditorCubit>(),
        ),
        BlocProvider<NapActivityCubit>(
          create: (_) => serviceLocator<NapActivityCubit>(),
        ),
      ],
      child: _NapActivityView(
        selectedStudents: selectedStudents,
        isEdit: isEdit,
        activityData: activityData,
        readOnly: readOnly,
      ),
    );
  }
}

class _NapActivityView extends StatefulWidget {
  const _NapActivityView({
    this.selectedStudents,
    this.activityData,
    this.isEdit = false,
    this.readOnly = false,
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  final bool readOnly;

  @override
  State<_NapActivityView> createState() => _NapActivityViewState();
}

class _NapActivityViewState extends State<_NapActivityView> {
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
  bool get _showRequireAdminApprovalToggle => !_isAdminDesignation;

  List<Map<String, dynamic>> _selectedStudentsData = [];
  List<String> _selectedStudents = [];
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _activityDate;
  TimeOfDay? _activityTime;

  String? _activityTypeCode;
  String _staffName = '';
  String _staffType = '';
  bool _requireAdminApproval = false;
  String? _staffCode;
  String? _staffPresentCode;
  String? _schoolCode;
  String? _organizationCode;
  String? _currentUserCode;
  String? _currentUserRole;
  bool _isSubmitting = false;
  bool _isApprovingOrRejecting = false;
  bool _isSavingBeforeApprove = false;
  bool _lastUpdateSucceeded = false;
  bool _loadingActivityDetail = false;

  /// Nap start only — persisted when activity type defines a matching BOOLEAN param.
  bool _remindCheckNapEvery15Minutes = true;
  ActivityItem? _liveActivity;
  final Set<int> _scopedEditStudentIndices = {};

  ActivityEditorCubit get _editor => context.read<ActivityEditorCubit>();
  NapActivityCubit get _napCubit => context.read<NapActivityCubit>();

  ActivityItem get _effectiveActivity => _liveActivity ?? widget.activityData!;
  bool _isAdminApprovalRequired(ActivityItem activity) {
    final status = (activity.approvalStatus ?? '').trim().toUpperCase();
    return status.isNotEmpty && status != 'NOT_REQUIRED';
  }

  String? _pickStaffPresentCode(List<Map<String, dynamic>> rows) {
    for (final p in rows) {
      final n = (p['parameterName'] ?? '').toString().trim().toLowerCase();
      if (n != 'staff present') continue;
      final v =
          (p['selectedOptionCode'] ?? p['valueText'] ?? p['valueNumber'] ?? '')
              .toString()
              .trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    bootstrapActivitySchoolTimezone();

    if (_layoutAsEdit && widget.activityData != null) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _requireAdminApproval = _isAdminApprovalRequired(activity);
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);

      _descriptionController.text = activity.description ?? '';
      _activityTypeCode = activity.activityTypeCode;
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
    } else {
      // Create flow: do not seed from [lastKnownTimeZone] before async bootstrap
      // finishes (same as Meal). Let [DateWidget]/[TimeWidget] apply school zone,
      // or use [attendanceDate] from student maps when present.
      _activityDate = null;
      _activityTime = null;
      if (widget.selectedStudents != null) {
        _selectedStudentsData = List.from(widget.selectedStudents!);
        _selectedStudents = _selectedStudentsData
            .map((s) => s['name'] as String)
            .toList();
        _activityDate = resolveSelectedAttendanceDate(_selectedStudentsData);
        _loadActivityContextForCreate();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncSchoolAttendanceDateForCreate();
        });
      } else {
        _selectedStudentsData = [];
        _selectedStudents = [];
      }
    }

    _loadStaffContext();
  }

  Future<void> _syncSchoolAttendanceDateForCreate() async {
    if (!mounted || _layoutAsEdit) return;
    if (_selectedStudentsData.isEmpty) return;
    await ensureAttendanceDateOnStudentMapsForSchoolToday(
      _selectedStudentsData,
    );
    if (!mounted) return;
    setState(() {
      _activityDate = resolveSelectedAttendanceDate(_selectedStudentsData);
    });
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
    final code = _effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() {
      _isSavingBeforeApprove = true;
      _isApprovingOrRejecting = true;
    });
    try {
      await _submitUpdateActivity();
      if (!_lastUpdateSucceeded) return;
      final msg = await _editor.approveActivity(code: code);
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
    final code = _effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _isApprovingOrRejecting = true);
    try {
      final msg = await _editor.rejectActivity(code: code);
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

  Future<void> _prefetchActivityForEdit() async {
    if (!_layoutAsEdit || !mounted) return;
    final code = widget.activityData?.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _loadingActivityDetail = true);
    try {
      final detail = await _editor.getActivity(code: code);
      if (!mounted) return;
      ActivityTypeDetails? typeDetailsForRemind;
      final tc = detail.activityTypeCode.trim();
      if (tc.isNotEmpty) {
        try {
          typeDetailsForRemind = await _editor.getActivityTypeDetails(code: tc);
        } catch (_) {}
      }
      final item = activityItemFromActivityDetail(
        detail,
        viewerDisplayName: _staffName,
      );
      setState(() {
        _liveActivity = item;
        _requireAdminApproval = _isAdminApprovalRequired(item);
        if ((widget.activityData?.studentList.length ?? 0) <= 1) {
          _selectedStudents = List<String>.from(item.studentList);
          _selectedStudentsData = studentDataMapsForActivityEdit(item);
        }
        _descriptionController.text = item.description ?? '';
        _activityTypeCode = item.activityTypeCode;
        _staffPresentCode = _pickStaffPresentCode(detail.parameterValues);
        final nextIso = item.activityDateIso;
        if (nextIso != null && nextIso.trim().isNotEmpty) {
          try {
            final dt = activityDateTimeForDisplayFromIso(nextIso.trim());
            _activityDate = DateTime(dt.year, dt.month, dt.day);
            _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
          } catch (_) {}
        }
        if (typeDetailsForRemind != null &&
            !_napEventIsEnd(detail.activityTypeName)) {
          final remindCode = _resolveRemindNap15ParamCode(typeDetailsForRemind);
          if (remindCode != null && remindCode.isNotEmpty) {
            for (final pv in detail.parameterValues) {
              final pc = (pv['parameterCode'] ?? '').toString().trim();
              if (pc != remindCode) continue;
              final v = pv['value'];
              if (v is bool) {
                _remindCheckNapEvery15Minutes = v;
              } else if (v is num) {
                _remindCheckNapEvery15Minutes = v != 0;
              } else {
                final s = v?.toString().toLowerCase() ?? '';
                _remindCheckNapEvery15Minutes =
                    s == 'true' || s == '1' || s == 'yes';
              }
              break;
            }
          }
        }
      });
    } catch (e) {
      CoreUtils.logApiError('Prefetch activity for edit: $e');
    } finally {
      if (mounted) setState(() => _loadingActivityDetail = false);
    }
  }

  Future<void> _loadStaffContext() async {
    final storage = serviceLocator<StorageService>();
    final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
        .trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final organizationCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final staffCode = await resolveLoggedInStaffCode();
    final apiDisplayName = await resolveLoggedInStaffDisplayNameFromApi(
      staffCode: staffCode,
    );
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final activeRole = await resolveActiveBackendRole(storage);

    if (!mounted) return;
    setState(() {
      _staffName = apiDisplayName.isNotEmpty ? apiDisplayName : 'Staff';
      _staffType = staffType.toUpperCase();
      _staffCode = staffCode;
      _staffPresentCode = (staffCode ?? '').trim().isEmpty
          ? null
          : staffCode!.trim();
      _schoolCode = schoolCode.isNotEmpty ? schoolCode : null;
      _organizationCode = organizationCode.isNotEmpty ? organizationCode : null;
      _currentUserCode = userCode.isNotEmpty ? userCode : null;
      _currentUserRole = activeRole.trim().isNotEmpty
          ? activeRole.trim().toUpperCase()
          : null;
    });
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
      final List<ActivitySetting> settings = await _editor
          .getClassroomActivitySettings(classroomCode: classroomCode);
      ActivitySetting? napSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('nap')) {
          napSetting = s;
          break;
        }
      }
      if (napSetting != null && mounted) {
        setState(() {
          _activityTypeCode = napSetting!.activityTypeCode;
        });
      }
    } catch (e) {
      CoreUtils.logApiError('Failed to load activity settings for Nap: $e');
    }
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  /// Nap end / wake / stop style events → nap end `true`, nap start `false`.
  /// Otherwise (start or generic "Nap") → nap start `true`, nap end `false`.
  static bool _napEventIsEnd(String activityTypeName) {
    final s = activityTypeName.toLowerCase().trim();
    if (s.isEmpty) return false;
    return s.contains('end') ||
        s.contains('wake') ||
        s.contains('stop') ||
        s.contains('finished');
  }

  static String? _findBooleanParamCode(
    ActivityTypeDetails details,
    bool Function(String lowerName) matchName,
  ) {
    for (final p in details.parameters) {
      final dt = (p.dataType ?? '').toUpperCase();
      if (dt != 'BOOLEAN' && dt != 'BOOL') continue;
      final n = p.parameterName.toLowerCase();
      if (!matchName(n)) continue;
      final c = p.code.trim();
      if (c.isNotEmpty) return c;
    }
    return null;
  }

  /// Sends nap start / nap end as JSON booleans on matching BOOLEAN parameters.
  static void _appendNapStartEndBooleans(
    ActivityTypeDetails details,
    List<Map<String, dynamic>> parameterValues,
    bool isNapEnd,
  ) {
    final napStartFlag = !isNapEnd;
    final napEndFlag = isNapEnd;

    String? startCode = _findBooleanParamCode(
      details,
      (n) =>
          n.contains('nap') &&
          (n.contains('start') || n.contains('begin')) &&
          !n.contains('end'),
    );
    startCode ??= _findBooleanParamCode(
      details,
      (n) => n.contains('start') && n.contains('nap'),
    );

    String? endCode = _findBooleanParamCode(
      details,
      (n) =>
          n.contains('nap') &&
          (n.contains('end') || n.contains('wake') || n.contains('stop')),
    );
    endCode ??= _findBooleanParamCode(
      details,
      (n) => n.contains('end') && n.contains('nap'),
    );

    if (startCode != null && endCode != null && startCode == endCode) {
      return;
    }
    if (startCode != null && startCode.isNotEmpty) {
      parameterValues.add({'parameterCode': startCode, 'value': napStartFlag});
    }
    if (endCode != null && endCode.isNotEmpty) {
      parameterValues.add({'parameterCode': endCode, 'value': napEndFlag});
    }
  }

  /// BOOLEAN parameter for “remind / 15 min / check nap” style fields from activity settings.
  String? _resolveRemindNap15ParamCode(ActivityTypeDetails details) {
    for (final p in details.parameters) {
      final dt = (p.dataType ?? '').toUpperCase();
      if (dt != 'BOOLEAN' && dt != 'BOOL') continue;
      final n = p.parameterName.toLowerCase();
      final matches =
          (n.contains('remind') &&
              (n.contains('15') ||
                  n.contains('minute') ||
                  n.contains('min'))) ||
          (n.contains('check') &&
              n.contains('nap') &&
              (n.contains('15') ||
                  n.contains('remind') ||
                  n.contains('minute')));
      if (matches) {
        final c = p.code.trim();
        if (c.isNotEmpty) return c;
      }
    }
    return null;
  }

  void _appendRemindNap15IfNapStart(
    ActivityTypeDetails details,
    List<Map<String, dynamic>> parameterValues,
    bool isNapEnd,
  ) {
    if (isNapEnd) return;
    final code = _resolveRemindNap15ParamCode(details);
    if (code == null || code.isEmpty) return;
    parameterValues.add({
      'parameterCode': code,
      'value': _remindCheckNapEvery15Minutes,
    });
  }

  Future<bool?> _resolveNapEndFromCurrentStatus({
    required String classroomCode,
    required List<String> studentCodes,
  }) async {
    final nappingCodes = await _napCubit.getNapStartStudents(
      classroomCode: classroomCode,
    );
    final nappingSet = nappingCodes.map((e) => e.trim()).toSet();
    final selectedSet = studentCodes.map((e) => e.trim()).toSet();
    final nappingSelectedCount = selectedSet
        .where((code) => nappingSet.contains(code))
        .length;

    if (nappingSelectedCount > 0 && nappingSelectedCount < selectedSet.length) {
      if (!mounted) return null;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Selected students have mixed nap states. Select students with same nap state.',
        isWarning: true,
      );
      return null;
    }
    return nappingSelectedCount == selectedSet.length;
  }

  static bool _isStudentMapNapping(Map<String, dynamic> student) {
    final dynamic raw = student['nappingStatus'] ?? student['isNapping'];
    if (raw == true) return true;
    if (raw is String && raw.toLowerCase() == 'true') return true;
    return false;
  }

  bool? _resolveNapEndFromSelectedStudentsData() {
    if (_selectedStudentsData.isEmpty) return null;
    var hasNapping = false;
    var hasNotNapping = false;

    for (final student in _selectedStudentsData) {
      if (_isStudentMapNapping(student)) {
        hasNapping = true;
      } else {
        hasNotNapping = true;
      }
      if (hasNapping && hasNotNapping) {
        return null;
      }
    }

    // If all selected students are currently napping, this event is nap end.
    return hasNapping && !hasNotNapping;
  }

  Future<bool?> _resolveNapEndForCreate({
    required String classroomCode,
    required List<String> studentCodes,
  }) async {
    final fromSelection = _resolveNapEndFromSelectedStudentsData();
    if (fromSelection != null) {
      return fromSelection;
    }
    return _resolveNapEndFromCurrentStatus(
      classroomCode: classroomCode,
      studentCodes: studentCodes,
    );
  }

  String _timeLabelForCurrentContext() {
    if (_layoutAsEdit) return 'Time';
    final fromSelection = _resolveNapEndFromSelectedStudentsData();
    if (fromSelection == true) return 'End Time';
    if (fromSelection == false) return 'Start Time';
    return 'Time';
  }

  bool _isNapEndContextForUi() {
    if (_layoutAsEdit) {
      return _effectiveActivity.name == 'Nap End';
    }
    return _resolveNapEndFromSelectedStudentsData() == true;
  }

  String _descriptionLabelForContext() {
    return _isNapEndContextForUi() ? 'Nap End' : 'Description';
  }

  String _descriptionHintForContext() {
    return _isNapEndContextForUi() ? 'Nap Ended' : 'Enter Description';
  }

  Future<void> _submitCreateActivity() async {
    if (_isSubmitting) return;
    if (_layoutAsEdit) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      if (_selectedStudents.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select at least one student',
          isWarning: true,
        );
        return;
      }
      final isWithinAttendanceWindow =
          await validateStudentsWithinAttendanceWindow(
            context: context,
            students: _selectedStudentsData,
            selectedDate: _activityDate,
            selectedTime: _activityTime,
          );
      if (!isWithinAttendanceWindow) return;

      final enteredDescription = _descriptionController.text.trim();
      var description = enteredDescription;
      if (description.length > ActivityDescriptionLimits.maxLength) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: ActivityDescriptionLimits.maxLengthMessage,
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

      final studentCodes = _selectedStudentsData
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
              'Unable to determine activity type for Nap. Please check activity settings.',
          isError: true,
        );
        return;
      }

      final details = await _editor.getActivityTypeDetails(
        code: activityTypeCode,
      );

      String? findParamCode(String contains) {
        final target = contains.toLowerCase();
        for (final p in details.parameters) {
          final name = p.parameterName.toLowerCase();
          if (name.contains(target)) return p.code;
        }
        return null;
      }

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      final localDate =
          '${_activityDate!.year}-${_two(_activityDate!.month)}-${_two(_activityDate!.day)}';
      final staffPresentCode = ((_staffPresentCode ?? staffCode).trim());

      // Ensure the API payload uses the attendance date chosen on student selection.
      final prefilled = widget.selectedStudents != null
          ? resolveSelectedAttendanceDate(_selectedStudentsData)
          : null;
      if (prefilled != null) {
        _activityDate = prefilled;
      }
      final resolvedActivityTime = await resolveActivityDateTime(
        date: _activityDate!,
        time: _activityTime!,
      );
      final activityDateIso = resolvedActivityTime.iso;
      final localTime = resolvedActivityTime.localTimeHms;

      final parameterValues = <Map<String, dynamic>>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          {'parameterCode': dateParamCode, 'value': localDate},
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          {'parameterCode': timeParamCode, 'value': localTime},
        if (staffParamCode != null &&
            staffParamCode.trim().isNotEmpty &&
            staffPresentCode.isNotEmpty)
          {'parameterCode': staffParamCode, 'value': staffPresentCode},
        if (descParamCode != null &&
            descParamCode.trim().isNotEmpty &&
            description.isNotEmpty)
          {'parameterCode': descParamCode, 'value': description},
      ];

      final isNapEnd = await _resolveNapEndForCreate(
        classroomCode: classroomCode,
        studentCodes: studentCodes,
      );
      if (isNapEnd == null) return;
      if (description.isEmpty) {
        description = isNapEnd ? 'Nap Ended' : 'Nap Started';
      }
      _appendNapStartEndBooleans(details, parameterValues, isNapEnd);
      _appendRemindNap15IfNapStart(details, parameterValues, isNapEnd);

      final message = await _editor.createActivity(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: description,
        napStart: !isNapEnd,
        napEnd: isNapEnd,
        // Reminder only applies to starting a nap — mirrors the "Remind to
        // check nap every 15 minutes" checkbox above, which is likewise
        // hidden for nap end (_isNapEndContextForUi()).
        napReminderEnabled: isNapEnd ? null : _remindCheckNapEvery15Minutes,
        napReminderUserCode: isNapEnd ? null : _currentUserCode,
        napReminderRole: isNapEnd ? null : _currentUserRole,
        requireAdminApproval: _showRequireAdminApprovalToggle
            ? _requireAdminApproval
            : false,
        parameterValues: parameterValues,
        attachments: const [],
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
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
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
    setState(() => _isSubmitting = true);
    try {
      final fallbackActivityCode = _effectiveActivity.activityCode?.trim();

      if (_selectedStudents.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select at least one student',
          isWarning: true,
        );
        return;
      }
      final isWithinAttendanceWindow =
          await validateStudentsWithinAttendanceWindow(
            context: context,
            students: _selectedStudentsData,
            selectedDate: _activityDate,
            selectedTime: _activityTime,
          );
      if (!isWithinAttendanceWindow) return;

      final description = _descriptionController.text.trim();
      if (description.length > ActivityDescriptionLimits.maxLength) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: ActivityDescriptionLimits.maxLengthMessage,
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

      var staffCode = _staffCode ?? await resolveLoggedInStaffCode();
      if (staffCode == null || staffCode.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Missing staff information. Please re-login and try again.',
          isError: true,
        );
        return;
      }

      final activityTypeCode = _activityTypeCode;
      if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message:
              'Unable to determine activity type for Nap. Please check activity settings.',
          isError: true,
        );
        return;
      }

      final resolvedActivityTime = await resolveActivityDateTime(
        date: _activityDate!,
        time: _activityTime!,
      );
      final activityDateIso = resolvedActivityTime.iso;

      final details = await _editor.getActivityTypeDetails(
        code: activityTypeCode,
      );

      String? findParamCode(String contains) {
        final target = contains.toLowerCase();
        for (final p in details.parameters) {
          final name = p.parameterName.toLowerCase();
          if (name.contains(target)) return p.code;
        }
        return null;
      }

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      final localDate =
          '${_activityDate!.year}-${_two(_activityDate!.month)}-${_two(_activityDate!.day)}';
      final localTime = resolvedActivityTime.localTimeHms;
      final staffPresentCode = ((_staffPresentCode ?? staffCode).trim());

      final parameterValues = <Map<String, dynamic>>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          {'parameterCode': dateParamCode, 'value': localDate},
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          {'parameterCode': timeParamCode, 'value': localTime},
        if (staffParamCode != null &&
            staffParamCode.trim().isNotEmpty &&
            staffPresentCode.isNotEmpty)
          {'parameterCode': staffParamCode, 'value': staffPresentCode},
        if (descParamCode != null &&
            descParamCode.trim().isNotEmpty &&
            description.isNotEmpty)
          {'parameterCode': descParamCode, 'value': description},
      ];

      _appendNapStartEndBooleans(
        details,
        parameterValues,
        _napEventIsEnd(_effectiveActivity.name),
      );
      _appendRemindNap15IfNapStart(
        details,
        parameterValues,
        _napEventIsEnd(_effectiveActivity.name),
      );

      final targets = studentMapsForScopedActivityUpdate(
        allStudentMaps: _selectedStudentsData,
        checkedIndices: _scopedEditStudentIndices,
      );
      String? lastMessage;
      for (final m in targets) {
        final code =
            (m['activityCode'] as String?)?.trim() ?? fallbackActivityCode;
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
        lastMessage = await _editor.updateActivity(
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
          description: description,
          parameterValues: parameterValues,
          attachments: const [],
        );
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

  Future<void> _onPressedBottom() async {
    if (_isSubmitting) return;
    if (widget.readOnly) return;

    // Admin picked a staff member other than themselves on create: verify
    // that staff is signed in right now, same use case + true/false check the
    // staff persona's own + button is gated on. Admins are never gated on
    // their OWN sign-in — only on who they're attributing the activity to.
    if (!await _editor.verifyPickedStaffSignedIn(
      isEdit: widget.isEdit,
      isAdminDesignation: _isAdminDesignation,
      pickedStaffCode: _staffPresentCode,
      ownStaffCode: _staffCode,
    )) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Staff is not signed in. You can only add an activity for '
            'staff who are signed in.',
        isWarning: true,
      );
      return;
    }

    if (widget.isEdit) {
      await _submitUpdateActivity();
      return;
    }

    await _submitCreateActivity();
  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);
      _selectedStudentsData.removeWhere((s) => s['name'] == name);

      if (_selectedStudents.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }

  String? _prefilledTimeForEdit() {
    final a = _effectiveActivity;
    if (a.time.trim().isNotEmpty) return a.time;
    if (a.napStartTime != null && a.napStartTime!.trim().isNotEmpty) {
      return a.napStartTime;
    }
    if (a.napEndTime != null && a.napEndTime!.trim().isNotEmpty) {
      return a.napEndTime;
    }
    return null;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: _layoutAsEdit ? (_effectiveActivity.name) : 'Nap',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AbsorbPointer(
          absorbing:
              _isSubmitting ||
              _isApprovingOrRejecting ||
              _loadingActivityDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
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
                    mainAxisExtent: 64,
                  ),
                  itemCount: _selectedStudents.length,
                  itemBuilder: (context, index) {
                    return ActivityStudentDisplayTile(
                      name: _selectedStudents[index],
                      studentCode: index < _selectedStudentsData.length
                          ? _selectedStudentsData[index]['studentCode']
                                as String?
                          : null,
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
                    mainAxisExtent: 64,
                  ),
                  itemCount: _selectedStudents.length,
                  itemBuilder: (context, index) {
                    final String name = _selectedStudents[index];
                    return ActivityStudentDisplayTile(
                      name: name,
                      studentCode: index < _selectedStudentsData.length
                          ? _selectedStudentsData[index]['studentCode']
                                as String?
                          : null,
                      onRemove: () => _removeStudent(name),
                    );
                  },
                ),
              if (widget.isEdit &&
                  !widget.readOnly &&
                  _selectedStudents.length > 1) ...[
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
              SizedBox(height: responsive.verticalSpacing),
              Row(
                children: [
                  Flexible(
                    child: _layoutAsEdit
                        ? DateWidget(
                            isEditable: false,
                            isRequired: true,
                            initialDate: _effectiveActivity.date,
                            onDateChanged: (d) {
                              setState(() {
                                _activityDate = d;
                              });
                            },
                          )
                        : DateWidget(
                            key: ValueKey<String>(
                              formatSelectedDateForDateWidget(_activityDate) ??
                                  'school_date',
                            ),
                            isEditable: false,
                            isRequired: true,
                            initialDate: formatSelectedDateForDateWidget(
                              _activityDate,
                            ),
                            onDateChanged: (d) {
                              setState(() {
                                _activityDate = d;
                              });
                            },
                          ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: _layoutAsEdit
                        ? TimeWidget(
                            label: _timeLabelForCurrentContext(),
                            isEditable: _canInteract,
                            isRequired: true,
                            prefilledTime: _prefilledTimeForEdit(),
                            onTimeChanged: (t) {
                              setState(() {
                                _activityTime = t;
                              });
                            },
                          )
                        : TimeWidget(
                            label: _timeLabelForCurrentContext(),
                            isRequired: true,
                            isEditable: true,
                            onTimeChanged: (t) {
                              setState(() {
                                _activityTime = t;
                              });
                            },
                          ),
                  ),
                ],
              ),
              const ActivitySchoolTimeZoneHint(),
              if (!_isNapEndContextForUi()) ...[
                SizedBox(height: responsive.verticalSpacing * 0.6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CustomCheckbox(
                      value: _remindCheckNapEvery15Minutes,
                      onChanged: !_canInteract
                          ? null
                          : (v) {
                              setState(() {
                                _remindCheckNapEvery15Minutes = v ?? false;
                              });
                            },
                      label: 'Remind to check nap every 15 minutes',
                      labelStyle: AppTextStyles.body.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: responsive.verticalSpacing),
              Builder(
                builder: (context) {
                  final isAdminPersona = _isAdminDesignation;
                  final lockToLoggedInStaff = _canInteract && !isAdminPersona;
                  return StaffPresentWidget(
                    staffName: staffPresentLabelForActivity(
                      layoutAsEdit: _layoutAsEdit,
                      activityCreatedBy: '',
                      loggedInDisplayName: _staffName,
                      staffLabelFromParameters: _layoutAsEdit
                          ? (((_staffPresentCode ?? '').trim().isNotEmpty)
                                ? _staffPresentCode
                                : _effectiveActivity.staffPresent)
                          : null,
                    ),
                    isEditable: lockToLoggedInStaff ? false : _canInteract,
                    onStaffChanged: (_, selectedCode) {
                      _staffPresentCode = (selectedCode ?? '').trim().isNotEmpty
                          ? selectedCode!.trim()
                          : (_staffPresentCode ?? _staffCode);
                    },
                  );
                },
              ),
              SizedBox(height: responsive.verticalSpacing),
              InputWidget(
                controller: _descriptionController,
                height: 100,
                label: _descriptionLabelForContext(),
                hint: _descriptionHintForContext(),
                isRequired: false,
                readOnly: !_canInteract,
                maxLength: ActivityDescriptionLimits.maxLength,
              ),
              if (_showRequireAdminApprovalToggle) const SizedBox(height: 4),
              if (_showRequireAdminApprovalToggle)
                CustomToggle(
                  label: 'Requires Admin Approval',
                  isToggled: _requireAdminApproval,
                  labelOnLeftSide: true,
                  enabled: !_layoutAsEdit,
                  onToggle: (value) {
                    setState(() {
                      _requireAdminApproval = value;
                    });
                  },
                ),
              SizedBox(height: responsive.verticalSpacing),
            ],
          ),
        ),
      ),
      bottomBar: widget.readOnly
          ? const SafeArea(child: SizedBox.shrink())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActivityAdminApproveRejectBar(
                      visible: _showAdminApproveRejectActions,
                      isLoading:
                          _isApprovingOrRejecting ||
                          _isSubmitting ||
                          _loadingActivityDetail,
                      onApprove: _approvePendingActivity,
                      onReject: _rejectPendingActivity,
                    ),
                    if (!_showAdminApproveRejectActions)
                      CustomButtonLayout(
                        confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                        onPressedConfirm: _onPressedBottom,
                        showCancelButton: false,
                        isForm: false,
                        isLoading:
                            _isSubmitting ||
                            _isApprovingOrRejecting ||
                            _loadingActivityDetail,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
