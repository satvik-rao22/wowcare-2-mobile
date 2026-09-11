import 'dart:io';

import 'package:flutter/services.dart';

/// iOS only: reads the action stored by AppDelegate when the user tapped a
/// native geofence UNNotification from the killed/background state.
/// Returns e.g. {'action': 'GEOFENCE_ENTER'}, or null.
Future<Map<String, String>?> readIosGeofenceTap() async {
  if (!Platform.isIOS) return null;
  try {
    const ch = MethodChannel('wowcare/geofence_tap');
    final action = await ch.invokeMethod<String>('getPendingAction');
    if (action == null || action.isEmpty) return null;
    return {'action': action};
  } catch (_) {
    return null;
  }
}
