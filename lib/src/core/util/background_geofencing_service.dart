// import 'dart:async';
// import 'dart:isolate';

// import 'package:background_locator_2/background_locator.dart';
// import 'package:background_locator_2/location_dto.dart';
// import 'package:background_locator_2/settings/android_settings.dart';
// import 'package:background_locator_2/settings/ios_settings.dart';
// import 'package:background_locator_2/settings/locator_settings.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:http/http.dart' as http;

// class BackgroundGeofencingService {
//   static const String _isolateName = 'background_locator_isolate';
//   static const String _backgroundLocationTaskKey = 'backgroundLocationTask';
//   static const double officeLat = 18.5588227;
//   static const double officeLong = 73.7984607;
//   static const double geofenceRadius = 50.0;

//   // Initialize background services
//   static Future<void> initializeBackgroundServices() async {
//     // Request location permissions
//     await _requestLocationPermission();

//     // Initialize Background Locator
//     await BackgroundLocator.initialize();

//     // Initialize Workmanager for additional background tasks
//     await Workmanager().initialize(
//       callbackDispatcher,
//       isInDebugMode: true,
//     );

//     // Register background location tracking
//     await BackgroundLocator.registerLocationUpdate(
//       LocationCallback.get(),
//       settings: LocatorSettings(
//         android: AndroidSettings(
//           notificationTitle: "Attendance Tracking",
//           notificationMsg: "Monitoring office location",
//           foregroundServiceNotificationId: 888,
//         ),
//         ios: IOSSettings(
//           accuracy: LocationAccuracy.best,
//           distanceFilter: 10,
//         ),
//         accurate: true,
//         distanceFilter: 10,
//       ),
//     );

//     // Schedule periodic location check
//     Workmanager().registerPeriodicTask(
//       _backgroundLocationTaskKey,
//       "checkGeofence",
//       frequency: const Duration(minutes: 15),
//     );
//   }

//   // Request location permission
//   static Future<bool> _requestLocationPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     return permission == LocationPermission.always || 
//            permission == LocationPermission.whileInUse;
//   }

//   // Background location callback
//   static void locationCallback(LocationDto locationDto) {
//     final SendPort? send = IsolatedUnitService.getServiceInstance;
//     if (send == null) return;

//     // Check if within geofence
//     final distance = Geolocator.distanceBetween(
//       locationDto.latitude,
//       locationDto.longitude,
//       officeLat,
//       officeLong,
//     );

//     if (distance > geofenceRadius) {
//       // Trigger punch-out API call
//       _performBackgroundPunchOut(locationDto);
//     }
//   }

//   // Perform background punch-out
//   static Future<void> _performBackgroundPunchOut(LocationDto locationDto) async {
//     try {
//       // Replace with your actual API endpoint and authentication method
//       final response = await http.post(
//         Uri.parse('https://your-api-endpoint.com/punch-out'),
//         body: {
//           'latitude': locationDto.latitude.toString(),
//           'longitude': locationDto.longitude.toString(),
//           'timestamp': DateTime.now().toIso8601String(),
//         },
//         headers: {
//           // Add necessary authentication headers
//           'Authorization': 'Bearer YOUR_TOKEN',
//         },
//       );

//       if (response.statusCode == 200) {
//         // Successfully punched out
//         debugPrint('Automatic punch-out performed');
//       }
//     } catch (e) {
//       debugPrint('Background punch-out error: $e');
//     }
//   }

//   // Workmanager callback dispatcher
//   static void callbackDispatcher() {
//     Workmanager().executeTask((taskName, inputData) async {
//       if (taskName == _backgroundLocationTaskKey) {
//         try {
//           // Perform geofence check
//           final position = await Geolocator.getCurrentPosition();
//           final distance = Geolocator.distanceBetween(
//             position.latitude,
//             position.longitude,
//             officeLat,
//             officeLong,
//           );

//           if (distance > geofenceRadius) {
//             // Trigger punch-out
//             await _performBackgroundPunchOut(
//               LocationDto(
//                 latitude: position.latitude,
//                 longitude: position.longitude,
//                 accuracy: position.accuracy,
//                 altitude: position.altitude,
//                 speed: position.speed,
//                 speedAccuracy: position.speedAccuracy,
//                 heading: position.heading,
//                 time: position.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
//               ),
//             );
//           }
//         } catch (e) {
//           debugPrint('Workmanager geofence check error: $e');
//         }
//       }
//       return Future.value(true);
//     });
//   }

//   // Stop background services
//   static Future<void> stopBackgroundServices() async {
//     await BackgroundLocator.unRegisterLocationUpdate();
//     Workmanager().cancelAll();
//   }
// }

// // Isolated unit service for communication
// class IsolatedUnitService {
//   static SendPort? _serviceInstance;

//   static set serviceInstance(SendPort? instance) {
//     _serviceInstance = instance;
//   }

//   static SendPort? get getServiceInstance => _serviceInstance;
// }