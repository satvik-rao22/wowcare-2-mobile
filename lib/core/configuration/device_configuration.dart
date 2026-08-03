import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// Initializes timezone data (used for school-timezone-aware date/time
/// calculations throughout the app).
void initializeTimeZoneData() {
  tzdata.initializeTimeZones();
}

/// Locks the app to the four cardinal orientations (portrait + landscape,
/// both directions).
void setPreferredOrientations() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}
