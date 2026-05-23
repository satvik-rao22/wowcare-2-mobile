import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/nap_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';

class ChooseActivity extends StatefulWidget {
  const ChooseActivity({super.key, required this.selectedStudents});

  final List<Map<String, dynamic>> selectedStudents ;
  static final Map<String, String> activityIcons = {
    'Nap': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
  };
  // Map activity name to the destination widget/screen
  static final Map<String, Widget Function(List<Map<String, dynamic>>)> activityRoutes = {
    'Nap': (students) => NapActivityScreen(selectedStudents: students),
    'Bathroom': (students) => BathroomActivityScreen(selectedStudents: students),
    'Bottle': (students) => BottleActivityScreen(selectedStudents: students),
    'Meal': (students) => MealActivityScreen(selectedStudents: students),
    'Incident': (students) => IncidentActivityScreen(selectedStudents: students),
    'Photo': (students) => PhotoVideoActivityScreen(selectedStudents: students, isPhoto: true,),
    'Video': (students) => PhotoVideoActivityScreen(selectedStudents: students, isPhoto: false),
    'Medication': (students) => MedicationActivityScreen(selectedStudents: students),
    'Notes': (students) => NotesActivityScreen(selectedStudents: students),
    'Outdoor': (students) => OutdoorActivityScreen(selectedStudents: students),
    'Learning': (students) => LearningActivityScreen(selectedStudents: students),
  };

  @override
  State<ChooseActivity> createState() => _ChooseActivityState();
}

class _ChooseActivityState extends State<ChooseActivity> {
  late final GetClassroomActivitySettingsUseCase
      _getClassroomActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;

  bool get _isMultipleStudentsSelected => widget.selectedStudents.length > 1;
  String? _selectedActivity;
  bool _isLoadingNext = false;
  bool _isLoadingActivities = true;

  // Activity settings fetched from /api/v1/classrooms/{classroomCode}/activity-settings
  Set<String>? _enabledActivities; // normalized (lowercase) names
  Set<String>? _multiStudentAllowed; // normalized (lowercase) names
  final Map<String, String> _activityTypeCodeByName = {}; // normalized name -> code
  final Map<String, String> _activityDisplayNameByKey = {}; // known key -> API name
  List<String> _visibleActivityKeys = [];

  String? _getKnownActivityKeyByNormalized(String normalizedName) {
    for (final key in ChooseActivity.activityIcons.keys) {
      if (key.toLowerCase() == normalizedName) {
        return key;
      }
    }
    return null;
  }

  String? get _classroomCode {
    if (widget.selectedStudents.isEmpty) return null;
    final first = widget.selectedStudents.first;
    final dynamic code = first['classroomCode'] ?? first['classroomcode'];
    if (code is String && code.trim().isNotEmpty) return code;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _getClassroomActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivitySettingsForClassroom();
    });
  }

  Future<void> _loadActivitySettingsForClassroom() async {
    final classroomCode = _classroomCode;
    if (classroomCode == null || classroomCode.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingActivities = false;
        _visibleActivityKeys = [];
      });
      return;
    }

    try {
      final List<ActivitySetting> settings =
          await _getClassroomActivitySettingsUseCase(
        classroomCode: classroomCode,
        refresh: true,
      );

      final enabled = <String>{};
      final multiAllowed = <String>{};
      final visibleKeys = <String>[];
      final seenKeys = <String>{};

      for (final setting in settings) {
        final name = setting.activityTypeName.trim();
        if (name.isEmpty) continue;

        final normalized = name.toLowerCase();
        _activityTypeCodeByName[normalized] = setting.activityTypeCode;
        final knownKey = _getKnownActivityKeyByNormalized(normalized);
        if (knownKey != null) {
          _activityDisplayNameByKey[knownKey] = name;
        }

        if (setting.isEnabled && knownKey != null) {
          enabled.add(normalized);
          if (!seenKeys.contains(knownKey)) {
            seenKeys.add(knownKey);
            visibleKeys.add(knownKey);
          }
        }
        if (setting.isMultiStudent) {
          multiAllowed.add(normalized);
        }
      }

      if (!mounted) return;

      setState(() {
        _enabledActivities = enabled.isEmpty ? null : enabled;
        _multiStudentAllowed = multiAllowed.isEmpty ? null : multiAllowed;
        _visibleActivityKeys = visibleKeys;
        _isLoadingActivities = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.logApiError('Failed to load activity settings: $message');
      // Keep UI usable with default behaviour even if settings fail,
      // but surface backend message to the user.
      _showWarningMessage(message);
      setState(() {
        _isLoadingActivities = false;
        _visibleActivityKeys = [];
      });
    }
  }

  bool _isActivityDisabled(String activityName) {
    final normalized = activityName.toLowerCase();

    // If we have classroom-specific enabled list, hide activities not enabled.
    if (_enabledActivities != null &&
        !_enabledActivities!.contains(normalized)) {
      return true;
    }

    // If multiple students are selected, enforce per-activity multi-student flag when available.
    if (_isMultipleStudentsSelected && _multiStudentAllowed != null) {
      if (!_multiStudentAllowed!.contains(normalized)) {
        return true;
      }
    }

    // Nap should be disabled only for a mixed multi-selection where
    // some students are already napping and some are not.
    if (_isMultipleStudentsSelected &&
        normalized == 'nap' &&
        _hasMixedNappingSelection()) {
      return true;
    }

    // Fallback rule for Incident if settings are not yet loaded.
    if (_enabledActivities == null && activityName == 'Incident' && _isMultipleStudentsSelected) {
      return true;
    }

    return false;
  }

  String _getDisabledActivityTooltip(String activityName) {
    final normalized = activityName.toLowerCase();
    if (_isMultipleStudentsSelected &&
        normalized == 'nap' &&
        _hasMixedNappingSelection()) {
      return 'Nap is disabled for mixed selection. Select either all currently napping students or all not-napping students.';
    }
    if (activityName == 'Incident' && _isMultipleStudentsSelected) {
      return 'Incident can only be recorded for a single student.';
    }
    return 'This activity is currently disabled';
  }

  bool _isStudentCurrentlyNapping(Map<String, dynamic> student) {
    final dynamic status = student['nappingStatus'] ?? student['isNapping'];
    if (status == true) return true;
    if (status is String && status.toLowerCase() == 'true') return true;
    return false;
  }

  bool _hasMixedNappingSelection() {
    if (widget.selectedStudents.isEmpty) return false;
    final hasNapping = widget.selectedStudents.any(_isStudentCurrentlyNapping);
    final hasNotNapping = widget.selectedStudents.any(
      (student) => !_isStudentCurrentlyNapping(student),
    );
    return hasNapping && hasNotNapping;
  }

  void _showDisabledActivityTooltip(BuildContext tileContext, String activityName) {
    final RenderBox renderBox = tileContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final maxWidth = (screenWidth - 16).clamp(160.0, 320.0);
    final left = position.dx.clamp(8.0, screenWidth - maxWidth - 8.0);

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy - 60,
        left: left,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                _getDisabledActivityTooltip(activityName),
                softWrap: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isWarning: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return StaffFormLayout(
      title: 'Choose Activity',
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Expanded(
            child: _isLoadingActivities
                ? const Center(child: PrimaryCircularLoader())
                : _visibleActivityKeys.isEmpty
                    ? const Center(
                        child: Text(
                          'No activities available from API.',
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                    : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 52,
                      ),
              itemCount: _visibleActivityKeys.length,
                      itemBuilder: (context, index) {
                final String activityKey = _visibleActivityKeys[index];
                final iconPath = ChooseActivity.activityIcons[activityKey]!;
                final String activityName =
                    _activityDisplayNameByKey[activityKey] ?? activityKey;
                final bool isDisabled = _isActivityDisabled(activityName);
                final bool isSelected = _selectedActivity == activityKey;

                return Builder(
                  builder: (tileContext) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: isDisabled
                          ? () => _showDisabledActivityTooltip(tileContext, activityName)
                          : () {
                              setState(() {
                                _selectedActivity = activityKey;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDisabled
                                ? Colors.grey.withOpacity(0.3)
                                : AppColors.primaryColor.withOpacity(0.1),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isDisabled
                              ? Colors.grey.withOpacity(0.1)
                              : isSelected
                                  ? const Color.fromARGB(255, 249, 245, 250)
                                  : Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Image.asset(
                                iconPath,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activityName,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: activityName.contains(' ') ? 2 : 1,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDisabled
                                      ? Colors.grey
                                      : AppColors.primaryColor,
                                ),
              ),
            ),
          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          cancelButtonLabel: 'Cancel',
          onPressedCancel: () => Navigator.of(context).pop(),
          onPressedConfirm: _isLoadingNext
              ? null
              : () async {
            if (_selectedActivity == null) {
              _showWarningMessage('Select an activity.');
              return;
            }

            // Always hit: GET /api/v1/activity-types/{code}
            final selectedApiName =
                _activityDisplayNameByKey[_selectedActivity!] ?? _selectedActivity!;
            final code = _activityTypeCodeByName[selectedApiName.toLowerCase()];
            if (code == null || code.trim().isEmpty) {
              _showWarningMessage('Unable to resolve activity code.');
              return;
            }

            setState(() {
              _isLoadingNext = true;
            });

            try {
              await _getActivityTypeDetailsUseCase(code: code);
              // NOTE: We fetch details (including parameters) here so the next
              // screen can use cached/stateful details later. Upload-session /
              // presign / S3 PUT / session GET happen on activity screens (e.g. Notes)
              // when the user adds media.
            } catch (e) {
              _showWarningMessage(e.toString());
              return;
            } finally {
              if (mounted) {
                setState(() {
                  _isLoadingNext = false;
                });
              }
            }

            final destinationBuilder =
                ChooseActivity.activityRoutes[_selectedActivity!];
            if (destinationBuilder != null) {
              final nextScreen = destinationBuilder(widget.selectedStudents);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => nextScreen),
              );
            }
          },
        ),
      ),
    );
  }
}
