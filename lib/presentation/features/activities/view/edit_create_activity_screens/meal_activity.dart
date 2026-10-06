import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_dropdown_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/entities/activity_type_details.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_edit_student_scope_checkboxes.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_student_display_tile.dart';
import 'package:wowcare/domain/features/activity/services/activity_description_limits.dart';
import 'package:wowcare/domain/features/activity/services/activity_selected_date_prefill.dart';
import 'package:wowcare/presentation/features/activities/view/activity_attendance_window_feedback.dart';
import 'package:wowcare/domain/features/activity/services/activity_school_time.dart';
import 'package:wowcare/domain/features/activity/services/activity_staff_display.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_admin_approve_reject_bar.dart';

class MealActivityScreen extends StatelessWidget {
  static const String routeName = '/activity/meal';

  const MealActivityScreen({
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
  Widget build(BuildContext context) {
    return _MealActivityView(
      selectedStudents: selectedStudents,
      isEdit: isEdit,
      activityData: activityData,
      readOnly: readOnly,
    );
  }
}

class _MealActivityView extends StatefulWidget {
  const _MealActivityView({
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
  State<_MealActivityView> createState() => _MealActivityViewState();
}

class _MealActivityViewState extends State<_MealActivityView> {
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

  List<ActivityTypeParameterOption> _mealTypeParamOptions = [];
  List<ActivityTypeParameterOption> _quantityParamOptions = [];
  List<String> _mealType = [];
  List<String> _quantityOptions = [];

  String? _selectedMealType;
  String? _selectedQuantity;

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
  bool _isSubmitting = false;
  bool _isApprovingOrRejecting = false;
  bool _isSavingBeforeApprove = false;
  bool _lastUpdateSucceeded = false;
  bool _loadingMealOptions = false;
  bool _loadingActivityDetail = false;
  ActivityItem? _liveActivity;
  final Set<int> _scopedEditStudentIndices = {};

  ActivityEditorCubit get _editor => context.read<ActivityEditorCubit>();

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
    _activityDate = null;
    _activityTime = null;
    _editor.bootstrapSchoolTimezone();

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData
          .map((student) => student['name'] as String)
          .toList();
      _activityDate =
          resolveSelectedAttendanceDate(_selectedStudentsData) ?? _activityDate;
      _loadActivityContextForCreate();
    } else if (_layoutAsEdit) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _requireAdminApproval = _isAdminApprovalRequired(activity);
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text = activity.description ?? '';
      _selectedMealType = activity.mealType?.trim();
      final q = activity.mealQuantity?.trim();
      _selectedQuantity = (q != null && q.isNotEmpty) ? q : null;
      _activityTypeCode = activity.activityTypeCode;
      final iso = activity.activityDateIso;
      if (iso != null && iso.trim().isNotEmpty) {
        try {
          final dt = activityDateTimeForDisplayFromIso(iso.trim());
          _activityDate = DateTime(dt.year, dt.month, dt.day);
          _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (e) {
          AppLogger.d('unparsable activityDateIso: $e');
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _prefetchActivityForEdit();
        await _loadMealParameterOptions();
      });
    }
    _loadStaffContext();
  }

  bool get _showAdminApproveRejectActions {
    if (!widget.isEdit || widget.readOnly) return false;
    if (!_isAdminDesignation) return false;
    return canAdminApproveOrRejectActivityItem(
      _effectiveActivity,
      isAdminPersona: activeAdminPersona(context),
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
      final item = activityItemFromActivityDetail(
        detail,
        viewerDisplayName: _staffName,
        schoolIana: await _editor.resolveSchoolTimezone(),
      );
      setState(() {
        _liveActivity = item;
        _requireAdminApproval = _isAdminApprovalRequired(item);
        if ((widget.activityData?.studentList.length ?? 0) <= 1) {
          _selectedStudents = List<String>.from(item.studentList);
          _selectedStudentsData = studentDataMapsForActivityEdit(item);
        }
        _descriptionController.text = item.description ?? '';
        _selectedMealType = item.mealType?.trim();
        final q = item.mealQuantity?.trim();
        _selectedQuantity = (q != null && q.isNotEmpty) ? q : null;
        _activityTypeCode = item.activityTypeCode;
        _staffPresentCode = _pickStaffPresentCode(detail.parameterValues);
        final nextIso = item.activityDateIso;
        if (nextIso != null && nextIso.trim().isNotEmpty) {
          try {
            final dt = activityDateTimeForDisplayFromIso(nextIso.trim());
            _activityDate = DateTime(dt.year, dt.month, dt.day);
            _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
          } catch (e) {
            AppLogger.d('unparsable activityDateIso: $e');
          }
        }
      });
      await _loadMealParameterOptions();
    } catch (e) {
      CoreUtils.logApiError('Prefetch activity for edit: $e');
    } finally {
      if (mounted) setState(() => _loadingActivityDetail = false);
    }
  }

  Future<void> _loadStaffContext() async {
    final ctx = await context.read<ActivityEditorCubit>().loadStaffContext();
    if (!mounted) return;
    setState(() {
      _staffName = ctx.staffName;
      _staffType = ctx.staffType;
      _staffCode = ctx.staffCode;
      _staffPresentCode = ctx.staffPresentCode;
      _schoolCode = ctx.schoolCode;
      _organizationCode = ctx.organizationCode;
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
      ActivitySetting? mealSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('meal')) {
          mealSetting = s;
          break;
        }
      }
      if (mealSetting != null && mounted) {
        setState(() {
          _activityTypeCode = mealSetting!.activityTypeCode;
        });
        await _loadMealParameterOptions();
      }
    } catch (e) {
      CoreUtils.logApiError('Failed to load activity settings for Meal: $e');
    }
  }

  /// [selectedOptionCode] only for DROPDOWN / SELECT / MULTISELECT.
  ActivityParameterValue? _paramEntryForOption(
    ActivityTypeParameter? param,
    String label,
  ) {
    if (param == null || label.trim().isEmpty) return null;
    final v = label.trim();
    final dt = (param.dataType ?? '').toUpperCase();
    final isDropdownType =
        dt == 'DROPDOWN' || dt == 'SELECT' || dt == 'MULTISELECT';

    if (isDropdownType) {
      for (final o in param.options) {
        final ol = (o.optionLabel ?? '').trim();
        if (ol.isNotEmpty && ol.toLowerCase() == v.toLowerCase()) {
          final oc = (o.optionCode ?? o.code).trim();
          if (oc.isNotEmpty) {
            return ActivityParameterValue(
              parameterCode: param.code,
              selectedOptionCode: oc,
            );
          }
        }
      }
    }
    return ActivityParameterValue(parameterCode: param.code, value: v);
  }

  ActivityTypeParameter? _findMealTypeParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('meal') && n.contains('type')) return p;
    }
    return null;
  }

  ActivityTypeParameter? _findQuantityParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('quant')) return p;
    }
    return null;
  }

  String? _canonicalLabelFromOptions(
    String? rawValue,
    List<ActivityTypeParameterOption> options,
  ) {
    final raw = (rawValue ?? '').trim();
    if (raw.isEmpty) return null;
    for (final o in options) {
      final label = (o.optionLabel ?? '').trim();
      final optionCode = (o.optionCode ?? o.code).trim();
      final rawCode = o.code.trim();
      if (label.isNotEmpty && label.toLowerCase() == raw.toLowerCase()) {
        return label;
      }
      if (optionCode.isNotEmpty &&
          optionCode.toLowerCase() == raw.toLowerCase() &&
          label.isNotEmpty) {
        return label;
      }
      if (rawCode.isNotEmpty &&
          rawCode.toLowerCase() == raw.toLowerCase() &&
          label.isNotEmpty) {
        return label;
      }
    }
    return null;
  }

  Future<void> _loadMealParameterOptions() async {
    final code = _activityTypeCode?.trim();
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _loadingMealOptions = true);
    try {
      final details = await _editor.getActivityTypeDetails(code: code);
      if (!mounted) return;
      final mealParam = _findMealTypeParameter(details.parameters);
      final quantityParam = _findQuantityParameter(details.parameters);
      final mealOptions = List<ActivityTypeParameterOption>.from(
        mealParam?.options ?? const <ActivityTypeParameterOption>[],
      )..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      final qtyOptions = List<ActivityTypeParameterOption>.from(
        quantityParam?.options ?? const <ActivityTypeParameterOption>[],
      )..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      setState(() {
        _mealTypeParamOptions = mealOptions;
        _quantityParamOptions = qtyOptions;
        _mealType = mealOptions
            .map((o) => (o.optionLabel ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        _quantityOptions = qtyOptions
            .map((o) => (o.optionLabel ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        _selectedMealType = _canonicalLabelFromOptions(
          _selectedMealType,
          _mealTypeParamOptions,
        );
        _selectedQuantity = _canonicalLabelFromOptions(
          _selectedQuantity,
          _quantityParamOptions,
        );
        _loadingMealOptions = false;
      });
    } catch (e) {
      CoreUtils.logApiError('Failed to load Meal parameter options: $e');
      if (!mounted) return;
      setState(() => _loadingMealOptions = false);
    }
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
            editor: _editor,
            students: _selectedStudentsData,
            selectedDate: _activityDate,
            selectedTime: _activityTime,
          );
      if (!isWithinAttendanceWindow) return;

      if (_selectedMealType == null || _selectedMealType!.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a meal type',
          isWarning: true,
        );
        return;
      }

      if (_selectedQuantity == null || _selectedQuantity!.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select quantity',
          isWarning: true,
        );
        return;
      }

      final description = _descriptionController.text.trim();
      if (description.isNotEmpty &&
          description.length > ActivityDescriptionLimits.maxLength) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: ActivityDescriptionLimits.maxLengthMessage,
          isWarning: true,
        );
        return;
      }

      if (_activityDate == null || _activityTime == null) {
        // When coming from student-selection, DateWidget can be non-editable; ensure we still use
        // the attendance date carried forward in selectedStudents payload.
        final prefilled = widget.selectedStudents != null
            ? resolveSelectedAttendanceDate(_selectedStudentsData)
            : null;
        if (prefilled != null) {
          _activityDate = prefilled;
        }
        if (_activityDate == null || _activityTime == null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Please select date and time',
            isWarning: true,
          );
          return;
        }
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

      var staffCode = _staffCode ?? await _editor.resolveStaffCode();
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
              'Unable to determine activity type for Meal. Please check activity settings.',
          isError: true,
        );
        return;
      }

      // Force activity payload date to match student-selection attendance date.
      final prefilled = widget.selectedStudents != null
          ? resolveSelectedAttendanceDate(_selectedStudentsData)
          : null;
      if (prefilled != null) {
        _activityDate = prefilled;
      }

      final resolvedActivityTime = await _editor.resolveActivityDateTime(
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

      final mealTypeParam = _findMealTypeParameter(details.parameters);
      final quantityParam = _findQuantityParameter(details.parameters);

      ActivityParameterValue? mealTypeEntry = _paramEntryForOption(
        mealTypeParam,
        _selectedMealType!.trim(),
      );
      if (mealTypeEntry == null && _selectedMealType!.trim().isNotEmpty) {
        final c = findParamCode('meal');
        if (c != null && c.trim().isNotEmpty) {
          mealTypeEntry = ActivityParameterValue(
            parameterCode: c,
            value: _selectedMealType!.trim(),
          );
        }
      }

      ActivityParameterValue? quantityEntry = _paramEntryForOption(
        quantityParam,
        _selectedQuantity!.trim(),
      );
      if (quantityEntry == null && _selectedQuantity!.trim().isNotEmpty) {
        final c = findParamCode('quant');
        if (c != null && c.trim().isNotEmpty) {
          quantityEntry = ActivityParameterValue(
            parameterCode: c,
            value: _selectedQuantity!.trim(),
          );
        }
      }

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime = resolvedActivityTime.localTimeHms;
      final staffPresentCode = ((_staffPresentCode ?? staffCode).trim());

      final parameterValues = <ActivityParameterValue>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          ActivityParameterValue(
            parameterCode: dateParamCode,
            value: localDate,
          ),
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          ActivityParameterValue(
            parameterCode: timeParamCode,
            value: localTime,
          ),
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
        if (mealTypeEntry != null) mealTypeEntry,
        if (quantityEntry != null) quantityEntry,
      ];

      final message = await _editor.createActivity(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: description,
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
            editor: _editor,
            students: _selectedStudentsData,
            selectedDate: _activityDate,
            selectedTime: _activityTime,
          );
      if (!isWithinAttendanceWindow) return;

      if (_selectedMealType == null || _selectedMealType!.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a meal type',
          isWarning: true,
        );
        return;
      }

      if (_selectedQuantity == null || _selectedQuantity!.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select quantity',
          isWarning: true,
        );
        return;
      }

      final description = _descriptionController.text.trim();
      if (description.isNotEmpty &&
          description.length > ActivityDescriptionLimits.maxLength) {
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

      var staffCode = _staffCode ?? await _editor.resolveStaffCode();
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
              'Unable to determine activity type for Meal. Please check activity settings.',
          isError: true,
        );
        return;
      }

      final resolvedActivityTime = await _editor.resolveActivityDateTime(
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

      final mealTypeParam = _findMealTypeParameter(details.parameters);
      final quantityParam = _findQuantityParameter(details.parameters);

      ActivityParameterValue? mealTypeEntry = _paramEntryForOption(
        mealTypeParam,
        _selectedMealType!.trim(),
      );
      if (mealTypeEntry == null && _selectedMealType!.trim().isNotEmpty) {
        final c = findParamCode('meal');
        if (c != null && c.trim().isNotEmpty) {
          mealTypeEntry = ActivityParameterValue(
            parameterCode: c,
            value: _selectedMealType!.trim(),
          );
        }
      }

      ActivityParameterValue? quantityEntry = _paramEntryForOption(
        quantityParam,
        _selectedQuantity!.trim(),
      );
      if (quantityEntry == null && _selectedQuantity!.trim().isNotEmpty) {
        final c = findParamCode('quant');
        if (c != null && c.trim().isNotEmpty) {
          quantityEntry = ActivityParameterValue(
            parameterCode: c,
            value: _selectedQuantity!.trim(),
          );
        }
      }

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime = resolvedActivityTime.localTimeHms;
      final staffPresentCode = ((_staffPresentCode ?? staffCode).trim());

      final parameterValues = <ActivityParameterValue>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          ActivityParameterValue(
            parameterCode: dateParamCode,
            value: localDate,
          ),
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          ActivityParameterValue(
            parameterCode: timeParamCode,
            value: localTime,
          ),
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
        if (mealTypeEntry != null) mealTypeEntry,
        if (quantityEntry != null) quantityEntry,
      ];

      final targets = studentMapsForScopedActivityUpdate(
        allStudentMaps: _selectedStudentsData,
        checkedIndices: _scopedEditStudentIndices,
      );
      String? lastMessage;
      final handledCards = <String>{};
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
        // Every selected student of one card shares that card's code, and the
        // first PATCH can already split the card (the rest stay on the old
        // one) — repeating it per student made the 2nd one fail with
        // "applyToStudentCodes must be a subset of the current card students".
        // One PATCH per distinct card, carrying only that card's students.
        if (!handledCards.add(code)) continue;
        lastMessage = await _editor.updateActivity(
          code: code,
          studentCodes: _selectedStudentsData
              .map((e) => (e['studentCode'] as String?)?.trim())
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList(),
          applyToStudentCodes: targets
              .where(
                (e) =>
                    ((e['activityCode'] as String?)?.trim() ??
                        fallbackActivityCode) ==
                    code,
              )
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
      _selectedStudentsData.removeWhere((m) => (m['name'] as String?) == name);

      if (_selectedStudents.isEmpty) {
        Navigator.of(context).pop();
      }
    });
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
      title: 'Meal',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AbsorbPointer(
          absorbing:
              _isSubmitting ||
              _isApprovingOrRejecting ||
              _loadingActivityDetail ||
              _loadingMealOptions,
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
              ActivityDropdownWidget(
                options: _mealType,
                dropDownName: 'Meal Type',
                selectedValue: _selectedMealType,
                isRequired: true,
                isEnabled:
                    _canInteract &&
                    !_loadingMealOptions &&
                    _mealType.isNotEmpty,
                onSelect: (value) {
                  setState(() {
                    _selectedMealType = value;
                  });
                },
              ),
              SizedBox(height: responsive.verticalSpacing),
              ActivityDropdownWidget(
                options: _quantityOptions,
                dropDownName: 'Quantity',
                selectedValue: _selectedQuantity,
                isRequired: true,
                isEnabled:
                    _canInteract &&
                    !_loadingMealOptions &&
                    _quantityOptions.isNotEmpty,
                onSelect: (value) {
                  setState(() {
                    _selectedQuantity = value;
                  });
                },
              ),
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
                            isEditable: _canInteract,
                            isRequired: true,
                            prefilledTime: _effectiveActivity.time,
                            onTimeChanged: (t) {
                              setState(() {
                                _activityTime = t;
                              });
                            },
                          )
                        : TimeWidget(
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
                hint: 'Enter Description (optional)',
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
                          _loadingActivityDetail ||
                          _loadingMealOptions,
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
                            _loadingActivityDetail ||
                            _loadingMealOptions,
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
