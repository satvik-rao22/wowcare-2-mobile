import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../../../../core/util/api_error_handler.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../shared/services/image_upload/image_upload_service.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../shared/common/widgets/student_tile.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../../widgets/upload_photo_video.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class NotesActivityScreen extends StatefulWidget {
  const NotesActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData,
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;

  @override
  State<NotesActivityScreen> createState() => _NotesActivityScreenState();
}

class _NotesActivityScreenState extends State<NotesActivityScreen> {
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
  List<File> _newPhotos = [];
  final Map<String, String> _uploadedAssetCodeByPath = {};
  String? _lastUploadContextKey;

  int get _uploadedPhotoCount => _newPhotos
      .where((f) => _uploadedAssetCodeByPath.containsKey(f.path))
      .length;

  late final GetClassroomActivitySettingsUseCase _getActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final CreateActivityUseCase _createActivityUseCase;
  late final ImageUploadService _imageUploadService;

  @override
  void initState() {
    super.initState();
    _getActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();
    _createActivityUseCase = serviceLocator<CreateActivityUseCase>();
    _imageUploadService = serviceLocator<ImageUploadService>();

    if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData
          .map((student) => student['name'] as String)
          .toList();
      _loadActivityContextForCreate();
    } else if (widget.isEdit) {
      final activity = widget.activityData!;
      _selectedStudents = List<String>.from(activity.studentList);
      _descriptionController.text = activity.whatHappened ?? '';
    }
    _loadStaffContext();
  }

  void _updateSelectAllState() {
    _selectAll =
        _selectedStudents.every((student) => _studentsToEdit.contains(student));
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
      ActivitySetting? notesSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('note')) {
          notesSetting = s;
          break;
        }
      }
      if (notesSetting != null && mounted) {
        setState(() {
          _activityTypeCode = notesSetting!.activityTypeCode;
        });
      }
    } catch (e) {
      CoreUtils.logApiError('Failed to load activity settings for Notes: $e');
    }
  }

  Future<void> _submitCreateActivity() async {
    if (_isSubmitting) return;

    if (widget.isEdit) {
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

    if (_activityDate == null || _activityTime == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select date and time',
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
            'Unable to determine activity type for Notes. Please check activity settings.',
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

      final dateParamCode = findParamCode('date');
      final timeParamCode = findParamCode('time');
      final staffParamCode = findParamCode('staff');
      final descParamCode = findParamCode('description');

      String two(int v) => v.toString().padLeft(2, '0');
      final localDate =
          '${_activityDate!.year}-${two(_activityDate!.month)}-${two(_activityDate!.day)}';
      final localTime =
          '${two(_activityTime!.hour)}:${two(_activityTime!.minute)}:00';

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
    } catch (error) {
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(error);
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
      // Prevent reusing asset codes uploaded under a different classroom/session context.
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
    _newPhotos = photos;
    _uploadedAssetCodeByPath.removeWhere(
      (path, _) => !_newPhotos.any((f) => f.path == path),
    );
    _uploadPhotosOnSelection();
  }

  Future<void> _uploadPhotosOnSelection() async {
    if (widget.isEdit || _newPhotos.isEmpty || _isUploadingMedia) return;

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
      final description = _descriptionController.text.trim();
      if (description.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please enter description',
          isWarning: true,
        );
        return;
      }
      Navigator.of(context).popUntil((route) {
        return route.settings.name == ActivityFeedScreen.routeName;
      });
      return;
    }

    _submitCreateActivity();
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
      title: 'Notes',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            if (widget.isEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: CustomCheckbox(
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
              ),
            if (widget.isEdit) const SizedBox(height: 12),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsive.isTablet ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: responsive.isTablet
                    ? 3.8
                    : widget.isEdit
                        ? 4.2
                        : 3.0,
              ),
              itemCount: _selectedStudents.length,
              itemBuilder: (context, index) {
                final String name = _selectedStudents[index];
                final bool isSelected = _studentsToEdit.contains(name);

                return widget.isEdit
                    ? StudentTile(
                        name: name,
                        isSelected: isSelected,
                        onSelected: (bool? selected) {
                          ScaffoldMessenger.of(context)
                              .removeCurrentSnackBar();
                          setState(() {
                            if (selected == true) {
                              _studentsToEdit.add(name);
                            } else {
                              _studentsToEdit.remove(name);
                            }
                            _updateSelectAllState();
                          });
                        },
                      )
                    : SelectedStudentTile(
                        name: name,
                        onTap: () => _removeStudent(name),
                      );
              },
            ),
            SizedBox(height: responsive.verticalSpacing),
            Row(
              children: [
                Flexible(
                  child: widget.isEdit
                      ? DateWidget(
                          isEditable: true,
                          isRequired: true,
                          initialDate: widget.activityData?.date,
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
                  child: widget.isEdit
                      ? TimeWidget(
                          isEditable: true,
                          isRequired: true,
                          prefilledTime: widget.activityData?.time,
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
              staffName: widget.isEdit
                  ? (widget.activityData?.createdBy ?? '')
                  : _staffName,
              isEditable: false,
            ),
            SizedBox(height: responsive.verticalSpacing),
            InputWidget(
              controller: _descriptionController,
              height: 100,
              hint: 'Enter Description',
              isRequired: true,
            ),
            SizedBox(height: responsive.verticalSpacing),
            if (widget.isEdit)
              MediaUploader(
                isRequired: false,
                allowVideo: false,
                allowPhoto: true,
                isPictureBox: false,
                limit: 10,
                label: 'Upload Photo',
                initialPhotoUrls: widget.activityData?.photoUrl != null &&
                        widget.activityData!.photoUrl!.trim().isNotEmpty
                    ? [widget.activityData!.photoUrl!.trim()]
                    : const [],
              )
            else
              MediaUploader(
                isRequired: false,
                allowVideo: false,
                allowPhoto: true,
                isPictureBox: false,
                limit: 10,
                label: 'Upload Photo',
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
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(
            responsive.isTablet ? 16.0 : 8.0,
          ),
        ),
        child: TextButton(
          onPressed: _isSubmitting ? null : _onSaveOrAddPressed,
          style: TextButton.styleFrom(overlayColor: Colors.transparent),
          child: Text(
            widget.isEdit ? 'Save' : 'Add',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
