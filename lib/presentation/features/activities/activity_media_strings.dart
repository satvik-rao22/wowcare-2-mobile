/// User-visible copy for the activity media capture/pick flow.
///
/// Follows the established per-feature convention (`BillingStrings`,
/// `ReportsStrings`, `StudentStrings`) rather than adding to the cross-feature
/// [AppStrings], because nothing here is used outside the activity module.
///
/// Mandate 4: no user-visible string literal in a view file. Every message the
/// picker, staging or validation path can show resolves through here, so the
/// wording is reviewable in one place and translatable in one move.
///
/// **Not here:** log tags, breadcrumb vocabulary and platform error codes —
/// those are logic, not display copy.
class ActivityMediaStrings {
  const ActivityMediaStrings._();

  // ── Permission refusals ───────────────────────────────────────────────────
  // Distinguished from generic failures because the user can actually fix
  // these, and the sentence tells them where.

  static const String cameraPermissionDenied =
      'WowCare needs camera access to record a video. You can enable it in '
      'Settings.';

  static const String cameraPermissionRestricted =
      'Camera access is restricted on this device, so a video cannot be '
      'recorded here.';

  static const String photoPermissionDenied =
      'WowCare needs photo access to choose a video. You can enable it in '
      'Settings.';

  static const String photoPermissionRestricted =
      'Photo access is restricted on this device, so a video cannot be chosen '
      'here.';

  // ── Hardware / picker state ───────────────────────────────────────────────

  static const String noCameraAvailable =
      'This device does not have a camera available.';

  static const String pickerAlreadyOpen =
      'A photo or video is already being selected. Please finish that first.';

  // ── The capture itself failed ─────────────────────────────────────────────

  static const String cameraUnavailable =
      'Could not open the camera. Please try again.';

  static const String videoSourceUnavailable =
      'Could not open that video. Please try again.';

  static const String captureUnreadable =
      'That recording could not be read. Please record it again.';

  static const String videoUnreadable =
      'Could not read the selected video. Please try again.';

  // ── Storage ───────────────────────────────────────────────────────────────

  static const String storageFullPreparingVideo =
      'Not enough storage space to prepare this video. Free up some space and '
      'try again.';

  static const String couldNotPrepareVideo =
      'Could not prepare this video for upload. Please try again.';

  // ── Validation ────────────────────────────────────────────────────────────

  /// Zero bytes — the capture produced no data at all.
  static const String videoEmpty =
      'That video is empty. Please record or choose it again.';

  /// The decoder could not read the file, or it decoded to no duration. Both
  /// are the signature of a recording cut short before it was finished
  /// writing, so the wording tells the user what to do rather than naming a
  /// container atom.
  static const String videoCorrupt =
      'That video appears to be incomplete and cannot be uploaded. This can '
      'happen if a recording was interrupted — please record it again.';

  static const String unsupportedVideoFormat = 'Unsupported video format.';

  static const String unsupportedImageFormat = 'Unsupported image format.';

  static const String videoCodecUnsupported =
      'This video format is not supported on this device. Please use standard '
      'MP4 (H.264).';

  static const String videoTooLong = 'Video must be ≤30 seconds.';

  /// Interpolated with the measured size in MB.
  static String videoTooLarge(String sizeMb) => 'Video too large ($sizeMb MB).';

  /// Interpolated with the measured size and the configured cap.
  static String photoTooLarge(String sizeMb, int maxMb) =>
      'Photo too large ($sizeMb MB). Max: $maxMb MB';

  /// Interpolated with the configured maximum.
  static String maxPhotosAllowed(int max) => 'Maximum $max photos allowed.';

  static String maxPhotosSelectable(int max) =>
      'You can only select up to $max photos.';
}
