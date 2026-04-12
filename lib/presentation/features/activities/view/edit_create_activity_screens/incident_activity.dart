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
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../../../../shared/services/image_upload/image_upload_service.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../shared/common/widgets/student_tile.dart';
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
  final List<Map<String,dynamic>>? selectedStudents;
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
  List<String> _studentsToEdit = [];
  bool _selectAll = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addNotesController = TextEditingController();
  bool _firstAidGiven = false;
  bool _isSigned = false;

  DateTime? _activityDate;
  TimeOfDay? _activityTime;
  String? _activityTypeCode;
  String _staffName = '';
  String? _staffCode;
  String? _schoolCode;
  String? _organizationCode;
  bool _isSubmitting = false;
  bool _loadingActivityDetail = false;
  ActivityItem? _liveActivity;
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
    _imageUploadService = serviceLocator<ImageUploadService>();

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
          activity.whatHappened ?? activity.description ?? '';
      _addNotesController.text = activity.additionalNotes ?? '';
      _firstAidGiven = activity.firstAidAdministered ?? false;
      _isSigned = true;
      _activityTypeCode = activity.activityTypeCode;
      _detailAttachmentRows = (activity.snapshotAttachments ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _remainingExistingPhotoUrls =
          imageDeliveryUrlsFromAttachmentRows(_detailAttachmentRows);
      if (_remainingExistingPhotoUrls.isEmpty &&
          activity.photoUrl != null &&
          activity.photoUrl!.trim().isNotEmpty) {
        _remainingExistingPhotoUrls = [activity.photoUrl!.trim()];
      }
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
      final item = activityItemFromActivityDetail(detail);
      setState(() {
        _liveActivity = item;
        _selectedStudents = List<String>.from(item.studentList);
        _selectedStudentsData = studentDataMapsForActivityEdit(item);
        _descriptionController.text =
            item.whatHappened ?? item.description ?? '';
        _addNotesController.text = item.additionalNotes ?? '';
        _firstAidGiven = item.firstAidAdministered ?? false;
        _activityTypeCode = item.activityTypeCode;
        _detailAttachmentRows = detail.attachments
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _remainingExistingPhotoUrls =
            imageDeliveryUrlsFromAttachmentRows(_detailAttachmentRows);
        if (_remainingExistingPhotoUrls.isEmpty &&
            item.photoUrl != null &&
            item.photoUrl!.trim().isNotEmpty) {
          _remainingExistingPhotoUrls = [item.photoUrl!.trim()];
        }
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
      CoreUtils.logApiError('Failed to load activity settings for Incident: $e');
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
        message: 'Please add at least one photo',
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
            'Unable to determine activity type for Incident. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final additionalNotes = _addNotesController.text.trim();

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
      final attachments = await _ensurePhotoAssetsUploaded(
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );

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

      String? findFirstAidParamCode() {
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          final dt = (p.dataType ?? '').toUpperCase();
          if (dt == 'BOOLEAN' && n.contains('first') && n.contains('aid')) {
            return p.code;
          }
        }
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          if (n.contains('first') && n.contains('aid')) return p.code;
        }
        return null;
      }

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final whatParamCode = findWhatHappenedParamCode();
      final notesParamCode = findAdditionalNotesParamCode();
      final firstAidParamCode = findFirstAidParamCode();

      final sameWhatAndNotes = whatParamCode != null &&
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
        if (firstAidParamCode != null &&
            firstAidParamCode.trim().isNotEmpty)
          {
            'parameterCode': firstAidParamCode,
            'value': _firstAidGiven ? 'true' : 'false',
          },
        if (notesParamCode != null &&
            notesParamCode.trim().isNotEmpty &&
            additionalNotes.isNotEmpty &&
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

    final activityCode = _effectiveActivity.activityCode?.trim();
    if (activityCode == null || activityCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Missing activity reference. Refresh the activity list and try again.',
        isError: true,
      );
      return;
    }

    if (_studentsToEdit.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select at least one student',
        isWarning: true,
      );
      return;
    }

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

    final existingPatch =
        attachmentsForActivityPatchRequest(_detailAttachmentRows);
    if (existingPatch.isEmpty && _newPhotos.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please add at least one photo',
        isWarning: true,
      );
      return;
    }
    if (_isUploadingMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please wait for the photo upload to finish',
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
            'Unable to determine activity type for Incident. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final additionalNotes = _addNotesController.text.trim();

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
      final newAttachments = await _ensurePhotoAssetsUploaded(
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
      final mergedRows = mergeAttachmentRowsForEditPatch(
        existingRows: _detailAttachmentRows
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        newUploadRows: newAttachments,
        remainingNormalizedDeliveryUrls: remainingNorm,
      );
      final attachments =
          attachmentsForActivityPatchRequest(mergedRows);

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

      String? findFirstAidParamCode() {
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          final dt = (p.dataType ?? '').toUpperCase();
          if (dt == 'BOOLEAN' && n.contains('first') && n.contains('aid')) {
            return p.code;
          }
        }
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          if (n.contains('first') && n.contains('aid')) return p.code;
        }
        return null;
      }

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final whatParamCode = findWhatHappenedParamCode();
      final notesParamCode = findAdditionalNotesParamCode();
      final firstAidParamCode = findFirstAidParamCode();

      final sameWhatAndNotes = whatParamCode != null &&
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
        if (firstAidParamCode != null &&
            firstAidParamCode.trim().isNotEmpty)
          {
            'parameterCode': firstAidParamCode,
            'value': _firstAidGiven ? 'true' : 'false',
          },
        if (notesParamCode != null &&
            notesParamCode.trim().isNotEmpty &&
            additionalNotes.isNotEmpty &&
            !sameWhatAndNotes)
          {'parameterCode': notesParamCode, 'value': additionalNotes},
      ];

      final message = await _updateActivityUseCase(
        code: activityCode,
        staffCode: staffCode,
        activityDate: activityDateIso,
        description: whatHappened,
        parameterValues: parameterValues,
        attachments: attachments,
      );

      try {
        await _getActivityUseCase(code: activityCode);
      } catch (_) {}

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

  Future<List<Map<String, dynamic>>> _ensurePhotoAssetsUploaded({
    required String classroomCode,
    required String activityTypeCode,
    required String organizationCode,
    required String schoolCode,
    required List<String> studentCodes,
  }) async {
    if (_newPhotos.isEmpty) return const [];

    final normalizedStudentCodes = studentCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList()
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

    final ownerCode = studentCodes.first;
    final missing = _newPhotos
        .where((f) => !_uploadedAssetCodeByPath.containsKey(f.path))
        .toList();

    if (missing.isNotEmpty) {
      setState(() => _isUploadingMedia = true);
      try {
        final uploadSession =
            await _imageUploadService.createActivityUploadSession(
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          classroomCode: classroomCode,
          activityTypeCode: activityTypeCode,
          bindingMode: 'PER_STUDENT',
          studentCodes: studentCodes,
        );

        final sessionAssetCodes = <String>[];
        for (final photo in missing) {
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
            ownerType: 'STUDENT',
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
        attachments.add({
          'assetCode': assetCode,
          'studentCode': ownerCode,
          'bindingMode': 'PER_STUDENT',
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
    setState(() {
      _newPhotos = photos;
      _remainingExistingPhotoUrls =
          List<String>.from(remainingExistingPhotoUrls);
      _uploadedAssetCodeByPath.removeWhere(
        (path, _) => !_newPhotos.any((f) => f.path == path),
      );
    });
    _uploadPhotosOnSelection();
  }

  Future<void> _uploadPhotosOnSelection() async {
    if (_layoutAsEdit || _newPhotos.isEmpty || _isUploadingMedia) return;

    final activityTypeCode = _activityTypeCode;
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;
    final classroomCodeDynamic = _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode =
        classroomCodeDynamic is String ? classroomCodeDynamic.trim() : '';
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
      await _ensurePhotoAssetsUploaded(
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Photo uploaded successfully',
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

  void _updateSelectAllState() {
    _selectAll = _selectedStudents.every((student) => _studentsToEdit.contains(student));

  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);
      _selectedStudentsData.removeWhere(
        (m) => (m['name'] as String?) == name,
      );

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
            const SizedBox(height: 10,),
            // Select All
            if (_layoutAsEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: AppColors.primaryColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Students involved'),
                          TextSpan(text: ' *', style: TextStyle(
                            color: AppColors.primaryColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),),
                        ],
                      ),
                    ),
                    if (_canInteract) ...[
                      const SizedBox(height: 10,),
                      CustomCheckbox(
                        label: 'Select All',
                        value: _selectAll,
                        borderColor: AppColors.themeColor,
                        onChanged: (v) {
                          final newVal = v ?? false;
                          setState(() {
                            _selectAll = newVal;
                            if (newVal) {
                              _studentsToEdit = List.from(_selectedStudents);
                            } else {
                              _studentsToEdit.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            if (_layoutAsEdit) const SizedBox(height: 12,),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsive.isTablet ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: responsive.isTablet ? 3.8 : _layoutAsEdit ? 4.2 : 3.0,
              ),
              itemCount: _selectedStudents.length,
              itemBuilder: (context, index) {
                final String name = _selectedStudents[index];
                final bool isSelected = _studentsToEdit.contains(name);

                return _layoutAsEdit
                ? StudentTile(
                  name: name,
                  isSelected: _canInteract ? isSelected : true,
                  onSelected: _canInteract
                      ? (bool? selected){
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    setState(() {
                      if(selected == true){
                        _studentsToEdit.add(name);
                      } else {
                        _studentsToEdit.remove(name);
                      }
                      _updateSelectAllState();
                    });
                  }
                      : null,
                )
                    :SelectedStudentTile(
                  name: name,
                  onTap: () => _removeStudent(name),
                );
              },
            ),
            SizedBox(height: responsive.verticalSpacing,),
            Row(
              children: [
                Flexible(
                  child: _layoutAsEdit
                      ? DateWidget(
                          isEditable: _canInteract,
                          isRequired: true,
                          initialDate: _effectiveActivity.date,
                          onDateChanged: (d) => _activityDate = d,
                        )
                      : DateWidget(
                          isEditable: true,
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
            SizedBox(height: responsive.verticalSpacing,),
            InputWidget(
              controller: _descriptionController,
              label: 'What happened?',
              isRequired: true,
              readOnly: !_canInteract,
            ),
            SizedBox(height: responsive.verticalSpacing,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start ,
              children: [
                Text(
                  'First Aid Administered',
                  style:
                  TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 10.0 : 8.0,),
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
            SizedBox(height: responsive.verticalSpacing,),
            StaffPresentWidget(
              staffName: _layoutAsEdit
                  ? (_effectiveActivity.staffPresent ??
                      _effectiveActivity.createdBy)
                  : _staffName,
              isEditable: _canInteract,
              isAlreadySigned: _layoutAsEdit,
              incidentActivity: true,
              onSigned: (value) {
                setState(() {
                  _isSigned = value;
                });
              },
            ),
            SizedBox(height: responsive.verticalSpacing,),
            InputWidget(
              controller: _addNotesController,
              hint: 'Enter note',
              label: 'Additional Notes',
              readOnly: !_canInteract,
            ),
            SizedBox(height: responsive.verticalSpacing,),
            if (_layoutAsEdit)
              IgnorePointer(
                ignoring: !_canInteract,
                child: MediaUploader(
                  isRequired: false,
                  allowVideo: false,
                  allowPhoto: true,
                  isPictureBox: false,
                  limit: 10,
                  photoSizeLimit: 20,
                  initialPhotoUrls: _remainingExistingPhotoUrls.isNotEmpty
                      ? List<String>.from(_remainingExistingPhotoUrls)
                      : (_effectiveActivity.photoUrl != null &&
                              _effectiveActivity.photoUrl!.trim().isNotEmpty
                          ? [_effectiveActivity.photoUrl!.trim()]
                          : const []),
                  label: 'Upload Photo',
                  onMediaChanged: _onMediaChanged,
                ),
              )
            else
              MediaUploader(
                isRequired: true,
                allowVideo: false,
                allowPhoto: true,
                isPictureBox: false,
                limit: 10,
                photoSizeLimit: 20,
                label: 'Upload Photo',
                onMediaChanged: _onMediaChanged,
              ),
            if (_newPhotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildUploadStatus(),
            ],
            SizedBox(height: responsive.verticalSpacing,),
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
                _isSubmitting || _isUploadingMedia || _loadingActivityDetail,
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
            'Uploading photo...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      );
    }

    if (_uploadedPhotoCount == _newPhotos.length) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Uploaded $_uploadedPhotoCount/${_newPhotos.length} photo(s)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.error_outline, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          'Uploaded $_uploadedPhotoCount/${_newPhotos.length} photo(s)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}
