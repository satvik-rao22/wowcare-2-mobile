/// Normalized location permission level, independent of platform-specific
/// status enums (built from `PermissionManager` in core/utils).
///
/// iOS does not expose "Allow Once" as a distinct authorization status from
/// "Allow While Using the App" — both report as `.authorizedWhenInUse`, so
/// both map to [whileInUse] here.
enum LocationPermissionLevel {
  /// Permission not granted; the OS prompt can still be shown again.
  denied,

  /// Permission permanently denied — the OS will not show the prompt again;
  /// the user must enable it from system Settings.
  permanentlyDenied,

  /// Foreground-only ("While Using the App" on Android, "Allow Once" or
  /// "Allow While Using App" on iOS).
  whileInUse,

  /// Foreground + background ("Allow All the Time" on Android, "Always
  /// Allow" on iOS).
  always,
}
