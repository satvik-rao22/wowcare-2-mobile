import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/selected_student_tile.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/storage/storage_service.dart';
import '../../../../../core/util/api_error_handler.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/usecases/create_shared_activities_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/services/image_upload/image_upload_service.dart';
import '../../widgets/activity_edit_student_scope_checkboxes.dart';
import '../../widgets/activity_student_display_tile.dart';
import '../../utils/activity_description_limits.dart';
import '../../utils/activity_staff_display.dart';
import '../../utils/activity_patch_attachments.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class PhotoVideoActivityScreen extends StatefulWidget {
  const PhotoVideoActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    required this.isPhoto,
    this.activityData,
    this.readOnly = false,
  });

  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final bool isPhoto;
  final ActivityItem? activityData;
  final bool readOnly;

  @override
  State<PhotoVideoActivityScreen> createState() => _PhotoVideoActivityScreenState();
}

class _PhotoVideoActivityScreenState extends State<PhotoVideoActivityScreen> {
  bool get _layoutAsEdit => widget.isEdit || widget.readOnly;
  bool get _canInteract => !widget.readOnly;

  List<Map<String, dynamic>> _selectedStudentsData = [];
  List<String> _selectedStudents = [];
  final TextEditingController _descriptionController = TextEditingController();

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

  List<File> _photos = [];
  File? _video;
  List<String> _existingPhotoUrls = [];
  String? _existingVideoUrl;
  /// URLs still shown in the editor; used to merge PATCH attachments without duplicating rows.
  List<String> _remainingExistingPhotoUrls = [];
  String? _remainingExistingVideoUrl;
  final Map<String, String> _uploadedAssetCodeByPath = {};
  List<Map<String, dynamic>> _uploadedAttachments = [];

  bool get _hasMedia =>
      _photos.isNotEmpty ||
      _video != null ||
      _existingPhotoUrls.isNotEmpty ||
      _existingVideoUrl != null;

  late final GetClassroomActivitySettingsUseCase _getSettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getDetailsUseCase;
  late final CreateSharedActivitiesUseCase _createSharedUseCase;
  late final GetActivityUseCase _getActivityUseCase;
  late final UpdateActivityUseCase _updateActivityUseCase;
  late final ImageUploadService _uploadService;

  ActivityItem get _effectiveActivity =>
      _liveActivity ?? widget.activityData!;

  @override
  void initState() {
    super.initState();
    _getSettingsUseCase = serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getDetailsUseCase = serviceLocator<GetActivityTypeDetailsUseCase>();
    _createSharedUseCase = serviceLocator<CreateSharedActivitiesUseCase>();
    _getActivityUseCase = serviceLocator<GetActivityUseCase>();
    _updateActivityUseCase = serviceLocator<UpdateActivityUseCase>();
    _uploadService = serviceLocator<ImageUploadService>();

    // Keep create flow aligned with other activity forms where date/time default
    // to "now" and are not blocked by initial widget callback timing.
    if (!widget.isEdit && !widget.readOnly) {
      _activityDate = DateTime.now();
      _activityTime = TimeOfDay.now();
    }

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents =
          _selectedStudentsData.map((student) => student['name'] as String).toList();
      _loadActivityTypeCode();
    } else if (_layoutAsEdit) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text = activity.description ?? '';
      _activityTypeCode = activity.activityTypeCode;
      _detailAttachmentRows = (activity.snapshotAttachments ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _applyExistingMediaFromAttachmentRows(
        activity.photoUrl,
        activity.videoUrl,
      );
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
        _descriptionController.text = item.description ?? '';
        _activityTypeCode = item.activityTypeCode;
        _detailAttachmentRows = detail.attachments
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _applyExistingMediaFromAttachmentRows(
          item.photoUrl,
          item.videoUrl,
        );
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

  /// Prefer URLs from raw attachment rows so PATCH merge matches any of
  /// delivery / thumbnail / artifact URLs the API returns.
  void _applyExistingMediaFromAttachmentRows(
    String? fallbackPhotoUrl,
    String? fallbackVideoUrl,
  ) {
    final rows = _detailAttachmentRows;
    if (widget.isPhoto) {
      final fromRows = imageDeliveryUrlsFromAttachmentRows(rows);
      if (fromRows.isNotEmpty) {
        _existingPhotoUrls = fromRows;
        _remainingExistingPhotoUrls = List<String>.from(fromRows);
      } else if (fallbackPhotoUrl != null && fallbackPhotoUrl.trim().isNotEmpty) {
        _existingPhotoUrls = [fallbackPhotoUrl.trim()];
        _remainingExistingPhotoUrls = List<String>.from(_existingPhotoUrls);
      } else {
        _existingPhotoUrls = [];
        _remainingExistingPhotoUrls = [];
      }
      _existingVideoUrl = null;
      _remainingExistingVideoUrl = null;
    } else {
      final fromRows = videoDeliveryUrlsFromAttachmentRows(rows);
      if (fromRows.isNotEmpty) {
        _existingVideoUrl = fromRows.first;
        _remainingExistingVideoUrl = _existingVideoUrl;
      } else {
        _existingVideoUrl = fallbackVideoUrl;
        _remainingExistingVideoUrl = _existingVideoUrl;
      }
      _existingPhotoUrls = [];
      _remainingExistingPhotoUrls = [];
    }
  }

  Future<void> _loadStaffContext() async {
    final storage = serviceLocator<StorageService>();
    final displayName =
        (await storage.getString(StorageKeys.displayName) ?? '').trim();
    final staffType =
        (await storage.getString(StorageKeys.staffType) ?? '').trim();
    final schoolCode =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
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

  Future<void> _loadActivityTypeCode() async {
    if (widget.selectedStudents == null || widget.selectedStudents!.isEmpty) return;
    final first = widget.selectedStudents!.first;
    final dynamic classroomCodeRaw = first['classroomCode'] ?? first['classroomcode'];
    final classroomCode = classroomCodeRaw is String ? classroomCodeRaw.trim() : '';
    if (classroomCode.isEmpty) return;
    try {
      final List<ActivitySetting> settings =
          await _getSettingsUseCase(classroomCode: classroomCode);
      ActivitySetting? matched;
      for (final setting in settings) {
        final name = setting.activityTypeName.toLowerCase();
        if (widget.isPhoto && name.contains('photo')) {
          matched = setting;
          break;
        }
        if (!widget.isPhoto && name.contains('video')) {
          matched = setting;
          break;
        }
      }
      if (matched != null) {
        _activityTypeCode = matched.activityTypeCode;
      } else {
        _activityTypeCode = null;
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: widget.isPhoto
                ? 'Photo activity type not configured for this classroom.'
                : 'Video activity type not configured for this classroom.',
            isError: true,
          );
        }
      }
    } catch (_) {}
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
      _photos = photos;
      _video = video;
      _existingPhotoUrls = remainingExistingPhotoUrls;
      _existingVideoUrl = remainingExistingVideoUrl;
      _remainingExistingPhotoUrls = List<String>.from(remainingExistingPhotoUrls);
      _remainingExistingVideoUrl = remainingExistingVideoUrl;
      _uploadedAttachments = [];
    });
    _uploadMediaOnSelection();
  }

  Future<void> _uploadMediaOnSelection() async {
    if (_isUploadingMedia) return;
    if (_photos.isEmpty && _video == null) return;

    final activityTypeCode = _activityTypeCode;
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;

    if (activityTypeCode == null ||
        activityTypeCode.isEmpty ||
        schoolCode == null ||
        schoolCode.isEmpty ||
        organizationCode == null ||
        organizationCode.isEmpty) {
      return;
    }

    final classroomCodeRaw = _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode = classroomCodeRaw is String ? classroomCodeRaw.trim() : '';
    final scopeMaps = widget.isEdit
        ? studentMapsForScopedActivityUpdate(
            allStudentMaps: _selectedStudentsData,
            checkedIndices: _scopedEditStudentIndices,
          )
        : _selectedStudentsData;
    final studentCodes = scopeMaps
        .map((s) => (s['studentCode'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();

    if (classroomCode.isEmpty || studentCodes.isEmpty) return;

    try {
      setState(() => _isUploadingMedia = true);
      final attachments = await _uploadAndBuildAttachments(
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        studentCodes: studentCodes,
      );
      if (mounted) {
        setState(() {
          _uploadedAttachments = attachments;
        });
      }
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: widget.isPhoto
            ? 'Photo uploaded successfully'
            : 'Video uploaded successfully',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _uploadAndBuildAttachments({
    required String classroomCode,
    required String activityTypeCode,
    required String organizationCode,
    required String schoolCode,
    required List<String> studentCodes,
  }) async {
    // Enforce media mode per screen type to avoid cross-posting
    // video as image/photo activity and vice versa.
    final media = widget.isPhoto
        ? <File>[..._photos]
        : <File>[if (_video != null) _video!];
    if (media.isEmpty) return const [];
    // Asset codes are scoped to a specific upload session. Reusing a previous
    // session's cached assetCode causes polling on a new session with no assets.
    _uploadedAssetCodeByPath.clear();
    final uploadSession = await _uploadService.createActivityUploadSession(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      activityTypeCode: activityTypeCode,
      bindingMode: 'SHARED',
      studentCodes: studentCodes,
    );
    final uploadedCodes = <String>[];
    for (final file in media) {
      if (_uploadedAssetCodeByPath.containsKey(file.path)) {
        uploadedCodes.add(_uploadedAssetCodeByPath[file.path]!);
        continue;
      }
      final lower = file.path.toLowerCase();
      final isVideoByExt =
          lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm');
      final forceVideoPayload = !widget.isPhoto;
      final isVideo = forceVideoPayload || isVideoByExt;
      final extension = lower.contains('.') ? lower.split('.').last : (isVideo ? 'mp4' : 'jpg');
      final generatedFileName =
          '${isVideo ? 'video' : 'photo'}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final contentType = isVideo
          ? (lower.endsWith('.mov')
              ? 'video/quicktime'
              : lower.endsWith('.webm')
                  ? 'video/webm'
                  : 'video/mp4')
          : 'image/jpeg';
      final presign = await _uploadService.createAssetPresign(
        sessionCode: uploadSession.sessionCode,
        documentApiBasePath: uploadSession.documentApiBasePath,
        fileName: generatedFileName,
        contentType: contentType,
        contentLengthBytes: await file.length(),
        mediaType: isVideo ? 'VIDEO' : 'IMAGE',
        ownerType: 'CLASSROOM',
        ownerCode: classroomCode,
      );
      await _uploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: contentType,
      );
      await _uploadService.completeAssetUpload(
        sessionCode: uploadSession.sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: uploadSession.documentApiBasePath,
      );
      _uploadedAssetCodeByPath[file.path] = presign.assetCode;
      uploadedCodes.add(presign.assetCode);
    }

    await _uploadService.waitUntilAssetsReady(
      sessionCode: uploadSession.sessionCode,
      expectedAssetCodes: uploadedCodes,
    );
    return uploadedCodes.map((code) => <String, dynamic>{'assetCode': code}).toList();
  }

  Future<void> _submitCreate() async {
    if (_isSubmitting) return;
    if (_layoutAsEdit) return;
    if (_isUploadingMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: widget.isPhoto
            ? 'Please wait until photo upload completes.'
            : 'Please wait until video upload completes.',
        isWarning: true,
      );
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
    if (!_hasMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: widget.isPhoto
            ? 'Please upload a photo before adding activity.'
            : 'Please upload a video before adding activity.',
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
    final classroomCodeRaw =
        _selectedStudentsData.first['classroomCode'] ?? _selectedStudentsData.first['classroomcode'];
    final classroomCode = classroomCodeRaw is String ? classroomCodeRaw.trim() : '';
    if (classroomCode.isEmpty) return;
    final studentCodes = _selectedStudentsData
        .map((s) => (s['studentCode'] as String?)?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toList();
    if (studentCodes.isEmpty) return;

    final staffCode = _staffCode ?? await resolveLoggedInStaffCode();
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;
    final activityTypeCode = _activityTypeCode;
    if (staffCode == null ||
        schoolCode == null ||
        organizationCode == null ||
        activityTypeCode == null ||
        staffCode.isEmpty ||
        schoolCode.isEmpty ||
        organizationCode.isEmpty ||
        activityTypeCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Missing required context for activity creation.',
        isError: true,
      );
      return;
    }

    final descriptionTrim = _descriptionController.text.trim();
    if (descriptionTrim.isNotEmpty && descriptionTrim.length < 5) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Description must be at least 5 characters long',
        isWarning: true,
      );
      return;
    }
    if (descriptionTrim.length > ActivityDescriptionLimits.maxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ActivityDescriptionLimits.maxLengthMessage,
        isWarning: true,
      );
      return;
    }

    final activityDateIso = DateTime(
      _activityDate!.year,
      _activityDate!.month,
      _activityDate!.day,
      _activityTime!.hour,
      _activityTime!.minute,
    ).toUtc().toIso8601String();

    setState(() {
      _isSubmitting = true;
    });
    try {
      final details = await _getDetailsUseCase(code: activityTypeCode);
      String? findCodeByNameOrType(String contains, String dataType) {
        for (final p in details.parameters) {
          final dt = (p.dataType ?? '').toUpperCase();
          final n = p.parameterName.toLowerCase();
          if (dt == dataType.toUpperCase() || n.contains(contains)) {
            return p.code;
          }
        }
        return null;
      }
      final localDate =
          '${_activityDate!.year.toString().padLeft(4, '0')}-${_activityDate!.month.toString().padLeft(2, '0')}-${_activityDate!.day.toString().padLeft(2, '0')}';
      final localTime =
          '${_activityTime!.hour.toString().padLeft(2, '0')}:${_activityTime!.minute.toString().padLeft(2, '0')}:00';
      final createParameterValues = <Map<String, dynamic>>[
        if (findCodeByNameOrType('date', 'DATE') != null)
          {
            'parameterCode': findCodeByNameOrType('date', 'DATE'),
            'value': localDate,
          },
        if (findCodeByNameOrType('time', 'TIME') != null)
          {
            'parameterCode': findCodeByNameOrType('time', 'TIME'),
            'value': localTime,
          },
        if (findCodeByNameOrType('staff', 'TEXT') != null)
          {
            'parameterCode': findCodeByNameOrType('staff', 'TEXT'),
            'value': staffCode,
          },
        if (descriptionTrim.isNotEmpty &&
            findCodeByNameOrType('description', 'TEXT') != null)
          {
            'parameterCode': findCodeByNameOrType('description', 'TEXT'),
            'value': descriptionTrim,
          },
      ];

      final attachments = _uploadedAttachments.isNotEmpty
          ? _uploadedAttachments
          : await _uploadAndBuildAttachments(
              classroomCode: classroomCode,
              activityTypeCode: activityTypeCode,
              organizationCode: organizationCode,
              schoolCode: schoolCode,
              studentCodes: studentCodes,
            );

      // Shared media flow (photos + videos): create one shared activity per attachment.
      await _createSharedUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: descriptionTrim,
        attachments: attachments,
        parameterValues: createParameterValues,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Shared activity created successfully',
        isSuccess: true,
      );
      Navigator.of(context).popUntil((route) => route.settings.name == ActivityFeedScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(error),
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

    if (_isUploadingMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: widget.isPhoto
            ? 'Please wait until photo upload completes.'
            : 'Please wait until video upload completes.',
        isWarning: true,
      );
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

    if (!_hasMedia) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: widget.isPhoto
            ? 'Please keep or upload a photo before saving.'
            : 'Please keep or upload a video before saving.',
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

    final classroomCodeRaw = _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode =
        classroomCodeRaw is String ? classroomCodeRaw.trim() : '';
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

    final staffCode = _staffCode ?? await resolveLoggedInStaffCode();
    final schoolCode = _schoolCode;
    final organizationCode = _organizationCode;
    final activityTypeCode = _activityTypeCode;
    if (staffCode == null ||
        schoolCode == null ||
        organizationCode == null ||
        activityTypeCode == null ||
        staffCode.isEmpty ||
        schoolCode.isEmpty ||
        organizationCode.isEmpty ||
        activityTypeCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Missing required context for activity update.',
        isError: true,
      );
      return;
    }

    final localDate =
        '${_activityDate!.year.toString().padLeft(4, '0')}-${_activityDate!.month.toString().padLeft(2, '0')}-${_activityDate!.day.toString().padLeft(2, '0')}';
    final localTime =
        '${_activityTime!.hour.toString().padLeft(2, '0')}:${_activityTime!.minute.toString().padLeft(2, '0')}:00';
    final activityDateIso = DateTime(
      _activityDate!.year,
      _activityDate!.month,
      _activityDate!.day,
      _activityTime!.hour,
      _activityTime!.minute,
    ).toUtc().toIso8601String();

    final desc = _descriptionController.text.trim();
    if (desc.isNotEmpty && desc.length < 5) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Description must be at least 5 characters long',
        isWarning: true,
      );
      return;
    }
    if (desc.length > ActivityDescriptionLimits.maxLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ActivityDescriptionLimits.maxLengthMessage,
        isWarning: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      List<Map<String, dynamic>> newUploads = const [];
      if (_photos.isNotEmpty || _video != null) {
        newUploads = _uploadedAttachments.isNotEmpty
            ? _uploadedAttachments
            : await _uploadAndBuildAttachments(
                classroomCode: classroomCode,
                activityTypeCode: activityTypeCode,
                organizationCode: organizationCode,
                schoolCode: schoolCode,
                studentCodes: studentCodes,
              );
      }

      final remainingNorm = <String>{
        for (final u in _remainingExistingPhotoUrls)
          normalizeActivityDeliveryUrl(u),
        if (_remainingExistingVideoUrl != null &&
            _remainingExistingVideoUrl!.trim().isNotEmpty)
          normalizeActivityDeliveryUrl(_remainingExistingVideoUrl),
      }..removeWhere((e) => e.isEmpty);

      final mergedRows = mergeAttachmentRowsForEditPatch(
        existingRows: _detailAttachmentRows
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        newUploadRows: newUploads,
        remainingNormalizedDeliveryUrls: remainingNorm,
      );
      final patchAttachments =
          attachmentsForActivityPatchRequest(mergedRows);

      final details = await _getDetailsUseCase(code: activityTypeCode);
      String? findCode(String contains, {String? dataType}) {
        final dtFilter = dataType?.toUpperCase();
        for (final p in details.parameters) {
          final n = p.parameterName.toLowerCase();
          final dt = (p.dataType ?? '').toUpperCase();
          if ((dtFilter != null && dt == dtFilter) || n.contains(contains)) {
            return p.code;
          }
        }
        return null;
      }
      final dateCode = findCode('date', dataType: 'DATE');
      final timeCode = findCode('time', dataType: 'TIME');
      final staffCodeParam = findCode('staff');
      final descriptionCode = findCode('description');
      final parameterValues = <Map<String, dynamic>>[
        if (dateCode != null) {'parameterCode': dateCode, 'value': localDate},
        if (timeCode != null) {'parameterCode': timeCode, 'value': localTime},
        if (staffCodeParam != null)
          {'parameterCode': staffCodeParam, 'value': staffCode},
        if (descriptionCode != null)
          {'parameterCode': descriptionCode, 'value': desc},
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
          description: desc,
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
      Navigator.of(context).popUntil(
        (route) => route.settings.name == ActivityFeedScreen.routeName,
      );
    } catch (error) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(error),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onSaveOrAddPressed() async {
    if (widget.readOnly) return;
    if (widget.isEdit) {
      await _submitUpdateActivity();
      return;
    }
    await _submitCreate();
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
      title: widget.isPhoto ? 'Photo' : 'Video',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    final name = _selectedStudents[index];
                    return SelectedStudentTile(
                      name: name,
                      onTap: () => setState(() {
                        _selectedStudents.remove(name);
                        _selectedStudentsData.removeWhere(
                          (m) => (m['name'] as String?) == name,
                        );
                      }),
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
              Row(
                children: [
                  Flexible(
                    child: DateWidget(
                      isEditable: false,
                      isRequired: true,
                      initialDate:
                          _layoutAsEdit ? _effectiveActivity.date : null,
                      onDateChanged: (d) => _activityDate = d,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: TimeWidget(
                      isEditable: _layoutAsEdit ? _canInteract : true,
                      isRequired: true,
                      prefilledTime:
                          _layoutAsEdit ? _effectiveActivity.time : null,
                      onTimeChanged: (t) => _activityTime = t,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.verticalSpacing),
              IgnorePointer(
                ignoring: _layoutAsEdit && !_canInteract,
                child: MediaUploader(
                  isRequired: true,
                  allowVideo: !widget.isPhoto,
                  allowPhoto: widget.isPhoto,
                  readOnly: widget.readOnly,
                  onMediaChanged:
                      _layoutAsEdit && !_canInteract ? null : _onMediaChanged,
                  initialPhotoUrls:
                      _layoutAsEdit ? _existingPhotoUrls : const [],
                  initialVideoUrl: _layoutAsEdit ? _existingVideoUrl : null,
                ),
              ),
              if (_isUploadingMedia) ...[
                const SizedBox(height: 8),
                Text(
                  widget.isPhoto ? 'Uploading photo...' : 'Uploading video...',
                  style: const TextStyle(color: AppColors.primaryColor, fontSize: 13),
                ),
              ],
              SizedBox(height: responsive.verticalSpacing),
              StaffPresentWidget(
                staffName: (widget.isEdit &&
                        !widget.readOnly &&
                        !(_staffType == 'SCHOOL_ADMIN' ||
                            _staffType == 'ORGANIZATION_ADMIN'))
                    ? _staffName
                    : staffPresentLabelForActivity(
                        layoutAsEdit: _layoutAsEdit,
                        activityCreatedBy:
                            _layoutAsEdit ? _effectiveActivity.createdBy : '',
                        loggedInDisplayName: _staffName,
                      ),
                isEditable: (widget.isEdit &&
                        !widget.readOnly &&
                        !(_staffType == 'SCHOOL_ADMIN' ||
                            _staffType == 'ORGANIZATION_ADMIN'))
                    ? false
                    : (_layoutAsEdit ? _canInteract : false),
              ),
              SizedBox(height: responsive.verticalSpacing),
              InputWidget(
                controller: _descriptionController,
                height: 100,
                hint: 'Enter Description',
                readOnly: !_canInteract,
                maxLength: ActivityDescriptionLimits.maxLength,
              ),
            ],
          ),
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
                      _isUploadingMedia ||
                      _loadingActivityDetail,
                ),
              ),
            ),
    );
  }
}
