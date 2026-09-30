import 'dart:async';
import 'package:wowcare/core/observability/media_upload_trace.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/entities/activity_type_details.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_edit_student_scope_checkboxes.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_student_display_tile.dart';
import 'package:wowcare/domain/features/activity/services/activity_description_limits.dart';
import 'package:wowcare/domain/features/activity/services/activity_selected_date_prefill.dart';
import 'package:wowcare/presentation/features/activities/view/activity_attendance_window_feedback.dart';
import 'package:wowcare/domain/features/activity/services/activity_school_time.dart';
import 'package:wowcare/domain/features/activity/services/activity_staff_display.dart';
import 'package:wowcare/data/features/activity/mappers/activity_patch_attachments.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/widgets/activity_admin_approve_reject_bar.dart';

class PhotoVideoActivityScreen extends StatelessWidget {
  static const String routeName = '/activity/photo-video';

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
  Widget build(BuildContext context) {
    return _PhotoVideoActivityView(
      selectedStudents: selectedStudents,
      isEdit: isEdit,
      isPhoto: isPhoto,
      activityData: activityData,
      readOnly: readOnly,
    );
  }
}

class _PhotoVideoActivityView extends StatefulWidget {
  const _PhotoVideoActivityView({
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
  State<_PhotoVideoActivityView> createState() =>
      _PhotoVideoActivityViewState();
}

class _PhotoVideoActivityViewState extends State<_PhotoVideoActivityView> {
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
  bool _isSubmitting = false;
  bool _isApprovingOrRejecting = false;
  bool _isSavingBeforeApprove = false;
  bool _lastUpdateSucceeded = false;
  bool _loadingActivityDetail = false;
  ActivityItem? _liveActivity;
  final Set<int> _scopedEditStudentIndices = {};
  List<Map<String, dynamic>> _detailAttachmentRows = [];
  bool _isUploadingMedia = false;
  int _uploadProgressPercent = 0;
  int _uploadCompletedCount = 0;
  int _uploadTotalCount = 0;
  bool _isMediaProcessing = false;
  String _mediaProcessingStatusText = '';
  Timer? _mediaProcessingPollTimer;
  String? _processingSessionCode;
  List<String> _processingAssetCodes = const [];

  List<File> _photos = [];
  File? _video;
  List<String> _existingPhotoUrls = [];
  String? _existingVideoUrl;

  /// URLs still shown in the editor; used to merge PATCH attachments without duplicating rows.
  List<String> _remainingExistingPhotoUrls = [];
  String? _remainingExistingVideoUrl;
  final Map<String, String> _uploadedAssetCodeByPath = {};

  /// The upload context the [_uploadedAssetCodeByPath] cache belongs to. Retried
  /// saves with the SAME context reuse the cache (no re-upload); a context
  /// change clears it. See [_uploadAndBuildAttachments].
  String? _uploadContextKey;
  List<ActivityAttachment> _uploadedAttachments = [];

  bool get _hasMedia =>
      _photos.isNotEmpty ||
      _video != null ||
      _existingPhotoUrls.isNotEmpty ||
      _existingVideoUrl != null;

  ActivityEditorCubit get _editor => context.read<ActivityEditorCubit>();

  /// Cancels any in-flight activity media upload when this screen is disposed,
  /// so a large video PUT doesn't keep burning bandwidth after the user leaves.
  final CancelToken _uploadCancelToken = CancelToken();

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

  String? _findParameterCode(
    List<ActivityTypeParameter> parameters, {
    String? contains,
    String? exactName,
    String? dataType,
  }) {
    final containsNeedle = contains?.trim().toLowerCase();
    final exactNeedle = exactName?.trim().toLowerCase();
    final dataTypeNeedle = dataType?.trim().toUpperCase();

    for (final p in parameters) {
      final name = p.parameterName.trim().toLowerCase();
      final type = (p.dataType ?? '').trim().toUpperCase();
      final matchesExact = exactNeedle != null && name == exactNeedle;
      final matchesContains =
          containsNeedle != null && name.contains(containsNeedle);
      final matchesType = dataTypeNeedle != null && type == dataTypeNeedle;
      if (matchesExact || matchesContains || matchesType) {
        final code = p.code.trim();
        if (code.isNotEmpty) return code;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _editor.bootstrapSchoolTimezone();

    // Create flow: let [DateWidget]/[TimeWidget] apply school zone after
    // [resolveForCurrentSchool] (avoid stale [lastKnownTimeZone] from classroom tab).
    if (!widget.isEdit && !widget.readOnly) {
      _activityDate = null;
      _activityTime = null;
    }

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData
          .map((student) => student['name'] as String)
          .toList();
      _activityDate = resolveSelectedAttendanceDate(_selectedStudentsData);
      _loadActivityTypeCode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncSchoolAttendanceDateForCreate();
      });
    } else if (_layoutAsEdit) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _requireAdminApproval = _isAdminApprovalRequired(activity);
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
          final dt = activityDateTimeForDisplayFromIso(iso.trim());
          _activityDate = DateTime(dt.year, dt.month, dt.day);
          _activityTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (e) {
          AppLogger.d('unparsable activityDateIso: $e');
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _prefetchActivityForEdit();
      });
    }
    _loadStaffContext();
    _restorePendingProcessingPollIfAny();
  }

  Future<void> _syncSchoolAttendanceDateForCreate() async {
    if (!mounted || _layoutAsEdit) return;
    if (_selectedStudentsData.isEmpty) return;
    await _editor.ensureAttendanceDateOnStudentMapsForSchoolToday(
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
        _activityTypeCode = item.activityTypeCode;
        _staffPresentCode = _pickStaffPresentCode(detail.parameterValues);
        _detailAttachmentRows = detail.attachments
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _applyExistingMediaFromAttachmentRows(item.photoUrl, item.videoUrl);
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
      } else if (fallbackPhotoUrl != null &&
          fallbackPhotoUrl.trim().isNotEmpty) {
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

  Future<void> _loadActivityTypeCode() async {
    if (widget.selectedStudents == null || widget.selectedStudents!.isEmpty)
      return;
    final first = widget.selectedStudents!.first;
    final dynamic classroomCodeRaw =
        first['classroomCode'] ?? first['classroomcode'];
    final classroomCode = classroomCodeRaw is String
        ? classroomCodeRaw.trim()
        : '';
    if (classroomCode.isEmpty) return;
    try {
      final List<ActivitySetting> settings = await _editor
          .getClassroomActivitySettings(classroomCode: classroomCode);
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
    } catch (e) {
      AppLogger.d('getClassroomActivitySettings failed for $classroomCode: $e');
    }
  }

  void _onMediaChanged(
    List<File> photos,
    File? video,
    List<String> remainingExistingPhotoUrls,
    String? remainingExistingVideoUrl,
  ) {
    // For video activities, picking a new video should replace the previous one.
    // Keeping both the existing video URL and the newly uploaded asset causes the
    // PATCH payload to include multiple attachments, which the backend rejects
    // for grouped activity cards.
    if (!widget.isPhoto && video != null) {
      remainingExistingVideoUrl = null;
    }
    final photoCount = photos.length + remainingExistingPhotoUrls.length;
    final videoCount =
        (video != null ? 1 : 0) +
        ((remainingExistingVideoUrl != null &&
                remainingExistingVideoUrl.trim().isNotEmpty)
            ? 1
            : 0);
    final maxPhotoCount = widget.isPhoto ? 10 : 1;
    if (photoCount > maxPhotoCount) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Maximum $maxPhotoCount photo${maxPhotoCount == 1 ? '' : 's'} can be attached.',
        isError: true,
      );
      return;
    }
    const maxVideoCount = 1;
    if (videoCount > maxVideoCount) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Maximum $maxVideoCount videos can be attached.',
        isError: true,
      );
      return;
    }
    setState(() {
      _photos = photos;
      _video = video;
      _existingPhotoUrls = remainingExistingPhotoUrls;
      _existingVideoUrl = remainingExistingVideoUrl;
      _remainingExistingPhotoUrls = List<String>.from(
        remainingExistingPhotoUrls,
      );
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

    final classroomCodeRaw =
        _selectedStudentsData.first['classroomCode'] ??
        _selectedStudentsData.first['classroomcode'];
    final classroomCode = classroomCodeRaw is String
        ? classroomCodeRaw.trim()
        : '';
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
      setState(() {
        _isUploadingMedia = true;
        _uploadProgressPercent = 0;
        _uploadCompletedCount = 0;
      });
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
      MediaUploadTrace.stage(MediaUploadStage.uploadSucceeded);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: widget.isPhoto
            ? 'Photo uploaded. Processing continues in background.'
            : 'Video uploaded. Processing continues in background.',
        isSuccess: true,
      );
    } catch (error, stackTrace) {
      // A cancellation (the screen was disposed mid-upload) is expected — don't
      // surface it as an error. Non-cancel failures still show as before.
      if (!(error is DioException && CancelToken.isCancel(error))) {
        MediaUploadTrace.stage(MediaUploadStage.uploadFailed);
        // Terminal failure of the whole flow: everything already uploaded is
        // discarded and the user is back to square one. Still non-fatal — the
        // UI surfaces it and Save can be retried.
        MediaUploadTrace.failure(
          MediaUploadStage.uploadFailed,
          error,
          stackTrace,
        );
        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: ApiErrorHandler.extractErrorMessage(error),
          isError: true,
        );
      } else {
        MediaUploadTrace.stage(MediaUploadStage.uploadCancelled);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<List<ActivityAttachment>> _uploadAndBuildAttachments({
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
    if (mounted) {
      setState(() => _uploadTotalCount = media.length);
    }
    // Single student → PER_STUDENT, multiple → SHARED. Owner follows the same
    // rule: STUDENT/studentCode for per-student, CLASSROOM/classroomCode shared.
    final isShared = studentCodes.length > 1;
    final bindingMode = isShared ? 'SHARED' : 'PER_STUDENT';
    final ownerType = isShared ? 'CLASSROOM' : 'STUDENT';
    final ownerCode = isShared ? classroomCode : studentCodes.first;
    // Asset codes are session-scoped for POLLING but stay valid to LINK at
    // create time. Keep the already-uploaded map across retries with the SAME
    // upload context, so a Save retried after a partial failure reuses what
    // already uploaded instead of re-uploading every file into a fresh session
    // (which orphans the first set); clear it only when the context actually
    // changes. Newly-uploaded files are polled against THIS run's session; the
    // reused ones were already confirmed ready in the run that uploaded them.
    final contextKey = [
      organizationCode.trim(),
      schoolCode.trim(),
      classroomCode.trim(),
      (studentCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            ..sort())
          .join(','),
      activityTypeCode.trim(),
      bindingMode,
    ].join('|');
    if (_uploadContextKey != contextKey) {
      _uploadedAssetCodeByPath.clear();
      _uploadContextKey = contextKey;
    }
    final missing = media
        .where((f) => !_uploadedAssetCodeByPath.containsKey(f.path))
        .toList();

    String? uploadedSessionCode;
    var newlyUploadedCodes = const <String>[];
    if (missing.isNotEmpty) {
      final items = <ActivityUploadItem>[];
      for (final file in missing) {
        final lower = file.path.toLowerCase();
        final isVideoByExt =
            lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.webm');
        final forceVideoPayload = !widget.isPhoto;
        final isVideo = forceVideoPayload || isVideoByExt;
        final extension = lower.contains('.')
            ? lower.split('.').last
            : (isVideo ? 'mp4' : 'jpg');
        final generatedFileName =
            '${isVideo ? 'video' : 'photo'}_${AppTime.nowUtc().millisecondsSinceEpoch}.$extension';
        final contentType = isVideo
            ? (lower.endsWith('.mov')
                  ? 'video/quicktime'
                  : lower.endsWith('.webm')
                  ? 'video/webm'
                  : 'video/mp4')
            : 'image/jpeg';
        items.add(
          ActivityUploadItem(
            file: file,
            fileName: generatedFileName,
            contentType: contentType,
            mediaType: isVideo ? 'VIDEO' : 'IMAGE',
          ),
        );
      }
      final result = await _editor.uploadActivityAssets(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        bindingMode: bindingMode,
        studentCodes: studentCodes,
        ownerType: ownerType,
        ownerCode: ownerCode,
        items: items,
        onItemProgress: (itemIndex, totalItems, percent) {
          if (!mounted) return;
          final overallFraction =
              ((itemIndex - 1) + (percent / 100)) / totalItems;
          final overallPercent = (overallFraction * 100).clamp(0, 100).round();
          setState(() => _uploadProgressPercent = overallPercent);
        },
        onItemComplete: (completed, total) {
          if (mounted) {
            setState(() => _uploadCompletedCount = completed);
          }
        },
        cancelToken: _uploadCancelToken,
      );
      _uploadedAssetCodeByPath.addAll(result.assetCodeByPath);
      uploadedSessionCode = result.sessionCode;
      newlyUploadedCodes = result.newAssetCodes;
    }

    if (mounted) {
      setState(() => _uploadProgressPercent = 100);
    }
    // Poll only the codes uploaded in THIS run's session — reused codes were
    // already confirmed ready and belong to a prior session.
    if (uploadedSessionCode != null && newlyUploadedCodes.isNotEmpty) {
      _startProcessingPoll(
        sessionCode: uploadedSessionCode,
        assetCodes: newlyUploadedCodes,
        persist: true,
      );
    }
    final uploadedCodes = media
        .map((f) => _uploadedAssetCodeByPath[f.path]!)
        .toList();
    return uploadedCodes.map((code) {
      if (isShared) {
        return ActivityAttachment(assetCode: code);
      }
      return ActivityAttachment(
        assetCode: code,
        studentCode: ownerCode,
        bindingMode: bindingMode,
      );
    }).toList();
  }

  Future<void> _restorePendingProcessingPollIfAny() async {
    try {
      final raw = await _editor.getPendingUploadPoll();
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final typeKey = (decoded['mediaType'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      if (typeKey.isEmpty) return;
      if (typeKey != (widget.isPhoto ? 'PHOTO' : 'VIDEO')) return;
      final sessionCode = (decoded['sessionCode'] ?? '').toString().trim();
      final assetsRaw = decoded['assetCodes'];
      final assetCodes = (assetsRaw is List)
          ? assetsRaw
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];
      if (sessionCode.isEmpty || assetCodes.isEmpty) return;
      _startProcessingPoll(
        sessionCode: sessionCode,
        assetCodes: assetCodes,
        persist: false,
      );
    } catch (e) {
      AppLogger.d('resume pending upload poll failed: $e');
    }
  }

  Future<void> _savePendingProcessingPoll({
    required String sessionCode,
    required List<String> assetCodes,
  }) async {
    try {
      await _editor.savePendingUploadPoll(
        jsonEncode(<String, dynamic>{
          'mediaType': widget.isPhoto ? 'PHOTO' : 'VIDEO',
          'sessionCode': sessionCode,
          'assetCodes': assetCodes,
          'savedAt': AppTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      AppLogger.d('savePendingUploadPoll failed: $e');
    }
  }

  Future<void> _clearPendingProcessingPoll() async {
    try {
      await _editor.clearPendingUploadPoll();
    } catch (e) {
      AppLogger.d('clearPendingUploadPoll failed: $e');
    }
  }

  void _startProcessingPoll({
    required String sessionCode,
    required List<String> assetCodes,
    required bool persist,
  }) {
    final normalizedCodes = assetCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (sessionCode.trim().isEmpty || normalizedCodes.isEmpty) return;
    _mediaProcessingPollTimer?.cancel();
    _processingSessionCode = sessionCode.trim();
    _processingAssetCodes = normalizedCodes;
    if (mounted) {
      setState(() {
        _isMediaProcessing = true;
        _mediaProcessingStatusText = widget.isPhoto
            ? 'Photo processing in background...'
            : 'Video processing in background...';
      });
    }
    if (persist) {
      _savePendingProcessingPoll(
        sessionCode: _processingSessionCode!,
        assetCodes: _processingAssetCodes,
      );
    }
    _pollProcessingStatusOnce();
    _mediaProcessingPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollProcessingStatusOnce(),
    );
  }

  /// Deletes the staged copies of everything this screen uploaded, now that the
  /// server has confirmed them READY.
  ///
  /// Best-effort: anything missed here is caught by the orphan sweep on a later
  /// app start, so a failure has no user-visible consequence.
  Future<void> _discardStagedMediaForConfirmedUpload() async {
    final paths = _uploadedAssetCodeByPath.keys.toList(growable: false);
    if (paths.isEmpty) return;
    for (final path in paths) {
      try {
        await _editor.discardStagedMedia(path);
      } catch (_) {
        // discardStagedMedia never throws by contract; belt-and-braces so one
        // bad path cannot abort the rest of the cleanup.
      }
    }
  }

  Future<void> _pollProcessingStatusOnce() async {
    final sessionCode = _processingSessionCode;
    final assetCodes = _processingAssetCodes;
    if (sessionCode == null || sessionCode.isEmpty || assetCodes.isEmpty)
      return;
    try {
      final statuses = await _editor.getActivityUploadAssetStatuses(
        sessionCode: sessionCode,
        assetCodes: assetCodes,
      );
      if (statuses.isEmpty) return;
      var ready = 0;
      var failed = 0;
      for (final s in statuses.values) {
        final normalized = s.trim().toUpperCase();
        if (normalized == 'READY') ready++;
        if (normalized == 'FAILED') failed++;
      }
      if (!mounted) return;
      if (failed > 0) {
        _mediaProcessingPollTimer?.cancel();
        _processingSessionCode = null;
        _processingAssetCodes = const [];
        setState(() {
          _isMediaProcessing = false;
          _mediaProcessingStatusText = '';
        });
        await _clearPendingProcessingPoll();
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Media processing failed for one or more files.',
          isError: true,
        );
        return;
      }
      if (ready >= assetCodes.length) {
        _mediaProcessingPollTimer?.cancel();
        _processingSessionCode = null;
        _processingAssetCodes = const [];
        setState(() {
          _isMediaProcessing = false;
          _mediaProcessingStatusText = widget.isPhoto
              ? 'Photo ready'
              : 'Video ready';
        });
        await _clearPendingProcessingPoll();
        // THE server-confirmed point: every asset in this session reports
        // READY, so the bytes are safely server-side and the persistent copy
        // has done its job. This is the earliest moment it is safe to delete —
        // a PUT that returned 200 is not enough, because the asset can still
        // fail processing and need re-uploading from the local file.
        await _discardStagedMediaForConfirmedUpload();
        return;
      }
      setState(() {
        _isMediaProcessing = true;
        _mediaProcessingStatusText = widget.isPhoto
            ? 'Photo processing ($ready/${assetCodes.length} ready)'
            : 'Video processing ($ready/${assetCodes.length} ready)';
      });
    } catch (_) {
      // Keep polling silently; backend processing may be eventually consistent.
    }
  }

  Future<void> _submitCreate() async {
    if (_isSubmitting) return;
    if (_layoutAsEdit) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
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
      final isWithinAttendanceWindow =
          await validateStudentsWithinAttendanceWindow(
            context: context,
            editor: _editor,
            students: _selectedStudentsData,
            selectedDate: _activityDate,
            selectedTime: _activityTime,
          );
      if (!isWithinAttendanceWindow) return;

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
          _selectedStudentsData.first['classroomCode'] ??
          _selectedStudentsData.first['classroomcode'];
      final classroomCode = classroomCodeRaw is String
          ? classroomCodeRaw.trim()
          : '';
      if (classroomCode.isEmpty) return;
      final studentCodes = _selectedStudentsData
          .map((s) => (s['studentCode'] as String?)?.trim())
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toList();
      if (studentCodes.isEmpty) return;

      final staffCode = _staffCode ?? await _editor.resolveStaffCode();
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
      final staffPresentCode = ((_staffPresentCode ?? staffCode).trim());
      if (descriptionTrim.length > ActivityDescriptionLimits.maxLength) {
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
      final resolvedActivityTime = await _editor.resolveActivityDateTime(
        date: _activityDate!,
        time: _activityTime!,
      );
      final activityDateIso = resolvedActivityTime.iso;

      final details = await _editor.getActivityTypeDetails(
        code: activityTypeCode,
      );
      final localDate =
          '${_activityDate!.year.toString().padLeft(4, '0')}-${_activityDate!.month.toString().padLeft(2, '0')}-${_activityDate!.day.toString().padLeft(2, '0')}';
      final localTime = resolvedActivityTime.localTimeHms;

      final attachments = _uploadedAttachments.isNotEmpty
          ? _uploadedAttachments
          : await _uploadAndBuildAttachments(
              classroomCode: classroomCode,
              activityTypeCode: activityTypeCode,
              organizationCode: organizationCode,
              schoolCode: schoolCode,
              studentCodes: studentCodes,
            );
      final uploadAssetCodes = attachments
          .map((a) => a.assetCode.trim())
          .where((code) => code.isNotEmpty)
          .toList();
      final uploadPhotoCode = _findParameterCode(
        details.parameters,
        exactName: 'upload photo',
      );
      final createParameterValues = <ActivityParameterValue>[
        if (_findParameterCode(details.parameters, exactName: 'date') != null)
          ActivityParameterValue(
            parameterCode: _findParameterCode(
              details.parameters,
              exactName: 'date',
            )!,
            value: localDate,
          ),
        if (_findParameterCode(details.parameters, exactName: 'time') != null)
          ActivityParameterValue(
            parameterCode: _findParameterCode(
              details.parameters,
              exactName: 'time',
            )!,
            value: localTime,
          ),
        if (_findParameterCode(details.parameters, contains: 'staff') != null)
          ActivityParameterValue(
            parameterCode: _findParameterCode(
              details.parameters,
              contains: 'staff',
            )!,
            value: staffPresentCode,
          ),
        if (descriptionTrim.isNotEmpty &&
            _findParameterCode(details.parameters, exactName: 'description') !=
                null)
          ActivityParameterValue(
            parameterCode: _findParameterCode(
              details.parameters,
              exactName: 'description',
            )!,
            value: descriptionTrim,
          ),
        if (uploadPhotoCode != null && uploadAssetCodes.isNotEmpty)
          ActivityParameterValue(
            parameterCode: uploadPhotoCode,
            value: uploadAssetCodes.join(','),
          ),
      ];

      // Shared media flow (photos + videos): create one shared activity per attachment.
      await _editor.createSharedActivities(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: descriptionTrim,
        requireAdminApproval: _showRequireAdminApprovalToggle
            ? _requireAdminApproval
            : false,
        attachments: attachments,
        parameterValues: createParameterValues,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Shared activity created successfully',
        isSuccess: true,
      );
      CoreUtils.exitActivityFlow(context);
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
    _lastUpdateSucceeded = false;
    setState(() => _isSubmitting = true);
    try {
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
      final isWithinAttendanceWindow =
          await validateStudentsWithinAttendanceWindow(
            context: context,
            editor: _editor,
            students: _selectedStudentsData,
            selectedDate: _activityDate,
            selectedTime: _activityTime,
          );
      if (!isWithinAttendanceWindow) return;

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

      final classroomCodeRaw =
          _selectedStudentsData.first['classroomCode'] ??
          _selectedStudentsData.first['classroomcode'];
      final classroomCode = classroomCodeRaw is String
          ? classroomCodeRaw.trim()
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

      final staffCode = _staffCode ?? await _editor.resolveStaffCode();
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
      final resolvedActivityTime = await _editor.resolveActivityDateTime(
        date: _activityDate!,
        time: _activityTime!,
      );
      final activityDateIso = resolvedActivityTime.iso;
      final localTime = resolvedActivityTime.localTimeHms;
      final staffPresentCode = ((_staffPresentCode ?? staffCode).trim());

      final desc = _descriptionController.text.trim();
      if (desc.length > ActivityDescriptionLimits.maxLength) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: ActivityDescriptionLimits.maxLengthMessage,
          isWarning: true,
        );
        return;
      }

      List<ActivityAttachment> newUploads = const [];
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
        // Holdout: the PATCH/merge helper works on Map rows — convert the typed
        // outbound attachments back to the wire Map shape at this boundary.
        newUploadRows: newUploads.map((a) => a.toPayload()).toList(),
        remainingNormalizedDeliveryUrls: remainingNorm,
      );
      final patchAttachments = attachmentsForActivityPatchRequest(mergedRows);

      final details = await _editor.getActivityTypeDetails(
        code: activityTypeCode,
      );
      final dateCode = _findParameterCode(
        details.parameters,
        exactName: 'date',
      );
      final timeCode = _findParameterCode(
        details.parameters,
        exactName: 'time',
      );
      final staffCodeParam = _findParameterCode(
        details.parameters,
        contains: 'staff',
      );
      final descriptionCode = _findParameterCode(
        details.parameters,
        exactName: 'description',
      );
      final uploadMediaCode = _findParameterCode(
        details.parameters,
        exactName: widget.isPhoto ? 'upload photo' : 'upload video',
      );
      final uploadAssetCodes = patchAttachments
          .map((row) => (row['assetCode'] ?? '').toString().trim())
          .where((code) => code.isNotEmpty)
          .toList();
      final parameterValues = <ActivityParameterValue>[
        if (dateCode != null)
          ActivityParameterValue(parameterCode: dateCode, value: localDate),
        if (timeCode != null)
          ActivityParameterValue(parameterCode: timeCode, value: localTime),
        if (staffCodeParam != null)
          ActivityParameterValue(
            parameterCode: staffCodeParam,
            value: staffPresentCode,
          ),
        if (descriptionCode != null && desc.isNotEmpty)
          ActivityParameterValue(parameterCode: descriptionCode, value: desc),
        if (uploadMediaCode != null && uploadAssetCodes.isNotEmpty)
          ActivityParameterValue(
            parameterCode: uploadMediaCode,
            value: uploadAssetCodes.join(','),
          ),
      ];

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
          description: desc,
          parameterValues: parameterValues,
          attachments: patchAttachments,
        );
        try {
          await _editor.getActivity(code: code);
        } catch (e) {
          AppLogger.d('post-update cache-warm refetch failed: $e');
        }
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
    await _submitCreate();
  }

  @override
  void dispose() {
    _mediaProcessingPollTimer?.cancel();
    // Abort any in-flight media upload so a large video PUT doesn't keep
    // running (and burning bandwidth) after the user leaves this screen.
    if (!_uploadCancelToken.isCancelled) {
      _uploadCancelToken.cancel('activity screen disposed');
    }
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
        child: AbsorbPointer(
          absorbing:
              _isSubmitting ||
              _isApprovingOrRejecting ||
              _isUploadingMedia ||
              _loadingActivityDetail,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalSpacing,
            ),
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
                      final name = _selectedStudents[index];
                      return ActivityStudentDisplayTile(
                        name: name,
                        studentCode: index < _selectedStudentsData.length
                            ? _selectedStudentsData[index]['studentCode']
                                  as String?
                            : null,
                        onRemove: () => setState(() {
                          _selectedStudents.remove(name);
                          _selectedStudentsData.removeWhere(
                            (m) => (m['name'] as String?) == name,
                          );
                        }),
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
                Row(
                  children: [
                    Flexible(
                      child: _layoutAsEdit
                          ? DateWidget(
                              isEditable: false,
                              isRequired: true,
                              initialDate: _effectiveActivity.date,
                              onDateChanged: (d) {
                                setState(() => _activityDate = d);
                              },
                            )
                          : DateWidget(
                              key: ValueKey<String>(
                                formatSelectedDateForDateWidget(
                                      _activityDate,
                                    ) ??
                                    'school_date',
                              ),
                              isEditable: false,
                              isRequired: true,
                              initialDate: formatSelectedDateForDateWidget(
                                _activityDate,
                              ),
                              onDateChanged: (d) {
                                setState(() => _activityDate = d);
                              },
                            ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: TimeWidget(
                        isEditable: _layoutAsEdit ? _canInteract : true,
                        isRequired: true,
                        prefilledTime: _layoutAsEdit
                            ? _effectiveActivity.time
                            : null,
                        onTimeChanged: (t) {
                          setState(() => _activityTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.verticalSpacing),
                MediaUploader(
                  isRequired: true,
                  allowVideo: !widget.isPhoto,
                  allowPhoto: widget.isPhoto,
                  limit: widget.isPhoto ? 10 : 1,
                  readOnly: widget.readOnly,
                  autoReplaceFirstPhotoWhenMaxReached: _layoutAsEdit,
                  onMediaChanged: _layoutAsEdit && !_canInteract
                      ? null
                      : _onMediaChanged,
                  initialPhotoUrls: _layoutAsEdit
                      ? _existingPhotoUrls
                      : const [],
                  initialVideoUrl: _layoutAsEdit ? _existingVideoUrl : null,
                ),
                if (_isUploadingMedia) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${widget.isPhoto ? 'Uploading photo' : 'Uploading video'}... $_uploadProgressPercent% ($_uploadCompletedCount/$_uploadTotalCount)',
                    style: AppTextStyles.activityUploadProgressPlain,
                  ),
                ] else if (_isMediaProcessing) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.activityProcessingBg,
                      border: Border.all(
                        color: AppColors.activityProcessingBorder,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.activityProcessingAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _mediaProcessingStatusText.isNotEmpty
                                ? _mediaProcessingStatusText
                                : (widget.isPhoto
                                      ? 'Photo processing in background...'
                                      : 'Video processing in background...'),
                            style: AppTextStyles.activityMediaProcessingLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_uploadTotalCount > 0 &&
                    _uploadCompletedCount == _uploadTotalCount &&
                    _uploadProgressPercent == 100) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.activityUploadSuccessColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploaded $_uploadCompletedCount/$_uploadTotalCount',
                        style: AppTextStyles.activityUploadSuccessText,
                      ),
                    ],
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
                        _staffPresentCode =
                            (selectedCode ?? '').trim().isNotEmpty
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
              ],
            ),
          ),
        ),
      ),
      bottomBar: widget.readOnly
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActivityAdminApproveRejectBar(
                  visible: _showAdminApproveRejectActions,
                  isLoading:
                      _isApprovingOrRejecting ||
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
                    isLoading:
                        _isSubmitting ||
                        _isApprovingOrRejecting ||
                        _isUploadingMedia ||
                        _loadingActivityDetail,
                  ),
              ],
            ),
    );
  }
}
