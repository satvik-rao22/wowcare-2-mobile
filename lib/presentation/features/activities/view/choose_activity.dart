import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/activities/cubit/choose_activity_cubit.dart';
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
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class ChooseActivity extends StatefulWidget {
  const ChooseActivity({super.key, required this.selectedStudents});

  final List<Map<String, dynamic>> selectedStudents;
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
  static final Map<String, Widget Function(List<Map<String, dynamic>>)>
  activityRoutes = {
    'Nap': (students) => NapActivityScreen(selectedStudents: students),
    'Bathroom': (students) =>
        BathroomActivityScreen(selectedStudents: students),
    'Bottle': (students) => BottleActivityScreen(selectedStudents: students),
    'Meal': (students) => MealActivityScreen(selectedStudents: students),
    'Incident': (students) =>
        IncidentActivityScreen(selectedStudents: students),
    'Photo': (students) =>
        PhotoVideoActivityScreen(selectedStudents: students, isPhoto: true),
    'Video': (students) =>
        PhotoVideoActivityScreen(selectedStudents: students, isPhoto: false),
    'Medication': (students) =>
        MedicationActivityScreen(selectedStudents: students),
    'Notes': (students) => NotesActivityScreen(selectedStudents: students),
    'Outdoor': (students) => OutdoorActivityScreen(selectedStudents: students),
    'Learning': (students) =>
        LearningActivityScreen(selectedStudents: students),
  };

  @override
  State<ChooseActivity> createState() => _ChooseActivityState();
}

class _ChooseActivityState extends State<ChooseActivity> {
  bool get _isMultipleStudentsSelected => widget.selectedStudents.length > 1;
  String? _selectedActivity;
  bool _isLoadingNext = false;

  String? get _classroomCode {
    if (widget.selectedStudents.isEmpty) return null;
    final first = widget.selectedStudents.first;
    final dynamic code = first['classroomCode'] ?? first['classroomcode'];
    if (code is String && code.trim().isNotEmpty) return code;
    return null;
  }

  bool _isActivityDisabled(String activityName, ChooseActivityState state) {
    final normalized = activityName.toLowerCase();

    // If we have classroom-specific enabled list, hide activities not enabled.
    if (state.enabledActivities != null &&
        !state.enabledActivities!.contains(normalized)) {
      return true;
    }

    // If multiple students are selected, enforce per-activity multi-student flag when available.
    if (_isMultipleStudentsSelected && state.multiStudentAllowed != null) {
      if (!state.multiStudentAllowed!.contains(normalized)) {
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
    if (state.enabledActivities == null &&
        activityName == 'Incident' &&
        _isMultipleStudentsSelected) {
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

  void _showDisabledActivityTooltip(
    BuildContext tileContext,
    String activityName,
  ) {
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
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
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

  /// Tapping an activity navigates directly to its create screen — there is no
  /// separate "Next" button. Guards against concurrent taps while the activity
  /// type details are being fetched.
  Future<void> _onActivitySelected(
    BuildContext context,
    ChooseActivityState state,
    String activityKey,
  ) async {
    if (_isLoadingNext) return;

    // Always hit: GET /api/v1/activity-types/{code}
    final selectedApiName =
        state.activityDisplayNameByKey[activityKey] ?? activityKey;
    final code = state.activityTypeCodeByName[selectedApiName.toLowerCase()];
    if (code == null || code.trim().isEmpty) {
      _showWarningMessage('Unable to resolve activity code.');
      return;
    }

    setState(() {
      _selectedActivity = activityKey;
      _isLoadingNext = true;
    });

    final error = await context
        .read<ChooseActivityCubit>()
        .fetchActivityTypeDetails(code);
    if (!mounted) return;
    setState(() {
      _isLoadingNext = false;
    });
    if (error != null) {
      _showWarningMessage(error);
      return;
    }

    final destinationBuilder = ChooseActivity.activityRoutes[activityKey];
    if (destinationBuilder != null && context.mounted) {
      final nextScreen = destinationBuilder(widget.selectedStudents);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => nextScreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChooseActivityCubit>(
      create: (_) => ChooseActivityCubit(
        settingsUseCase: serviceLocator<GetClassroomActivitySettingsUseCase>(),
        detailsUseCase: serviceLocator<GetActivityTypeDetailsUseCase>(),
        knownActivityKeys: ChooseActivity.activityIcons.keys,
      )..loadActivitySettings(classroomCode: _classroomCode),
      child: BlocConsumer<ChooseActivityCubit, ChooseActivityState>(
        listenWhen: (prev, curr) =>
            curr.loadErrorMessage != null &&
            prev.loadErrorMessage != curr.loadErrorMessage,
        listener: (context, state) {
          CoreUtils.logApiError(
            'Failed to load activity settings: ${state.loadErrorMessage}',
          );
          _showWarningMessage(state.loadErrorMessage!);
        },
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, ChooseActivityState state) {
    return StaffFormLayout(
      title: 'Choose Activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: PrimaryCircularLoader())
                : state.visibleActivityKeys.isEmpty
                ? const Center(
                    child: Text(
                      'No activities available from API.',
                      style: AppTextStyles.body,
                    ),
                  )
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    shrinkWrap: false,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 52,
                        ),
                    itemCount: state.visibleActivityKeys.length,
                    itemBuilder: (context, index) {
                      final String activityKey =
                          state.visibleActivityKeys[index];
                      final iconPath =
                          ChooseActivity.activityIcons[activityKey]!;
                      final String activityName =
                          state.activityDisplayNameByKey[activityKey] ??
                          activityKey;
                      final bool isDisabled = _isActivityDisabled(
                        activityName,
                        state,
                      );
                      final bool isSelected = _selectedActivity == activityKey;

                      return Builder(
                        builder: (tileContext) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: isDisabled
                                ? () => _showDisabledActivityTooltip(
                                    tileContext,
                                    activityName,
                                  )
                                : () => _onActivitySelected(
                                    context,
                                    state,
                                    activityKey,
                                  ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDisabled
                                      ? Colors.grey.withValues(alpha: 0.3)
                                      : AppColors.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isDisabled
                                    ? Colors.grey.withValues(alpha: 0.1)
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
                                      maxLines: activityName.contains(' ')
                                          ? 2
                                          : 1,
                                      style: AppTextStyles.body.copyWith(
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
      // Tapping an activity navigates directly — no Next/Cancel buttons.
      bottomBar: const SizedBox.shrink(),
    );
  }
}
