import 'package:flutter/foundation.dart';

/// Lightweight global signal fired when a BACKGROUND profile-photo upload
/// finishes, so any open list screen can refresh and show the new photo —
/// the same refresh it does after an add. Scoped per entity type so a staff
/// upload doesn't needlessly refresh the student list and vice-versa.
///
/// List screens add a listener to the relevant ticker in `initState` and
/// remove it in `dispose`; the background upload helpers bump it on success.
class ProfilePhotoUploadEvents {
  ProfilePhotoUploadEvents._();

  static final ValueNotifier<int> studentTick = ValueNotifier<int>(0);
  static final ValueNotifier<int> staffTick = ValueNotifier<int>(0);
  static final ValueNotifier<int> guardianTick = ValueNotifier<int>(0);

  static void notifyStudentUploaded() => studentTick.value++;
  static void notifyStaffUploaded() => staffTick.value++;
  static void notifyGuardianUploaded() => guardianTick.value++;
}
