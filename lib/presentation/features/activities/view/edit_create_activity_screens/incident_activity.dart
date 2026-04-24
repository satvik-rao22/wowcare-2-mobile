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
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/entities/activity_type_details.dart';
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
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
import '../activity_feed_screen.dart';

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
  String _staffType = '';
  String? _staffCode;
  String? _schoolCode;
  String? _organizationCode;
  bool _isSubmitting = false;
  bool _loadingActivityDetail = false;
  ActivityItem? _liveActivity;
  final Set<int> _scopedEditStudentIndices = {};
  List<Map<String, dynamic>> _detailAttachmentRows = [];
  bool _isUploadingMedia = false;
  List<File> _newPhotos = [];
  final Map<String, String> _uploadedAssetCodeByPath = {};
  String? _lastUploadContextKey;
  List<String> _remainingExistingPhotoUrls = [];

  int get _uploadedPhotoCount => _newPhotos
      .where((f) => _uploadedAssetCodeByPath.containsKey(f.path))
      .length;

  late final GetClassroomActivitySettingsUseCase _getActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final CreateActivityUseCase _createActivityUseCase;
  late final GetActivityUseCase _getActivityUseCase;
  late final UpdateActivityUseCase _updateActivityUseCase;
  late final ImageUploadService _imageUploadService;

  ActivityItem get _effectiveActivity => _liveActivity ?? widget.activityData!;

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
    _createActivityUseCase = serviceLocator<CreateActivityUseCase>();
    _getActivityUseCase = serviceLocator<GetActivityUseCase>();
    _updateActivityUseCase = serviceLocator<UpdateActivityUseCase>();
    _imageUploadService = serviceLocator<ImageUploadService>();

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
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text =
          activity.whatHappened ?? activity.description ?? '';
      _addNotesController.text = activity.additionalNotes ?? '';
      _firstAidGiven = activity.firstAidAdministered ?? false;
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
            item.whatHappened ?? item.description ?? '';
        _addNotesController.text = item.additionalNotes ?? '';
        _firstAidGiven = item.firstAidAdministered ?? false;
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
    } catch (e) {
      CoreUtils.logApiError('Prefetch activity for edit: $e');
    } finally {
      if (mounted) setState(() => _loadingActivityDetail = false);
    }
  }

  Future<void> _loadStaffContext() async {
    final storage = serviceLocator<StorageService>();
    final displayName = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final staffType =
        (await storage.getString(StorageKeys.staffType) ?? '').trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final organizationCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final staffCode = await resolveLoggedInStaffCode();

    if (!mounted) return;
    setState(() {
      _staffName = displayName.isNotEmpty ? displayName : 'Staff';
      _staffType = staffType.toUpperCase();
      _staffCode = staffCode;
      _schoolCode = schoolCode.isNotEmpty ? schoolCode : null;
      _organizationCode = organizationCode.isNotEmpty ? organizationCode : null;
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

    if (_activityDate == null || _activityTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select date and time',
        isWarning: true,
      );
      return;
    }

    if (_newPhotos.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please add at least one photo (required for Incident)',
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

    final combinedDateTime = DateTime(
      _activityDate!.year,
      _activityDate!.month,
      _activityDate!.day,
      _activityTime!.hour,
      _activityTime!.minute,
    );
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

      String? findParamCode(String contains) {
        final target = contains.toLowerCase();
        for (final p in details.parameters) {
          final name = p.parameterName.toLowerCase();
          if (name.contains(target)) return p.code;
        }
        return null;
      }

      String? findWhatHappenedParamCode() {
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          if (n.contains('what') && n.contains('happ')) return p.code;
        }
        return findParamCode('description');
      }

      String? findAdditionalNotesParamCode() {
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          if (n.contains('additional')) return p.code;
        }
        return null;
      }

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final whatParamCode = findWhatHappenedParamCode();
      final notesParamCode = findAdditionalNotesParamCode();
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
      ];

      final message = await _createActivityUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: whatHappened,
        parameterValues: parameterValues,
        attachments: attachments,
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

    if (_activityDate == null || _activityTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select date and time',
        isWarning: true,
      );
      return;
    }

    final keepsExistingPhotos = _remainingExistingPhotoUrls.isNotEmpty ||
        imageDeliveryUrlsFromAttachmentRows(_detailAttachmentRows)
            .isNotEmpty ||
        (_effectiveActivity.photoUrl ?? '').trim().isNotEmpty;
    final hasPhotoForSave = keepsExistingPhotos || _newPhotos.isNotEmpty;
    if (!hasPhotoForSave) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Incident requires at least one photo',
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

    final combinedDateTime = DateTime(
      _activityDate!.year,
      _activityDate!.month,
      _activityDate!.day,
      _activityTime!.hour,
      _activityTime!.minute,
    );
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

      String? findParamCode(String contains) {
        final target = contains.toLowerCase();
        for (final p in details.parameters) {
          final name = p.parameterName.toLowerCase();
          if (name.contains(target)) return p.code;
        }
        return null;
      }

      String? findWhatHappenedParamCode() {
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          if (n.contains('what') && n.contains('happ')) return p.code;
        }
        return findParamCode('description');
      }

      String? findAdditionalNotesParamCode() {
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          if (n.contains('additional')) return p.code;
        }
        return null;
      }

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final whatParamCode = findWhatHappenedParamCode();
      final notesParamCode = findAdditionalNotesParamCode();
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
          await _getActivityUseCase(code: code);
        } catch (_) {}
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

    final hasSharedAttachmentInEdit = widget.isEdit &&
        _detailAttachmentRows.any((row) {
          final binding = (row['bindingMode'] ?? '').toString().trim().toUpperCase();
          final student = (row['studentCode'] ?? '').toString().trim();
          return binding == 'SHARED' || student.isEmpty;
        });
    final isShared = hasSharedAttachmentInEdit || studentCodes.length > 1;
    final bindingMode = isShared ? 'SHARED' : 'PER_STUDENT';
    final ownerType = isShared ? 'CLASSROOM' : 'STUDENT';
    final ownerCode = isShared ? classroomCode.trim() : studentCodes.first;
    final missingPhotos = _newPhotos
        .where((f) => !_uploadedAssetCodeByPath.containsKey(f.path))
        .toList();

    if (missingPhotos.isNotEmpty) {
      setState(() => _isUploadingMedia = true);
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
        for (final photo in missingPhotos) {
          final fileName = photo.uri.pathSegments.isNotEmpty
              ? photo.uri.pathSegments.last
              : 'photo.jpg';
          final contentLengthBytes = await photo.length();
          final presign = await _imageUploadService.createAssetPresign(
            sessionCode: uploadSession.sessionCode,
            documentApiBasePath: uploadSession.documentApiBasePath,
            fileName: fileName,
            contentType: 'image/jpeg',
            contentLengthBytes: contentLengthBytes,
            mediaType: 'IMAGE',
            ownerType: ownerType,
            ownerCode: ownerCode,
          );
          await _imageUploadService.uploadFileToPresignedUrl(
            file: photo,
            presignedPutUrl: presign.presignedPutUrl,
            requiredHeaders: presign.requiredHeaders,
            fallbackContentType: 'image/jpeg',
          );
          await _imageUploadService.completeAssetUpload(
            sessionCode: uploadSession.sessionCode,
            assetCode: presign.assetCode,
            documentApiBasePath: uploadSession.documentApiBasePath,
          );
          _uploadedAssetCodeByPath[photo.path] = presign.assetCode;
          sessionAssetCodes.add(presign.assetCode);
        }
        await _imageUploadService.waitUntilAssetsReady(
          sessionCode: uploadSession.sessionCode,
          expectedAssetCodes: sessionAssetCodes,
        );
      } finally {
        if (mounted) setState(() => _isUploadingMedia = false);
      }
    }

    final attachments = <Map<String, dynamic>>[];
    for (final photo in _newPhotos) {
      final assetCode = _uploadedAssetCodeByPath[photo.path];
      if (assetCode != null && assetCode.isNotEmpty) {
        if (isShared) {
          attachments.add({'assetCode': assetCode});
        } else {
          attachments.add({
            'assetCode': assetCode,
            'studentCode': ownerCode,
            'bindingMode': bindingMode,
          });
        }
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
    final photoCount = photos.length + remainingExistingPhotoUrls.length;
    final videoCount =
        (video != null ? 1 : 0) +
        ((remainingExistingVideoUrl != null &&
                remainingExistingVideoUrl.trim().isNotEmpty)
            ? 1
            : 0);
    if (widget.isEdit && photoCount > 1) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Maximum 1 photo can be attached.',
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
      _newPhotos = photos;
      _remainingExistingPhotoUrls =
          List<String>.from(remainingExistingPhotoUrls);
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
                final isAdminPersona =
                    _staffType == 'SCHOOL_ADMIN' || _staffType == 'ORGANIZATION_ADMIN';
                final lockToLoggedInStaffOnEdit =
                    widget.isEdit && !widget.readOnly && !isAdminPersona;
                return StaffPresentWidget(
                  staffName: lockToLoggedInStaffOnEdit
                      ? _staffName
                      : staffPresentLabelForActivity(
                          layoutAsEdit: _layoutAsEdit,
                          activityCreatedBy: _layoutAsEdit
                              ? (_effectiveActivity.staffPresent ??
                                  _effectiveActivity.createdBy)
                              : '',
                          loggedInDisplayName: _staffName,
                        ),
                  isEditable:
                      lockToLoggedInStaffOnEdit ? false : _canInteract,
                  isAlreadySigned: _layoutAsEdit,
                  incidentActivity: true,
                  onSigned: (value) {
                    setState(() {
                      _isSigned = value;
                    });
                  },
                );
              },
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
            SizedBox(height: responsive.verticalSpacing),
            if (_layoutAsEdit)
              IgnorePointer(
                ignoring: !_canInteract,
                child: MediaUploader(
                  isRequired: false,
                  allowVideo: false,
                  allowPhoto: true,
                  readOnly: widget.readOnly,
                  isPictureBox: false,
                  limit: 10,
                  photoSizeLimit: 20,
                  initialPhotoUrls: _remainingExistingPhotoUrls.isNotEmpty
                      ? List<String>.from(_remainingExistingPhotoUrls)
                      : (_effectiveActivity.photoUrl != null &&
                              _effectiveActivity.photoUrl!.trim().isNotEmpty
                          ? [_effectiveActivity.photoUrl!.trim()]
                          : const []),
                  label: 'Photos',
                  onMediaChanged: _onMediaChanged,
                ),
              )
            else
              MediaUploader(
                isRequired: true,
                allowVideo: false,
                allowPhoto: true,
                readOnly: widget.readOnly,
                isPictureBox: false,
                limit: 10,
                photoSizeLimit: 20,
                label: 'Photos (required)',
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
          ? const SafeArea(child: SizedBox.shrink())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: CustomButtonLayout(
                  confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                  onPressedConfirm: _onSaveOrAddPressed,
                  showCancelButton: false,
                  isForm: false,
                  isLoading:
                      _isSubmitting ||
                      _isUploadingMedia ||
                      _loadingActivityDetail,
                ),
              ),
            ),
    );
  }

  Widget _buildUploadStatus() {
    if (_isUploadingMedia) {
      return Row(
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Uploading photos...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      );
    }

    final uploadsSynced = _newPhotos.isEmpty ||
        _uploadedPhotoCount == _newPhotos.length;
    final createSatisfied = _layoutAsEdit || _newPhotos.isNotEmpty;

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
    if (!_layoutAsEdit && _newPhotos.isEmpty) {
      buf.write(' — add at least one photo (required)');
    }
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


