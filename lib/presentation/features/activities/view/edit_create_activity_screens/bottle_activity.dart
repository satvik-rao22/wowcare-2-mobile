import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/ounce_input_widget.dart';
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
import '../../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../shared/common/widgets/student_tile.dart';
import '../../utils/resolve_logged_in_staff_code.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class BottleActivityScreen extends StatefulWidget {
  const BottleActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;

  @override
  State<BottleActivityScreen> createState() => _BottleActivityScreenState();
}

class _BottleActivityScreenState extends State<BottleActivityScreen> {
  late final List<Map<String, dynamic>> _selectedStudentsData;
  late final List<String> _selectedStudents;
  List<String> _studentsToEdit = [];
  bool _selectAll = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final GlobalKey<OunceInputWidgetState> _ounceFiledKey = GlobalKey<OunceInputWidgetState>();
  //double? _ounceAmount;

  DateTime? _activityDate;
  TimeOfDay? _activityTime;
  String? _activityTypeCode;
  String _staffName = '';
  String? _staffCode;
  String? _schoolCode;
  String? _organizationCode;
  bool _isSubmitting = false;

  late final GetClassroomActivitySettingsUseCase _getActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final CreateActivityUseCase _createActivityUseCase;


  @override
  void initState() {
    super.initState();
    _getActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();
    _createActivityUseCase = serviceLocator<CreateActivityUseCase>();
    // Create a mutable copy of the incoming list
    //_selectedStudents = List.from(widget.selectedStudents);
    //_selectedStudents = widget.selectedStudents.map((studentMap) => studentMap['name'] as String).toList();
    if(widget.selectedStudents != null){
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData.map((student) => student['name'] as String).toList();
      _loadActivityContextForCreate();
    } else if (widget.isEdit){
      final activity = widget.activityData!;
      _selectedStudents = List<String>.from(activity.studentList);
      _descriptionController.text = activity.description ?? '';
      _amountController.text = activity.amountConsumed ?? '';
    }
    _loadStaffContext();
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
    _amountController.dispose();
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
      ActivitySetting? bottleSetting;
      for (final s in settings) {
        final name = s.activityTypeName.toLowerCase();
        if (name.contains('bottle')) {
          bottleSetting = s;
          break;
        }
      }
      if (bottleSetting != null && mounted) {
        setState(() {
          _activityTypeCode = bottleSetting!.activityTypeCode;
        });
      }
    } catch (e) {
      CoreUtils.logApiError('Failed to load activity settings for Bottle: $e');
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

    final ounceState = _ounceFiledKey.currentState;
    final amountOz = ounceState?.validValue;
    if (amountOz == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a valid amount (0.5 – 20.0 oz)',
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
            'Unable to determine activity type for Bottle. Please check activity settings.',
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
      final amountParamCode = findParamCode('amount') ??
          findParamCode('ounce') ??
          findParamCode('oz') ??
          findParamCode('consumed');

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
        if (amountParamCode != null && amountParamCode.trim().isNotEmpty)
          {'parameterCode': amountParamCode, 'value': amountOz.toString()},
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

  Future<void> _onSaveOrAddPressed() async {
    if (widget.isEdit) {
      if (_studentsToEdit.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select at least one student',
          isWarning: true,
        );
        return;
      }
      final ounceState = _ounceFiledKey.currentState;
      final amountOz = ounceState?.validValue;
      if (amountOz == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please enter a valid amount (0.5 – 20.0 oz)',
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
      Navigator.of(context).popUntil((route) {
        return route.settings.name == ActivityFeedScreen.routeName;
      });
      return;
    }

    await _submitCreateActivity();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: 'Bottle',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            // Select All
            if(widget.isEdit)
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
            if(widget.isEdit) const SizedBox(height: 12,),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsive.isTablet ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: responsive.isTablet ? 3.8 : widget.isEdit ? 4.2 : 3.0,
              ),
              itemCount: _selectedStudents.length,
              itemBuilder: (context, index) {
                final String name = _selectedStudents[index];
                final bool isSelected = _studentsToEdit.contains(name);

                return widget.isEdit ?
                StudentTile(
                  name: name,
                  isSelected: isSelected,
                  onSelected: (bool? selected){
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    setState(() {
                      if(selected == true){
                        _studentsToEdit.add(name);
                      } else {
                        _studentsToEdit.remove(name);
                      }
                      _updateSelectAllState();
                    });
                  },
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
                  child:
                  widget.isEdit ?
                  DateWidget(
                    isEditable: true,
                    isRequired: true,
                    initialDate: widget.activityData?.date,
                    onDateChanged: (d) => _activityDate = d,
                  )
                      :
                  DateWidget(
                    isEditable: true,
                    isRequired: true,
                    onDateChanged: (d) => _activityDate = d,
                  ),
                ),
                const SizedBox(width: 10,),
                Flexible(
                    child: widget.isEdit ?
                    TimeWidget(
                      isEditable: true,
                      isRequired: true,
                      prefilledTime: widget.activityData?.time,
                      onTimeChanged: (t) => _activityTime = t,
                    )
                        : TimeWidget(
                      isRequired: true,
                      isEditable: true,
                      onTimeChanged: (t) => _activityTime = t,
                    )
                ),
              ],
            ),
            SizedBox(height: responsive.verticalSpacing,),
            if(widget.isEdit)
              OunceInputWidget(
                key: _ounceFiledKey,
                label: 'Amount(OZ)',
                isRequired: true,
                min: 0.5,
                max: 20.0,
                controller: _amountController,
              )
            else
              OunceInputWidget(
                key: _ounceFiledKey,
                label: 'Amount(OZ)',
                isRequired: true,
                min: 0.5,
                max: 20.0,
              ),
            SizedBox(height: responsive.verticalSpacing,),
            StaffPresentWidget(
              staffName: widget.isEdit
                  ? (widget.activityData?.createdBy ?? '')
                  : _staffName,
              isEditable: false,
            ),
            SizedBox(height: responsive.verticalSpacing,),
            InputWidget(controller: _descriptionController, height: 100, hint: 'Enter Description'),
            SizedBox(height: responsive.verticalSpacing,),
          ],
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
            isLoading: _isSubmitting,
          ),
        ),
      ),
    );
  }
}
