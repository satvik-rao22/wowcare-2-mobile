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
import '../../../../../core/util/core_utils.dart';
import '../../../../../core/util/storage_keys.dart';
import '../../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../shared/common/widgets/student_tile.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class MedicationActivityScreen extends StatefulWidget {
  const MedicationActivityScreen({
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
  State<MedicationActivityScreen> createState() => _MedicationActivityScreenState();
}

class _MedicationActivityScreenState extends State<MedicationActivityScreen> {
  bool get _layoutAsEdit => widget.isEdit || widget.readOnly;
  bool get _canInteract => !widget.readOnly;

  List<Map<String, dynamic>> _selectedStudentsData = [];
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
  bool _loadingActivityDetail = false;
  ActivityItem? _liveActivity;

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

    if(widget.selectedStudents != null){
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData.map((student) => student['name'] as String).toList();
      _loadActivityContextForCreate();
    } else if (_layoutAsEdit) {
      final activity = widget.activityData!;
      _liveActivity = activity;
      _selectedStudents = List<String>.from(activity.studentList);
      _selectedStudentsData = studentDataMapsForActivityEdit(activity);
      _descriptionController.text = activity.description ?? '';
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
        _descriptionController.text = item.description ?? '';
        _activityTypeCode = item.activityTypeCode;
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

  void _updateSelectAllState() {
    _selectAll = _selectedStudents.every((student) => _studentsToEdit.contains(student));

  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);

      // If no students left, go back to previous screen
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
      ActivitySetting? medicationSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('medication')) {
          medicationSetting = s;
          break;
        }
      }
      if (medicationSetting != null && mounted) {
        setState(() {
          _activityTypeCode = medicationSetting!.activityTypeCode;
        });
      }
    } catch (e) {
      CoreUtils.logApiError('Failed to load activity settings for Medication: $e');
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
        message: 'Missing staff or school information. Please re-login and try again.',
        isError: true,
      );
      return;
    }

    final activityTypeCode = _activityTypeCode;
    if (activityTypeCode == null || activityTypeCode.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to determine activity type for Medication. Please check activity settings.',
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
      // Build parameterValues in backend-required shape:
      // [{ "parameterCode": "...", "value": ... }, ...]
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
            'Unable to determine activity type for Medication. Please check activity settings.',
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

      final message = await _updateActivityUseCase(
        code: activityCode,
        staffCode: staffCode,
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
      if (mounted) setState(() => _isSubmitting = false);
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
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: 'Medication',
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            // Select All
            if (_layoutAsEdit && _canInteract) ...[
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
              const SizedBox(height: 12,),
            ],
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
                            ? (bool? selected) {
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
                              }
                            : null,
                      )
                    : SelectedStudentTile(
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
                const SizedBox(width: 10,),
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
            StaffPresentWidget(
              staffName: _layoutAsEdit
                  ? _effectiveActivity.createdBy
                  : _staffName,
              isEditable: _canInteract,
            ),
            SizedBox(height: responsive.verticalSpacing,),
            InputWidget(
              controller: _descriptionController,
              height: 100,
              hint: 'Enter Description',
              isRequired: true,
              readOnly: !_canInteract,
            ),
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
                  isLoading: _isSubmitting || _loadingActivityDetail,
                ),
              ),
            ),
    );
  }
}
