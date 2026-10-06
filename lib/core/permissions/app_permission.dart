import 'package:flutter/material.dart';

/// The runtime permissions the app knows how to ask for.
///
/// Only list a permission here once a feature actually needs it, because each
/// one also needs native setup that this file cannot do for you:
///
/// | Permission      | Android (AndroidManifest.xml) | iOS (Info.plist + ios/Podfile)                      |
/// |-----------------|-------------------------------|-----------------------------------------------------|
/// | [camera]        | CAMERA (merged in by the QR scanner plugin) | NSCameraUsageDescription + `PERMISSION_CAMERA=1` |
/// | [location]      | ACCESS_FINE/COARSE_LOCATION   | NSLocationWhenInUseUsageDescription (via Geolocator, no Podfile flag) |
/// | [notifications] | POST_NOTIFICATIONS            | `PERMISSION_NOTIFICATIONS=1`                        |
///
/// Skipping the native setup does not crash — it makes the OS report the
/// permission as denied forever, which sends users to Settings for a toggle
/// that does not exist. That is why this list is short on purpose.
///
/// Adding one: add the value here, then fix the compile errors — every
/// `switch` over [AppPermission] in this folder is exhaustive, so the compiler
/// lists each place (OS mapping, Settings steps) that needs a line.
enum AppPermission {
  camera(label: 'Camera', icon: Icons.photo_camera_outlined),

  /// Foreground ("While using the app") location only. Background location is
  /// deliberately not offered: App Review rejected it (guideline 2.5.4).
  location(label: 'Location', icon: Icons.location_on_outlined),

  notifications(label: 'Notifications', icon: Icons.notifications_outlined);

  const AppPermission({required this.label, required this.icon});

  /// The name the OS uses in Settings, so on-screen steps match what the user
  /// sees there.
  final String label;

  final IconData icon;
}

/// Where a permission stands, reduced to what a feature can act on.
enum AppPermissionStatus {
  /// Usable. Includes iOS "limited"/"provisional" grants.
  granted,

  /// Not granted yet; asking again will show the OS dialog.
  denied,

  /// The OS will not show its dialog again — only Settings can fix it.
  permanentlyDenied,

  /// Blocked by the device owner (iOS Screen Time, a company MDM policy). The
  /// user cannot change it, so do not send them to Settings.
  restricted;

  bool get isGranted => this == granted;
}
