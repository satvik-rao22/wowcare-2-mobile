import 'dart:io';

import 'package:wowcare/presentation/features/activities/model/activity_item.dart';

/// Typed route argument payloads for the activity GoRouter routes.
///
/// Each route reads its arguments from `state.extra` cast to the matching
/// class below — the `extra` object is passed through untouched (never
/// serialized), so it can safely carry non-primitive values like a local
/// [File] or an [ActivityItem].

/// [ActivityFilterScreen]
class ActivityFilterArgs {
  const ActivityFilterArgs({
    required this.schoolCode,
    required this.classroomCode,
    this.initialFilters,
  });

  final String schoolCode;
  final String classroomCode;
  final Map<String, List<String>>? initialFilters;
}

/// [ShowFullScreenMedia]
class ShowFullScreenMediaArgs {
  const ShowFullScreenMediaArgs({this.activity, this.photoUrl, this.videoUrl});

  final ActivityItem? activity;
  final String? photoUrl;
  final String? videoUrl;
}

/// [FullscreenLocalVideoPlayerPage]
class FullscreenLocalVideoArgs {
  const FullscreenLocalVideoArgs({required this.videoFile});

  final File videoFile;
}

/// [ChooseActivity]
class ChooseActivityArgs {
  const ChooseActivityArgs({required this.selectedStudents});

  final List<Map<String, dynamic>> selectedStudents;
}

/// Classroom code for the activity-settings fetch that kicks off
/// [ChooseActivity] — the first selected student's classroom, same as the
/// View's own logic used before the cubit's creation moved to the router.
String? classroomCodeFromSelectedStudents(
  List<Map<String, dynamic>> selectedStudents,
) {
  if (selectedStudents.isEmpty) return null;
  final dynamic code =
      selectedStudents.first['classroomCode'] ??
      selectedStudents.first['classroomcode'];
  if (code is String && code.trim().isNotEmpty) return code;
  return null;
}

/// Shared args for the nine activity create/edit/read-only screens whose
/// constructor is `{selectedStudents, isEdit, activityData, readOnly}`:
/// [NapActivityScreen], [BathroomActivityScreen], [BottleActivityScreen],
/// [MealActivityScreen], [IncidentActivityScreen], [MedicationActivityScreen],
/// [NotesActivityScreen], [OutdoorActivityScreen], [LearningActivityScreen].
class ActivityTypeScreenArgs {
  const ActivityTypeScreenArgs({
    this.selectedStudents,
    this.isEdit = false,
    this.activityData,
    this.readOnly = false,
  });

  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;
  final bool readOnly;
}

/// [PhotoVideoActivityScreen] — same shape as [ActivityTypeScreenArgs] plus
/// the required `isPhoto` flag distinguishing the photo vs. video variant.
class PhotoVideoActivityScreenArgs {
  const PhotoVideoActivityScreenArgs({
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
}
