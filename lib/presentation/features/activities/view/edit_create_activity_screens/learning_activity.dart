import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/shared/common/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/api_error_handler.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/entities/activity_type_details.dart';
import '../../../../../domain/features/activity/usecases/approve_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/reject_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../../../../shared/services/image_upload/image_upload_service.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_dropdown.dart';
import '../../widgets/activity_dropdown_widget.dart';
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
import '../widgets/activity_admin_approve_reject_bar.dart';

class LearningActivityScreen extends StatefulWidget {
  const LearningActivityScreen({
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
  State<LearningActivityScreen> createState() => _LearningActivityScreenState();
}

class _LearningActivityScreenState extends State<LearningActivityScreen> {
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

  List<ActivityTypeParameterOption> _activityNameParamOptions = [];
  List<ActivityTypeParameterOption> _categoryParamOptions = [];
  List<String> _activityType = [];
  List<String> _category = [];
  String? _selectedCategory;
  String? _selectedActivityType;

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
  bool _loadingLearningOptions = false;
  bool _loadingActivityDetail = false;
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

  int get _uploadedPhotoCount => _newPhotos
      .where((f) => _uploadedAssetCodeByPath.containsKey(f.path))
      .length;

  late final GetClassroomActivitySettingsUseCase _getActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final CreateActivityUseCase _createActivityUseCase;
  late final GetActivityUseCase _getActivityUseCase;
  late final UpdateActivityUseCase _updateActivityUseCase;
  late final ApproveActivityUseCase _approveActivityUseCase;
  late final RejectActivityUseCase _rejectActivityUseCase;
  late final ImageUploadService _imageUploadService;

  ActivityItem get _effectiveActivity => _liveActivity ?? widget.activityData!;
  bool _isAdminApprovalRequired(ActivityItem activity) {
    final status = (activity.approvalStatus ?? '').trim().toUpperCase();
    return status.isNotEmpty && status != 'NOT_REQUIRED';
  }

  String? _pickStaffPresentCode(List<Map<String, dynamic>> rows) {
    for (final p in rows) {
      final n = (p['parameterName'] ?? '').toString().trim().toLowerCase();
      if (n != 'staff present') continue;
      final v = (p['selectedOptionCode'] ?? p['valueText'] ?? p['valueNumber'] ?? '')
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
    _getActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();
    _createActivityUseCase = serviceLocator<CreateActivityUseCase>();
    _getActivityUseCase = serviceLocator<GetActivityUseCase>();
    _updateActivityUseCase = serviceLocator<UpdateActivityUseCase>();
    _approveActivityUseCase = serviceLocator<ApproveActivityUseCase>();
    _rejectActivityUseCase = serviceLocator<RejectActivityUseCase>();
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
      _requireAdminApproval = _isAdminApprovalRequired(activity);
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text =
          activity.description ?? activity.whatHappened ?? '';
      _selectedActivityType = activity.activityType?.trim();
      final cats = activity.categoryType;
      _selectedCategory = (cats != null && cats.isNotEmpty) ? cats.first : null;
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
        await _loadLearningParameterOptions();
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
    final code = _effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _isApprovingOrRejecting = true);
    try {
      final msg = await _approveActivityUseCase(code: code);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(context: context, message: msg, isSuccess: true);
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

  Future<void> _rejectPendingActivity() async {
    final code = _effectiveActivity.activityCode?.trim();
    if (code == null || code.isEmpty) return;
    setState(() => _isApprovingOrRejecting = true);
    try {
      final msg = await _rejectActivityUseCase(code: code);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(context: context, message: msg, isSuccess: true);
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
      final detail = await _getActivityUseCase(code: code);
      if (!mounted) return;
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
        _descriptionController.text =
            item.description ?? item.whatHappened ?? '';
        _selectedActivityType = item.activityType?.trim();
        final cats = item.categoryType;
        _selectedCategory = (cats != null && cats.isNotEmpty)
            ? cats.first
            : null;
        _activityTypeCode = item.activityTypeCode;
        _staffPresentCode = _pickStaffPresentCode(detail.parameterValues);
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
      await _loadLearningParameterOptions();
    } catch (e) {
      CoreUtils.logApiError('Prefetch activity for edit: $e');
    } finally {
      if (mounted) setState(() => _loadingActivityDetail = false);
    }
  }

  Future<void> _loadStaffContext() async {
    final storage = serviceLocator<StorageService>();
    final staffType =
        (await storage.getString(StorageKeys.staffType) ?? '').trim();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final organizationCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final staffCode = await resolveLoggedInStaffCode();
    final apiDisplayName = await resolveLoggedInStaffDisplayNameFromApi(
      staffCode: staffCode,
    );

    if (!mounted) return;
    setState(() {
      _staffName = apiDisplayName.isNotEmpty ? apiDisplayName : 'Staff';
      _staffType = staffType.toUpperCase();
      _staffCode = staffCode;
      _staffPresentCode = (staffCode ?? '').trim().isEmpty ? null : staffCode!.trim();
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
      ActivitySetting? learningSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('learning')) {
          learningSetting = s;
          break;
        }
      }
      if (learningSetting != null && mounted) {
        setState(() {
          _activityTypeCode = learningSetting!.activityTypeCode;
        });
        await _loadLearningParameterOptions();
      }
    } catch (e) {
      CoreUtils.logApiError(
        'Failed to load activity settings for Learning: $e',
      );
    }
  }

  /// Maps a UI label to [selectedOptionCode] only for dropdown-like parameters.
  /// Other types must use [value] — the API rejects [selectedOptionCode] otherwise.
  Map<String, dynamic>? _paramEntryForOption(
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
            return {'parameterCode': param.code, 'selectedOptionCode': oc};
          }
        }
      }
    }
    return {'parameterCode': param.code, 'value': v};
  }

  ActivityTypeParameter? _findActivityNameParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('activity') &&
          (n.contains('name') || n.contains('type'))) {
        return p;
      }
    }
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('learning') && !n.contains('categor')) return p;
    }
    return null;
  }

  ActivityTypeParameter? _findCategoryParameter(
    List<ActivityTypeParameter> parameters,
  ) {
    for (final p in parameters) {
      final n = p.parameterName.toLowerCase();
      if (n.contains('categor')) return p;
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

  Future<void> _loadLearningParameterOptions() async {
    final code = _activityTypeCode?.trim();
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _loadingLearningOptions = true);
    try {
      final details = await _getActivityTypeDetailsUseCase(code: code);
      if (!mounted) return;
      final activityParam = _findActivityNameParameter(details.parameters);
      final categoryParam = _findCategoryParameter(details.parameters);
      final activityOptions = List<ActivityTypeParameterOption>.from(
        activityParam?.options ?? const <ActivityTypeParameterOption>[],
      )..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      final categoryOptions = List<ActivityTypeParameterOption>.from(
        categoryParam?.options ?? const <ActivityTypeParameterOption>[],
      )..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      setState(() {
        _activityNameParamOptions = activityOptions;
        _categoryParamOptions = categoryOptions;
        _activityType = activityOptions
            .map((o) => (o.optionLabel ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        _category = categoryOptions
            .map((o) => (o.optionLabel ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        _selectedActivityType = _canonicalLabelFromOptions(
          _selectedActivityType,
          _activityNameParamOptions,
        );
        _selectedCategory = _canonicalLabelFromOptions(
          _selectedCategory,
          _categoryParamOptions,
        );
        _loadingLearningOptions = false;
      });
    } catch (e) {
      CoreUtils.logApiError('Failed to load Learning parameter options: $e');
      if (!mounted) return;
      setState(() => _loadingLearningOptions = false);
    }
  }

  Future<List<Map<String, dynamic>>> _ensurePhotoAssetsUploaded({
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
    final missing = _newPhotos
        .where((f) => !_uploadedAssetCodeByPath.containsKey(f.path))
        .toList();

    if (missing.isNotEmpty) {
      setState(() {
        _isUploadingMedia = true;
        _uploadProgressPercent = 0;
        _uploadCompletedCount = 0;
        _uploadTotalCount = missing.length;
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
        for (var i = 0; i < missing.length; i++) {
          final photo = missing[i];
          final fileIndex = i + 1;
          final totalFiles = missing.length;
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
    final normalizedPhotos = widget.isEdit && photos.length > 1
        ? <File>[photos.last]
        : photos;
    final photoCount =
        normalizedPhotos.length + remainingExistingPhotoUrls.length;
    final maxPhotoCount = widget.isEdit ? 1 : 2;
    final videoCount =
        (video != null ? 1 : 0) +
        ((remainingExistingVideoUrl != null &&
                remainingExistingVideoUrl.trim().isNotEmpty)
            ? 1
            : 0);
    if (photoCount > maxPhotoCount) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Maximum $maxPhotoCount photo${maxPhotoCount == 1 ? '' : 's'} can be attached.',
        isError: true,
      );
      return;
    }
    if (videoCount > 1) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Maximum 1 video can be attached.',
        isError: true,
      );
      return;
    }
    setState(() {
      _newPhotos = normalizedPhotos;
      _remainingExistingPhotoUrls =
          (widget.isEdit && normalizedPhotos.isNotEmpty)
          ? const []
          : List<String>.from(remainingExistingPhotoUrls);
      _uploadedAssetCodeByPath.removeWhere(
        (path, _) => !_newPhotos.any((f) => f.path == path),
      );
    });
    _uploadPhotosOnSelection();
  }

  Future<void> _uploadPhotosOnSelection() async {
    if (widget.readOnly || _newPhotos.isEmpty || _isUploadingMedia) return;

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


    if (_selectedActivityType == null ||
        _selectedActivityType!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select an Activity Name',
        isWarning: true,
      );
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a category',
        isWarning: true,
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isNotEmpty && description.length < 5) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Description must be at least 5 characters long',
        isWarning: true,
      );
      return;
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
            'Unable to determine activity type for Learning. Please check activity settings.',
        isError: true,
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
      final attachments = await _ensurePhotoAssetsUploaded(
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

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      final activityNameParam = _findActivityNameParameter(details.parameters);
      final categoryParam = _findCategoryParameter(details.parameters);

      Map<String, dynamic>? activityEntry = _paramEntryForOption(
        activityNameParam,
        _selectedActivityType!.trim(),
      );
      if (activityEntry == null && _selectedActivityType!.trim().isNotEmpty) {
        final c = findParamCode('activity') ?? findParamCode('learning');
        if (c != null && c.trim().isNotEmpty) {
          activityEntry = {
            'parameterCode': c,
            'value': _selectedActivityType!.trim(),
          };
        }
      }

      final categoryValue = _selectedCategory!.trim();
      Map<String, dynamic>? categoryEntry;
      if (categoryParam != null && categoryValue.isNotEmpty) {
        categoryEntry = _paramEntryForOption(categoryParam, categoryValue);
      }
      if (categoryEntry == null && categoryValue.isNotEmpty) {
        final fallbackCode = findParamCode('categor');
        if (fallbackCode != null && fallbackCode.trim().isNotEmpty) {
          categoryEntry = {
            'parameterCode': fallbackCode,
            'value': categoryValue,
          };
        }
      }

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';
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
        if (descParamCode != null && descParamCode.trim().isNotEmpty)
          {'parameterCode': descParamCode, 'value': description},
        if (activityEntry != null) activityEntry,
        if (categoryEntry != null) categoryEntry,
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
      selectedTime: _activityTime,
    );
    if (!isWithinAttendanceWindow) return;


    if (_selectedActivityType == null ||
        _selectedActivityType!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select an Activity Name',
        isWarning: true,
      );
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a category',
        isWarning: true,
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isNotEmpty && description.length < 5) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Description must be at least 5 characters long',
        isWarning: true,
      );
      return;
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
            'Unable to determine activity type for Learning. Please check activity settings.',
        isError: true,
      );
      return;
    }

    final activityDateIso = await activityUtcIsoFromSchoolWallClock(
      date: _activityDate!,
      time: _activityTime!,
    );

    if (_isUploadingMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please wait for the photo upload to finish',
        isWarning: true,
      );
      return;
    }

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

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      final activityNameParam = _findActivityNameParameter(details.parameters);
      final categoryParam = _findCategoryParameter(details.parameters);

      Map<String, dynamic>? activityEntry = _paramEntryForOption(
        activityNameParam,
        _selectedActivityType!.trim(),
      );
      if (activityEntry == null && _selectedActivityType!.trim().isNotEmpty) {
        final c = findParamCode('activity') ?? findParamCode('learning');
        if (c != null && c.trim().isNotEmpty) {
          activityEntry = {
            'parameterCode': c,
            'value': _selectedActivityType!.trim(),
          };
        }
      }

      final categoryValue = _selectedCategory!.trim();
      Map<String, dynamic>? categoryEntry;
      if (categoryParam != null && categoryValue.isNotEmpty) {
        categoryEntry = _paramEntryForOption(categoryParam, categoryValue);
      }
      if (categoryEntry == null && categoryValue.isNotEmpty) {
        final fallbackCode = findParamCode('categor');
        if (fallbackCode != null && fallbackCode.trim().isNotEmpty) {
          categoryEntry = {
            'parameterCode': fallbackCode,
            'value': categoryValue,
          };
        }
      }

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';
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
        if (descParamCode != null && descParamCode.trim().isNotEmpty)
          {'parameterCode': descParamCode, 'value': description},
        if (activityEntry != null) activityEntry,
        if (categoryEntry != null) categoryEntry,
      ];

      final patchAttachments =
          attachmentsForActivityPatchRequest(mergedRows);

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
          description: description,
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

  Future<void> _onPressedBottom() async {
    if (_isSubmitting || _isUploadingMedia) return;
    if (widget.readOnly) return;

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
            'Uploading photo... $_uploadProgressPercent% ($_uploadCompletedCount/$_uploadTotalCount)',
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
          Text(
            'Uploaded $_uploadCompletedCount/$_uploadTotalCount',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    if (_newPhotos.isEmpty) return const SizedBox.shrink();

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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: 'Learning',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            if (widget.isEdit && !widget.readOnly && _selectedStudents.length > 1) ...[
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
            Row(
              children: [
                Flexible(
                  child: ActivityDropdownWidget(
                    options: _activityType,
                    dropDownName: 'Activity Name',
                    selectedValue: _selectedActivityType,
                    isRequired: true,
                    isEnabled: _canInteract &&
                        !_loadingLearningOptions &&
                        _activityType.isNotEmpty,
                    onSelect: (value) {
                      setState(() {
                        _selectedActivityType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: CustomDropdown(
                    label: 'Category',
                    hintText: 'Select category',
                    items: _category,
                    selectedItem: _selectedCategory,
                    isEnabled: _canInteract &&
                        !_loadingLearningOptions &&
                        _category.isNotEmpty,
                    onSelect: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.verticalSpacing),
            Builder(
              builder: (context) {
                final isAdminPersona =
                    _isAdminDesignation;
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
                  isEditable: lockToLoggedInStaff
                      ? false
                      : _canInteract,
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
              hint: 'Enter Description',
              isRequired: false,
              readOnly: !_canInteract,
              maxLength: ActivityDescriptionLimits.maxLength,
            ),
            if (_showRequireAdminApprovalToggle)
              const SizedBox(height: 4),
            if (_showRequireAdminApprovalToggle)
              CustomToggle(
                label: 'Requires Admin Approval',
                isToggled: _requireAdminApproval,
                labelOnLeftSide: true,
                onToggle: (value) {
                  setState(() {
                    _requireAdminApproval = value;
                  });
                },
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
                  limit: widget.isEdit ? 1 : 2,
                  autoReplaceFirstPhotoWhenMaxReached: widget.isEdit,
                  initialPhotoUrls: _remainingExistingPhotoUrls.isNotEmpty
                      ? List<String>.from(_remainingExistingPhotoUrls)
                      : (_effectiveActivity.photoUrl != null &&
                                _effectiveActivity.photoUrl!.trim().isNotEmpty
                            ? [_effectiveActivity.photoUrl!.trim()]
                            : const []),
                  label: 'Upload Photos',
                  onMediaChanged: _onMediaChanged,
                ),
              )
            else
              MediaUploader(
                isRequired: false,
                allowVideo: false,
                allowPhoto: true,
                readOnly: widget.readOnly,
                isPictureBox: false,
                limit: 2,
                label: 'Upload Photos',
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActivityAdminApproveRejectBar(
                      visible: _showAdminApproveRejectActions,
                      isLoading: _isApprovingOrRejecting ||
                          _isSubmitting ||
                          _isUploadingMedia ||
                          _loadingActivityDetail ||
                          _loadingLearningOptions,
                      onApprove: _approvePendingActivity,
                      onReject: _rejectPendingActivity,
                    ),
                    if (!_showAdminApproveRejectActions)
                      CustomButtonLayout(
                      confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                      onPressedConfirm: _onPressedBottom,
                      showCancelButton: false,
                      isForm: false,
                      isLoading: _isSubmitting ||
                          _isApprovingOrRejecting ||
                          _isUploadingMedia ||
                          _loadingActivityDetail ||
                          _loadingLearningOptions,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}



