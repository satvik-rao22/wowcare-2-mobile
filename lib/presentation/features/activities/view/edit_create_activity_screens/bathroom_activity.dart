import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_dropdown_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/shared/common/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/entities/activity_type_details.dart';
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../widgets/activity_edit_student_scope_checkboxes.dart';
import '../../widgets/activity_student_display_tile.dart';
import '../../utils/activity_description_limits.dart';
import '../../utils/activity_staff_display.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class BathroomActivityScreen extends StatefulWidget {
  const BathroomActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData,
    this.readOnly = false,
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  /// Same layout as edit; all fields non-interactive (view mode).
  final bool readOnly;

  @override
  State<BathroomActivityScreen> createState() => _BathroomActivityScreenState();
}

class _BathroomActivityScreenState extends State<BathroomActivityScreen> {
  bool get _layoutAsEdit => widget.isEdit || widget.readOnly;
  bool get _canInteract => !widget.readOnly;

  /// Description is required only when bathroom type is Potty (label match).
  bool get _descriptionRequiredForPotty {
    final t = (_selectedBathroomType ?? '').toLowerCase();
    return t.contains('potty');
  }

  List<Map<String, dynamic>> _selectedStudentsData = [];
  List<String> _selectedStudents = [];
  final TextEditingController _descriptionController = TextEditingController();

  List<ActivityTypeParameterOption> _bathroomTypeOptions = [];
  List<ActivityTypeParameterOption> _allSubTypeOptions = [];
  List<String> _bathroomTypeLabels = [];
  List<String> _availableSubTypes = [];
  String? _selectedBathroomType;
  String? _selectedSubType;

  DateTime? _activityDate;
  TimeOfDay? _activityTime;
  String? _activityTypeCode;
  String _staffName = '';
  String? _staffCode;
  String? _schoolCode;
  String? _organizationCode;
  bool _isSubmitting = false;
  bool _loadingBathroomOptions = false;
  bool _loadingActivityDetail = false;
  ActivityItem? _liveActivity;
  /// Edit scope: indices checked = only those students' activities are PATCHed.
  /// All unchecked = PATCH every student row (when multiple underlying codes exist).
  final Set<int> _scopedEditStudentIndices = {};

  /// Parameters from activity type except bathroom/sub-type and core form fields.
  List<ActivityTypeParameter> _extraParameters = [];
  final Map<String, String?> _extraDropdownByParamCode = {};
  final Map<String, bool> _extraBoolByParamCode = {};
  List<Map<String, dynamic>> _detailParameterRows = [];

  late final GetClassroomActivitySettingsUseCase _getActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final CreateActivityUseCase _createActivityUseCase;
  late final GetActivityUseCase _getActivityUseCase;
  late final UpdateActivityUseCase _updateActivityUseCase;

  ActivityItem get _effectiveActivity =>
      _liveActivity ?? widget.activityData!;

  @override
  void initState() {
    super.initState();
    _getActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();
    _createActivityUseCase = serviceLocator<CreateActivityUseCase>();
    _getActivityUseCase = serviceLocator<GetActivityUseCase>();
    _updateActivityUseCase = serviceLocator<UpdateActivityUseCase>();

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData
          .map((student) => student['name'] as String)
          .toList();
      _loadActivityContextForCreate();
    } else if (_layoutAsEdit) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text =
          activity.studentList.length > 1 ? '' : (activity.description ?? '');
      _selectedBathroomType = activity.bathroomType;
      _selectedSubType = activity.bathroomSubType;
      _activityTypeCode = activity.activityTypeCode;
      final iso = activity.activityDateIso;
      if (iso != null && iso.trim().isNotEmpty) {
        try {
          final dt = DateTime.parse(iso.trim()).toLocal();
          _activityDate = DateTime(dt.year, dt.month, dt.day);
          _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _prefetchActivityForEdit();
        if (!mounted) return;
        final typeCode = _activityTypeCode?.trim();
        if (typeCode != null && typeCode.isNotEmpty) {
          await _loadBathroomParameterOptions();
        }
      });
    }
    _loadStaffContext();
  }

  Future<void> _prefetchActivityForEdit() async {
    if (!_layoutAsEdit || !mounted) return;
    final code = widget.activityData?.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _loadingActivityDetail = true);
    try {
      final detail = await _getActivityUseCase(code: code);
      if (!mounted) return;
      final item = activityItemFromActivityDetail(
        detail,
        viewerDisplayName: _staffName,
      );
      setState(() {
        _liveActivity = item;
        if ((widget.activityData?.studentList.length ?? 0) <= 1) {
          _selectedStudents = List<String>.from(item.studentList);
          _selectedStudentsData = studentDataMapsForActivityEdit(item);
        }
        _descriptionController.text =
            (widget.activityData?.studentList.length ?? 0) > 1
                ? ''
                : (item.description ?? '');
        _selectedBathroomType = item.bathroomType;
        _selectedSubType = item.bathroomSubType;
        _activityTypeCode = item.activityTypeCode;
        _detailParameterRows = detail.parameterValues
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final nextIso = item.activityDateIso;
        if (nextIso != null && nextIso.trim().isNotEmpty) {
          try {
            final dt = DateTime.parse(nextIso.trim()).toLocal();
            _activityDate = DateTime(dt.year, dt.month, dt.day);
            _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
          } catch (_) {}
        }
      });
    } catch (e) {
      CoreUtils.logApiError('Prefetch activity for edit: $e');
    } finally {
      if (mounted) setState(() => _loadingActivityDetail = false);
    }
  }

  void _updateAvailableSubTypes() {
    if (_selectedBathroomType == null) {
      _availableSubTypes = [];
      _selectedSubType = null;
      return;
    }
    final parent = _optionCodeForBathroomTypeLabel(_selectedBathroomType!);
    if (parent == null || parent.isEmpty) {
      _availableSubTypes = [];
      _selectedSubType = null;
      return;
    }
    final matching = _allSubTypeOptions
        .where((o) => (o.parentOptionCode ?? '').trim() == parent)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _availableSubTypes = matching
        .map((o) => (o.optionLabel ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final st = _selectedSubType;
    if (st != null && st.trim().isNotEmpty) {
      final idx = _availableSubTypes.indexWhere(
        (s) => s.toLowerCase() == st.trim().toLowerCase(),
      );
      if (idx >= 0) {
        _selectedSubType = _availableSubTypes[idx];
      } else {
        _selectedSubType = null;
      }
    }
  }

  String? _optionCodeForBathroomTypeLabel(String label) {
    for (final o in _bathroomTypeOptions) {
      final l = (o.optionLabel ?? '').trim();
      if (l.isEmpty) continue;
      if (l.toLowerCase() == label.trim().toLowerCase()) {
        final oc = (o.optionCode ?? o.code).trim();
        if (oc.isNotEmpty) return oc;
      }
    }
    return null;
  }

  ActivityTypeParameter? _findBathroomTypeParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('sub')) continue;
      if ((n.contains('bathroom') || n.contains('potty') || n.contains('diaper')) &&
          (n.contains('type') || n.contains('kind'))) {
        return p;
      }
    }
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('sub')) continue;
      if (n.contains('bathroom') ||
          n.contains('potty') ||
          n.contains('diaper')) {
        return p;
      }
    }
    return null;
  }

  ActivityTypeParameter? _findSubTypeParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('sub') && n.contains('type')) return p;
      if (n.contains('subtype')) return p;
    }
    return null;
  }

  bool _isBuiltInFormParameter(ActivityTypeParameter p) {
    final n = p.parameterName.toLowerCase();
    final dt = (p.dataType ?? '').toUpperCase();
    if (dt == 'DATE') return true;
    if (dt == 'TIME') return true;
    if (n.contains('staff')) return true;
    if (n.contains('description')) return true;
    return false;
  }

  bool _isDiaperBathroomTypeSelected() {
    final t = _selectedBathroomType?.toLowerCase().trim() ?? '';
    return t == 'diaper' || t.contains('diaper');
  }

  bool _extraParameterVisible(ActivityTypeParameter p) {
    if (_selectedBathroomType == null) return false;
    final bathroomOc = _optionCodeForBathroomTypeLabel(_selectedBathroomType!);
    if (bathroomOc == null || bathroomOc.isEmpty) return false;

    final dt = (p.dataType ?? '').toUpperCase();
    if (dt == 'BOOLEAN') {
      final n = p.parameterName.toLowerCase();
      if (n.contains('diaper') || n.contains('cream')) {
        return _isDiaperBathroomTypeSelected();
      }
      return true;
    }

    if (p.options.isEmpty) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('diaper') || n.contains('cream')) {
        return _isDiaperBathroomTypeSelected();
      }
      return true;
    }

    final withParent = p.options
        .where((o) => (o.parentOptionCode ?? '').trim().isNotEmpty)
        .toList();
    if (withParent.isEmpty) {
      return true;
    }
    return p.options.any((o) => (o.parentOptionCode ?? '').trim() == bathroomOc);
  }

  List<String> _labelsForExtraParameterOptions(ActivityTypeParameter p) {
    final bathroomOc = _optionCodeForBathroomTypeLabel(_selectedBathroomType ?? '');
    if (bathroomOc == null || bathroomOc.isEmpty) return [];
    final opts = p.options.where((o) {
      final po = (o.parentOptionCode ?? '').trim();
      if (po.isEmpty) return true;
      return po == bathroomOc;
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return opts
        .map((o) => (o.optionLabel ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _parseBoolDefault(String? raw) {
    if (raw == null) return false;
    final s = raw.toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  bool _boolValueForParameter(ActivityTypeParameter p) {
    if (_extraBoolByParamCode.containsKey(p.code)) {
      return _extraBoolByParamCode[p.code]!;
    }
    return _parseBoolDefault(p.defaultValue);
  }

  void _clearExtraFieldValues() {
    _extraDropdownByParamCode.clear();
    _extraBoolByParamCode.clear();
  }

  String? _validateVisibleExtraParameters() {
    for (final p in _extraParameters) {
      if (!_extraParameterVisible(p) || !p.isRequired) continue;
      final dt = (p.dataType ?? '').toUpperCase();
      if (dt == 'DROPDOWN' || dt == 'SELECT' || dt == 'MULTISELECT') {
        final v = _extraDropdownByParamCode[p.code];
        if (v == null || v.trim().isEmpty) {
          return 'Please select ${p.parameterName}';
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _buildExtraParameterValueEntries() {
    final out = <Map<String, dynamic>>[];
    final bathroomOc =
        _optionCodeForBathroomTypeLabel(_selectedBathroomType ?? '');
    for (final p in _extraParameters) {
      if (!_extraParameterVisible(p)) continue;
      final dt = (p.dataType ?? '').toUpperCase();
      if (dt == 'BOOLEAN') {
        final b = _boolValueForParameter(p);
        out.add({'parameterCode': p.code, 'value': b ? 'true' : 'false'});
        continue;
      }
      if (dt == 'DROPDOWN' || dt == 'SELECT' || dt == 'MULTISELECT') {
        final label = _extraDropdownByParamCode[p.code];
        if (label == null || label.trim().isEmpty) continue;
        final entry = _paramForOptionOrValue(
          p,
          label,
          restrictParentOptionCode: bathroomOc,
        );
        if (entry != null) out.add(entry);
      }
    }
    return out;
  }

  String? _labelFromOptionCode(
    ActivityTypeParameter p,
    String? optionCode, {
    String? restrictParentOptionCode,
  }) {
    final oc = (optionCode ?? '').trim();
    if (oc.isEmpty) return null;
    final parentFilter = restrictParentOptionCode?.trim();
    for (final o in p.options) {
      if (parentFilter != null && parentFilter.isNotEmpty) {
        final po = (o.parentOptionCode ?? '').trim();
        if (po.isNotEmpty && po != parentFilter) continue;
      }
      final thisOc = (o.optionCode ?? o.code).trim();
      if (thisOc.isNotEmpty && thisOc == oc) {
        final label = (o.optionLabel ?? '').trim();
        if (label.isNotEmpty) return label;
      }
    }
    return null;
  }

  void _prefillExtraFieldValuesFromDetailRows() {
    final rows = _detailParameterRows;
    if (rows.isEmpty || _extraParameters.isEmpty) return;
    final bathroomOc =
        _optionCodeForBathroomTypeLabel(_selectedBathroomType ?? '');
    for (final p in _extraParameters) {
      final row = rows.where((r) => (r['parameterCode'] ?? '') == p.code).toList();
      if (row.isEmpty) continue;
      final r = row.first;
      final dt = (p.dataType ?? '').toUpperCase();
      if (dt == 'BOOLEAN') {
        final vb = r['valueBoolean'];
        if (vb is bool) {
          _extraBoolByParamCode[p.code] = vb;
        } else {
          final txt = (r['valueText'] ?? '').toString().trim().toLowerCase();
          if (txt.isNotEmpty) {
            _extraBoolByParamCode[p.code] =
                txt == 'true' || txt == '1' || txt == 'yes';
          }
        }
        continue;
      }

      if (dt == 'DROPDOWN' || dt == 'SELECT' || dt == 'MULTISELECT') {
        String? label = (r['selectedOptionLabel'] ?? '').toString().trim();
        label = label.isEmpty
            ? (r['optionLabel'] ?? '').toString().trim()
            : label;
        if (label.isEmpty) {
          label = _labelFromOptionCode(
            p,
            (r['selectedOptionCode'] ?? r['valueText']).toString(),
            restrictParentOptionCode: bathroomOc,
          );
        }
        if (label != null && label.isNotEmpty) {
          _extraDropdownByParamCode[p.code] = label;
        }
      }
    }
  }

  Future<void> _loadBathroomParameterOptions() async {
    final code = _activityTypeCode?.trim();
    if (code == null || code.isEmpty) return;
    if (!mounted) return;
    setState(() => _loadingBathroomOptions = true);
    try {
      final details = await _getActivityTypeDetailsUseCase(code: code);
      if (!mounted) return;
      final bathroom = _findBathroomTypeParameter(details.parameters);
      final sub = _findSubTypeParameter(details.parameters);
      if (bathroom == null || sub == null) {
        setState(() {
          _bathroomTypeOptions = [];
          _bathroomTypeLabels = [];
          _allSubTypeOptions = [];
          _availableSubTypes = [];
          _extraParameters = [];
          _clearExtraFieldValues();
          _loadingBathroomOptions = false;
        });
        return;
      }
      final types = List<ActivityTypeParameterOption>.from(bathroom.options)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      final subs = List<ActivityTypeParameterOption>.from(sub.options)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      final extras = details.parameters
          .where(
            (p) =>
                p.code != bathroom.code &&
                p.code != sub.code &&
                !_isBuiltInFormParameter(p),
          )
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      setState(() {
        _extraParameters = extras;
        _clearExtraFieldValues();
        _bathroomTypeOptions = types;
        _bathroomTypeLabels = types
            .map((o) => (o.optionLabel ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        _allSubTypeOptions = subs;
        _loadingBathroomOptions = false;
        _updateAvailableSubTypes();
        _prefillExtraFieldValuesFromDetailRows();
      });
    } catch (e) {
      CoreUtils.logApiError('Failed to load Bathroom type options: $e');
      if (mounted) {
        setState(() {
          _loadingBathroomOptions = false;
        });
      }
    }
  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);

      if (_selectedStudents.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _loadStaffContext() async {
    final storage = serviceLocator<StorageService>();
    final displayName =
        (await storage.getString(StorageKeys.displayName) ?? '').trim();
    final schoolCode =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final organizationCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final staffCode = await resolveLoggedInStaffCode();

    if (!mounted) return;
    setState(() {
      _staffName = displayName.isNotEmpty ? displayName : 'Staff';
      _staffCode = staffCode;
      _schoolCode = schoolCode.isNotEmpty ? schoolCode : null;
      _organizationCode =
          organizationCode.isNotEmpty ? organizationCode : null;
    });
  }

  Future<void> _loadActivityContextForCreate() async {
    if (widget.selectedStudents == null || widget.selectedStudents!.isEmpty) {
      return;
    }
    final first = widget.selectedStudents!.first;
    final dynamic classroomCodeDynamic =
        first['classroomCode'] ?? first['classroomcode'];
    final classroomCode =
        classroomCodeDynamic is String ? classroomCodeDynamic.trim() : '';
    if (classroomCode.isEmpty) return;

    try {
      final List<ActivitySetting> settings =
          await _getActivitySettingsUseCase(classroomCode: classroomCode);
      ActivitySetting? bathroomSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('bathroom') || name.contains('potty') || name.contains('diaper')) {
          bathroomSetting = s;
          break;
        }
      }
      if (bathroomSetting != null && mounted) {
        setState(() {
          _activityTypeCode = bathroomSetting!.activityTypeCode;
        });
        await _loadBathroomParameterOptions();
      }
    } catch (e) {
      CoreUtils.logApiError(
          'Failed to load activity settings for Bathroom: $e');
    }
  }

  Map<String, dynamic>? _paramForOptionOrValue(
    ActivityTypeParameter? param,
    String uiLabel, {
    String? restrictParentOptionCode,
  }) {
    if (param == null || uiLabel.trim().isEmpty) return null;
    final v = uiLabel.trim();
    final parentFilter = restrictParentOptionCode?.trim();
    for (final o in param.options) {
      if (parentFilter != null && parentFilter.isNotEmpty) {
        final po = (o.parentOptionCode ?? '').trim();
        if (po.isNotEmpty && po != parentFilter) continue;
      }
      final label = (o.optionLabel ?? '').trim();
      if (label.isEmpty) continue;
      if (label.toLowerCase() == v.toLowerCase()) {
        final oc = (o.optionCode ?? o.code).trim();
        if (oc.isNotEmpty) {
          return {
            'parameterCode': param.code,
            'selectedOptionCode': oc,
          };
        }
      }
    }
    return {
      'parameterCode': param.code,
      'value': v,
    };
  }

  Future<void> _submitCreateActivity() async {
    if (_isSubmitting) return;

    if (_layoutAsEdit) {
      return;
    }

    if (_selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isWarning: true,
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (_descriptionRequiredForPotty) {
      if (description.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please enter description',
          isWarning: true,
        );
        return;
      }
      if (description.length < 5) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Description must be at least 5 characters long',
          isWarning: true,
        );
        return;
      }
    }
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

    if (_selectedBathroomType == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select Bathroom Type',
        isWarning: true,
      );
      return;
    }
    if (_selectedSubType == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select Sub Type',
        isWarning: true,
      );
      return;
    }

    final extraErr = _validateVisibleExtraParameters();
    if (extraErr != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: extraErr,
        isWarning: true,
      );
      return;
    }

    final classroomCodeDynamic = _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode =
        classroomCodeDynamic is String ? classroomCodeDynamic.trim() : '';

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
            'Unable to determine activity type for Bathroom. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final combinedDateTime = DateTime(
      _activityDate!.year,
      _activityDate!.month,
      _activityDate!.day,
      _activityTime!.hour,
      _activityTime!.minute,
    );
    final activityDateIso = combinedDateTime.toUtc().toIso8601String();

    setState(() {
      _isSubmitting = true;
    });

    try {
      // POST /api/v1/activities — same payload as MedicationActivityScreen (multi-student fan-out via studentCodes).
      final details =
          await _getActivityTypeDetailsUseCase(code: activityTypeCode);

      String? findParamCode(String contains) {
        final target = contains.toLowerCase();
        for (final p in details.parameters) {
          final name = p.parameterName.toLowerCase();
          if (name.contains(target)) return p.code;
        }
        return null;
      }

      final typeParam = _findBathroomTypeParameter(details.parameters);
      final subParam = _findSubTypeParameter(details.parameters);

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';

      final typeEntry =
          _paramForOptionOrValue(typeParam, _selectedBathroomType!);
      final subEntry = _paramForOptionOrValue(subParam, _selectedSubType!);

      // Build parameterValues in backend-required shape (supports multi-student fan-out via studentCodes).
      final parameterValues = <Map<String, dynamic>>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          {'parameterCode': dateParamCode, 'value': localDate},
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          {'parameterCode': timeParamCode, 'value': localTime},
        if (staffParamCode != null &&
            staffParamCode.trim().isNotEmpty &&
            staffCode.trim().isNotEmpty)
          {'parameterCode': staffParamCode, 'value': staffCode},
        if (descParamCode != null && descParamCode.trim().isNotEmpty)
          {'parameterCode': descParamCode, 'value': description},
        if (typeEntry != null) typeEntry,
        if (subEntry != null) subEntry,
        ..._buildExtraParameterValueEntries(),
      ];

      final message = await _createActivityUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: description,
        parameterValues: parameterValues,
        attachments: const [],
      );

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );

      Navigator.of(context).popUntil((route) {
        return route.settings.name == ActivityFeedScreen.routeName;
      });
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: e.toString(),
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

    final fallbackActivityCode = _effectiveActivity.activityCode?.trim();

    if (_selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isWarning: true,
      );
      return;
    }
    if (_selectedBathroomType == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select Bathroom Type',
        isWarning: true,
      );
      return;
    }
    if (_selectedSubType == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select Sub Type',
        isWarning: true,
      );
      return;
    }
    final description = _descriptionController.text.trim();
    if (_descriptionRequiredForPotty) {
      if (description.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please enter description',
          isWarning: true,
        );
        return;
      }
      if (description.length < 5) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Description must be at least 5 characters long',
          isWarning: true,
        );
        return;
      }
    }
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

    final extraErr = _validateVisibleExtraParameters();
    if (extraErr != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: extraErr,
        isWarning: true,
      );
      return;
    }

    var staffCode = _staffCode ?? await resolveLoggedInStaffCode();
    if (staffCode == null || staffCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Missing staff information. Please re-login and try again.',
        isError: true,
      );
      return;
    }

    final activityTypeCode = _activityTypeCode;
    if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to determine activity type for Bathroom. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final combinedDateTime = DateTime(
      _activityDate!.year,
      _activityDate!.month,
      _activityDate!.day,
      _activityTime!.hour,
      _activityTime!.minute,
    );
    final activityDateIso = combinedDateTime.toUtc().toIso8601String();

    setState(() => _isSubmitting = true);
    try {
      final details =
          await _getActivityTypeDetailsUseCase(code: activityTypeCode);

      String? findParamCode(String contains) {
        final target = contains.toLowerCase();
        for (final p in details.parameters) {
          final name = p.parameterName.toLowerCase();
          if (name.contains(target)) return p.code;
        }
        return null;
      }

      final typeParam = _findBathroomTypeParameter(details.parameters);
      final subParam = _findSubTypeParameter(details.parameters);

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';

      final typeEntry =
          _paramForOptionOrValue(typeParam, _selectedBathroomType!);
      final subEntry = _paramForOptionOrValue(subParam, _selectedSubType!);

      final parameterValues = <Map<String, dynamic>>[
        if (dateParamCode != null && dateParamCode.trim().isNotEmpty)
          {'parameterCode': dateParamCode, 'value': localDate},
        if (timeParamCode != null && timeParamCode.trim().isNotEmpty)
          {'parameterCode': timeParamCode, 'value': localTime},
        if (staffParamCode != null &&
            staffParamCode.trim().isNotEmpty &&
            staffCode.trim().isNotEmpty)
          {'parameterCode': staffParamCode, 'value': staffCode},
        if (descParamCode != null && descParamCode.trim().isNotEmpty)
          {'parameterCode': descParamCode, 'value': description},
        if (typeEntry != null) typeEntry,
        if (subEntry != null) subEntry,
        ..._buildExtraParameterValueEntries(),
      ];

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
          staffCode: staffCode,
          activityDate: activityDateIso,
          description: description,
          parameterValues: parameterValues,
          attachments: const [],
        );
      }

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: lastMessage ?? 'Updated',
        isSuccess: true,
      );
      Navigator.of(context).popUntil((route) {
        return route.settings.name == ActivityFeedScreen.routeName;
      });
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onSaveOrAddPressed() async {
    if (_isSubmitting) return;
    if (widget.readOnly) return;

    if (widget.isEdit) {
      await _submitUpdateActivity();
      return;
    }

    await _submitCreateActivity();
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
      title: 'Bathroom',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            if (_layoutAsEdit)
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
            else
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
            if (widget.isEdit && !widget.readOnly && _selectedStudents.length > 1) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Divider(height: 24),
              ),
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
                  child: ActivityDropdownWidget(
                    options: _bathroomTypeLabels,
                    dropDownName: 'Bathroom Type',
                    selectedValue: _selectedBathroomType,
                    isRequired: true,
                    isEnabled: _canInteract &&
                        !_loadingBathroomOptions &&
                        _bathroomTypeLabels.isNotEmpty,
                    onSelect: (value) {
                      setState(() {
                        _selectedBathroomType = value;
                        _selectedSubType = null;
                        _clearExtraFieldValues();
                        _updateAvailableSubTypes();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: ActivityDropdownWidget(
                    options: _availableSubTypes,
                    dropDownName: 'Sub Type',
                    selectedValue: _selectedSubType,
                    isEnabled: _canInteract &&
                        _selectedBathroomType != null &&
                        !_loadingBathroomOptions,
                    isRequired: true,
                    onSelect: (value) {
                      setState(() {
                        _selectedSubType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            ..._buildDynamicExtraFields(responsive),
            SizedBox(height: responsive.verticalSpacing),
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
            StaffPresentWidget(
              staffName: staffPresentLabelForActivity(
                layoutAsEdit: _layoutAsEdit,
                activityCreatedBy:
                    _layoutAsEdit ? _effectiveActivity.createdBy : '',
                loggedInDisplayName: _staffName,
              ),
              isEditable: _canInteract,
            ),
            SizedBox(height: responsive.verticalSpacing),
            InputWidget(
              controller: _descriptionController,
              height: 100,
              hint: 'Enter Description',
              isRequired: _descriptionRequiredForPotty,
              readOnly: !_canInteract,
              maxLength: ActivityDescriptionLimits.maxLength,
            ),
            SizedBox(height: responsive.verticalSpacing),
          ],
        ),
      ),
      bottomBar: widget.readOnly
          ? const SafeArea(child: SizedBox.shrink())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: CustomButtonLayout(
                  confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                  onPressedConfirm: _onSaveOrAddPressed,
                  showCancelButton: false,
                  isForm: false,
                  isLoading: _isSubmitting ||
                      _loadingBathroomOptions ||
                      _loadingActivityDetail,
                ),
              ),
            ),
    );
  }

  List<Widget> _buildDynamicExtraFields(ResponsiveHelper responsive) {
    if (_extraParameters.isEmpty) return <Widget>[];
    final visible =
        _extraParameters.where(_extraParameterVisible).toList(growable: false);
    if (visible.isEmpty) return <Widget>[];

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      rows.add(SizedBox(height: responsive.verticalSpacing));
      rows.add(_buildOneExtraParameter(visible[i], responsive));
    }
    return rows;
  }

  Widget _buildOneExtraParameter(
    ActivityTypeParameter p,
    ResponsiveHelper responsive,
  ) {
    final dt = (p.dataType ?? '').toUpperCase();
    if (dt == 'BOOLEAN') {
      return Align(
        alignment: Alignment.centerLeft,
        child: CustomCheckbox(
          label: p.parameterName,
          value: _boolValueForParameter(p),
          borderColor: AppColors.themeColor,
          onChanged: _canInteract
              ? (nv) {
                  setState(() {
                    _extraBoolByParamCode[p.code] = nv ?? false;
                  });
                }
              : null,
        ),
      );
    }
    if (dt == 'DROPDOWN' || dt == 'SELECT' || dt == 'MULTISELECT') {
      final options = _labelsForExtraParameterOptions(p);
      return ActivityDropdownWidget(
        options: options,
        dropDownName: p.parameterName,
        selectedValue: _extraDropdownByParamCode[p.code],
        isRequired: p.isRequired,
        isEnabled:
            _canInteract && options.isNotEmpty && !_loadingBathroomOptions,
        onSelect: (val) {
          setState(() {
            _extraDropdownByParamCode[p.code] = val;
          });
        },
      );
    }
    return const SizedBox.shrink();
  }
}
