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
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/student_tile.dart';
import '../../../../../shared/services/image_upload/image_upload_service.dart';
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
  });

  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final bool isPhoto;
  final ActivityItem? activityData;

  @override
  State<PhotoVideoActivityScreen> createState() => _PhotoVideoActivityScreenState();
}

class _PhotoVideoActivityScreenState extends State<PhotoVideoActivityScreen> {
  late final List<Map<String, dynamic>> _selectedStudentsData;
  late final List<String> _selectedStudents;
  List<String> _studentsToEdit = [];
  bool _selectAll = false;
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _activityDate;
  TimeOfDay? _activityTime;
  String? _activityTypeCode;
  String _staffName = '';
  String? _staffCode;
  String? _schoolCode;
  String? _organizationCode;
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;

  List<File> _photos = [];
  File? _video;
  List<String> _existingPhotoUrls = [];
  String? _existingVideoUrl;
  final Map<String, String> _uploadedAssetCodeByPath = {};
  List<Map<String, dynamic>> _uploadedAttachments = [];

  bool get _hasMedia =>
      _photos.isNotEmpty ||
      _video != null ||
      _existingPhotoUrls.isNotEmpty ||
      _existingVideoUrl != null;

  late final GetClassroomActivitySettingsUseCase _getSettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getDetailsUseCase;
  late final CreateActivityUseCase _createUseCase;
  late final ImageUploadService _uploadService;

  @override
  void initState() {
    super.initState();
    _getSettingsUseCase = serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getDetailsUseCase = serviceLocator<GetActivityTypeDetailsUseCase>();
    _createUseCase = serviceLocator<CreateActivityUseCase>();
    _uploadService = serviceLocator<ImageUploadService>();

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents =
          _selectedStudentsData.map((student) => student['name'] as String).toList();
      _loadActivityTypeCode();
    } else if (widget.isEdit) {
      final activity = widget.activityData!;
      _selectedStudents = List<String>.from(activity.studentList);
      _descriptionController.text = activity.description ?? '';
      if (widget.isPhoto && activity.photoUrl != null) {
        _existingPhotoUrls = [activity.photoUrl!];
      } else {
        _existingVideoUrl = activity.videoUrl;
      }
    }
    _loadStaffContext();
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
    setState(() {
      _photos = photos;
      _video = video;
      _existingPhotoUrls = remainingExistingPhotoUrls;
      _existingVideoUrl = remainingExistingVideoUrl;
      _uploadedAttachments = [];
    });
    _uploadMediaOnSelection();
  }

  Future<void> _uploadMediaOnSelection() async {
    if (widget.isEdit || _isUploadingMedia) return;
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
    final studentCodes = _selectedStudentsData
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
    final ownerCode = studentCodes.first;
    final uploadSession = await _uploadService.createActivityUploadSession(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      activityTypeCode: activityTypeCode,
      bindingMode: 'PER_STUDENT',
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
        ownerType: 'STUDENT',
        ownerCode: ownerCode,
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
    return uploadedCodes
        .map((code) => <String, dynamic>{
              'assetCode': code,
              'studentCode': ownerCode,
              'bindingMode': 'PER_STUDENT',
            })
        .toList();
  }

  Future<void> _submitCreate() async {
    if (_isSubmitting || widget.isEdit) return;
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

    setState(() {
      _isSubmitting = true;
    });
    try {
      final attachments = _uploadedAttachments.isNotEmpty
          ? _uploadedAttachments
          : await _uploadAndBuildAttachments(
              classroomCode: classroomCode,
              activityTypeCode: activityTypeCode,
              organizationCode: organizationCode,
              schoolCode: schoolCode,
              studentCodes: studentCodes,
            );

      final details = await _getDetailsUseCase(code: activityTypeCode);
      String? findCode(String contains) {
        for (final p in details.parameters) {
          if (p.parameterName.toLowerCase().contains(contains)) return p.code;
        }
        return null;
      }
      final parameterValues = <Map<String, dynamic>>[
        if (findCode('date') != null) {'parameterCode': findCode('date'), 'value': localDate},
        if (findCode('time') != null) {'parameterCode': findCode('time'), 'value': localTime},
        if (findCode('staff') != null) {'parameterCode': findCode('staff'), 'value': staffCode},
        if (findCode('description') != null)
          {'parameterCode': findCode('description'), 'value': _descriptionController.text.trim()},
      ];

      final message = await _createUseCase(
        activityTypeCode: activityTypeCode,
        classroomCode: classroomCode,
        studentCodes: studentCodes,
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        activityDate: activityDateIso,
        description: _descriptionController.text.trim(),
        parameterValues: parameterValues,
        attachments: attachments,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(context: context, message: message, isSuccess: true);
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

  void _onSaveOrAddPressed() {
    if (widget.isEdit) {
      if (_studentsToEdit.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select at least one student',
          isWarning: true,
        );
        return;
      }
      Navigator.of(context).popUntil((route) => route.settings.name == ActivityFeedScreen.routeName);
      return;
    }
    _submitCreate();
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
              if (widget.isEdit) ...[
                const SizedBox(height: 12),
                CustomCheckbox(
                  label: 'Select All',
                  value: _selectAll,
                  borderColor: AppColors.themeColor,
                  onChanged: (v) => setState(() {
                    _selectAll = v ?? false;
                    _studentsToEdit =
                        _selectAll ? List.from(_selectedStudents) : <String>[];
                  }),
                ),
              ],
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: responsive.isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: responsive.isTablet ? 3.8 : (widget.isEdit ? 4.2 : 3.0),
                ),
                itemCount: _selectedStudents.length,
                itemBuilder: (context, index) {
                  final name = _selectedStudents[index];
                  final selected = _studentsToEdit.contains(name);
                  if (widget.isEdit) {
                    return StudentTile(
                      name: name,
                      isSelected: selected,
                      onSelected: (value) => setState(() {
                        if (value == true) {
                          _studentsToEdit.add(name);
                        } else {
                          _studentsToEdit.remove(name);
                        }
                      }),
                    );
                  }
                  return SelectedStudentTile(
                    name: name,
                    onTap: () => setState(() => _selectedStudents.remove(name)),
                  );
                },
              ),
              Row(
                children: [
                  Flexible(
                    child: DateWidget(
                      isEditable: true,
                      isRequired: true,
                      initialDate: widget.isEdit ? widget.activityData?.date : null,
                      onDateChanged: (d) => _activityDate = d,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: TimeWidget(
                      isEditable: true,
                      isRequired: true,
                      prefilledTime: widget.isEdit ? widget.activityData?.time : null,
                      onTimeChanged: (t) => _activityTime = t,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.verticalSpacing),
              MediaUploader(
                isRequired: true,
                allowVideo: !widget.isPhoto,
                allowPhoto: widget.isPhoto,
                onMediaChanged: _onMediaChanged,
                initialPhotoUrls: widget.isEdit ? _existingPhotoUrls : const [],
                initialVideoUrl: widget.isEdit ? _existingVideoUrl : null,
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
                staffName: widget.isEdit ? widget.activityData?.createdBy ?? '' : _staffName,
                isEditable: false,
              ),
              SizedBox(height: responsive.verticalSpacing),
              InputWidget(
                controller: _descriptionController,
                height: 100,
                hint: 'Enter Description',
              ),
            ],
          ),
        ),
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CustomButtonLayout(
            confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
            onPressedConfirm: _onSaveOrAddPressed,
            showCancelButton: false,
            isForm: false,
            isLoading: _isSubmitting || _isUploadingMedia,
          ),
        ),
      ),
    );
  }
}
