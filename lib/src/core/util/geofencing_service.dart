// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geolocator_android/geolocator_android.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';
// import '../../features/authentication/domain/entities/user.dart';
// import '../../features/user/data/model/staffModel.dart';
// import '../../src/attendance/presentation/views/forms/staff_attendance_forms/staff_sign_in_form.dart';
// import '../../src/attendance/presentation/views/forms/staff_attendance_forms/staff_sign_out_form.dart';
// import '../../src/attendance/presentation/views/forms/student_attendance_forms/student_signIn_out_button.dart';
// import '../../src/auth/data/Models/user_model.dart';
// import '../../src/auth/presentation/views/auth_screen.dart';

// class LocationService extends ChangeNotifier {
//   static final LocationService _instance = LocationService._internal();
//   factory LocationService() => _instance;
//   LocationService._internal();

//   Position? _currentPosition;
//   bool _isLocationEnabled = false;
//   bool _isNotificationEnabled = false;
//   StreamSubscription<Position>? _positionStreamSubscription;
//   bool _isWithinGeofence = false;
//   bool _isInitialized = false;

//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Function(bool isNear)? onGeofenceStatusChanged;

//   double _targetLatitude = 0.0;
//   double _targetLongitude = 0.0;
//   static const double _geofenceRadiusMeters = 183;

//   static GlobalKey<NavigatorState>? _navigatorKey;
//   static void setNavigatorKey(GlobalKey<NavigatorState> key) {
//     _navigatorKey = key;
//   }

//   bool get isWithinGeofence => _isWithinGeofence;
//   Position? get currentPosition => _currentPosition;
//   bool get isLocationEnabled => _isLocationEnabled;
//   bool get isNotificationEnabled => _isNotificationEnabled;
//   bool get isInitialized => _isInitialized;

//   void setTargetLocation(double lat, double lng) {
//     if (lat == 0.0 ||
//         lng == 0.0 ||
//         lat < -90 ||
//         lat > 90 ||
//         lng < -180 ||
//         lng > 180) {
//       debugPrint(
//         'Invalid target location: Lat=$lat, Lng=$lng. Geofencing disabled.',
//       );
//       _isWithinGeofence = false;
//       notifyListeners();
//       return;
//     }
//     _targetLatitude = lat;
//     _targetLongitude = lng;
//     debugPrint('Target location updated: Lat=$lat, Lng=$lng');
//     if (_currentPosition != null) {
//       _checkGeofence(_currentPosition!);
//     }
//     if (_isLocationEnabled && _positionStreamSubscription == null) {
//       resumeTracking();
//     }
//   }

//   Future<bool> initialize() async {
//     if (_isInitialized) return true;

//     try {
//       if (Platform.isAndroid) {
//         GeolocatorAndroid.registerWith();
//       }

//       if (!await checkAndRequestPermissions()) {
//         debugPrint('Permissions not granted, initialization aborted');
//         return false;
//       }

//       await _initializeNotifications();
//       _isInitialized = true;
//       debugPrint(
//         'Location enabled: $_isLocationEnabled, Notifications enabled: $_isNotificationEnabled',
//       );
//       notifyListeners();

//       if (_isLocationEnabled) {
//         await _startLocationTracking();
//       }
//       return _isInitialized;
//     } catch (e) {
//       debugPrint('Error initializing location service: $e');
//       _isLocationEnabled = false;
//       _isNotificationEnabled = false;
//       _isInitialized = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<bool> checkAndRequestPermissions([BuildContext? context]) async {
//     try {
//       var locationStatus = await Permission.locationWhenInUse.status;
//       if (!locationStatus.isGranted && !locationStatus.isLimited) {
//         locationStatus = await Permission.locationWhenInUse.request();
//         if (!locationStatus.isGranted && !locationStatus.isLimited) {
//           debugPrint('Foreground location permission denied: $locationStatus');
//           if (context != null && context.mounted) {
//             await _showPermissionDialog(
//               context,
//               'Location Permission Required',
//               'This app needs location access to detect proximity to school. Please enable it in settings.',
//             );
//           }
//           _isLocationEnabled = false;
//           notifyListeners();
//           return false;
//         }
//       }

//       if (Platform.isAndroid) {
//         var bgStatus = await Permission.locationAlways.status;
//         if (!bgStatus.isGranted) {
//           bgStatus = await Permission.locationAlways.request();
//           if (!bgStatus.isGranted) {
//             debugPrint('Background location permission denied: $bgStatus');
//             if (context != null && context.mounted) {
//               await _showPermissionDialog(
//                 context,
//                 'Background Location Required',
//                 'This app needs background location access to track proximity to school. Please enable it in settings.',
//               );
//             }
//             _isLocationEnabled = false;
//             notifyListeners();
//             return false;
//           }
//         }

//         var batteryStatus = await Permission.ignoreBatteryOptimizations.status;
//         if (!batteryStatus.isGranted) {
//           await Permission.ignoreBatteryOptimizations.request();
//           debugPrint('Battery optimization exemption requested');
//         }
//       }

//       var notificationStatus = await Permission.notification.status;
//       if (!notificationStatus.isGranted && !notificationStatus.isLimited) {
//         notificationStatus = await Permission.notification.request();
//         _isNotificationEnabled =
//             notificationStatus.isGranted || notificationStatus.isLimited;
//         if (!_isNotificationEnabled && context != null && context.mounted) {
//           await _showPermissionDialog(
//             context,
//             'Notification Permission Required',
//             'This app needs notification access to alert you about school proximity. Please enable it in settings.',
//           );
//         }
//       } else {
//         _isNotificationEnabled = true;
//       }

//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled && context != null && context.mounted) {
//         await _showPermissionDialog(
//           context,
//           'Location Services Disabled',
//           'Please enable location services to use this feature.',
//         );
//         await Geolocator.openLocationSettings();
//         _isLocationEnabled = false;
//         notifyListeners();
//         return false;
//       }

//       _isLocationEnabled =
//           (locationStatus.isGranted || locationStatus.isLimited) &&
//           serviceEnabled;
//       notifyListeners();
//       return _isLocationEnabled;
//     } catch (e) {
//       debugPrint('Error checking permissions: $e');
//       _isLocationEnabled = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<void> requestLocationPermissionOnStartup(BuildContext context) async {
//     if (_isInitialized) return;
//     final permissionsGranted = await checkAndRequestPermissions(context);
//     if (permissionsGranted) {
//       await _startLocationTracking();
//     }
//   }

//   Future<void> _showPermissionDialog(
//     BuildContext context,
//     String title,
//     String message,
//   ) async {
//     if (context.mounted) {
//       await showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await openAppSettings();
//               },
//               child: const Text('Open Settings'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   // Future<void> _initializeNotifications() async {
//   //   const AndroidInitializationSettings initializationSettingsAndroid =
//   //       AndroidInitializationSettings('ic_notification');
//   //   const DarwinInitializationSettings initializationSettingsIOS =
//   //       DarwinInitializationSettings();
//   //   const InitializationSettings initializationSettings =
//   //       InitializationSettings(
//   //     android: initializationSettingsAndroid,
//   //     iOS: initializationSettingsIOS,
//   //   );
//   //   await _flutterLocalNotificationsPlugin.initialize(
//   //     initializationSettings,
//   //     onDidReceiveNotificationResponse: (NotificationResponse response) {
//   //       if (response.payload == 'school_geofence' &&
//   //           _navigatorKey?.currentState != null) {
//   //         _navigatorKey!.currentState!.pushNamed('/student_sign_in_out');
//   //       } else {
//   //         debugPrint('Navigator key unavailable or route not found');
//   //       }
//   //     },
//   //   );

//   //   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//   //     'school_proximity_channel',
//   //     'School Proximity Alerts',
//   //     description: 'Notifications for school geofence proximity',
//   //     importance: Importance.high,
//   //   );
//   //   await _flutterLocalNotificationsPlugin
//   //       .resolvePlatformSpecificImplementation<
//   //           AndroidFlutterLocalNotificationsPlugin>()
//   //       ?.createNotificationChannel(channel);
//   // }

//   Future<void> _initializeNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('ic_notification');
//     const DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings();
//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//           android: initializationSettingsAndroid,
//           iOS: initializationSettingsIOS,
//         );
//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         if (_navigatorKey?.currentState != null) {
//           final context = _navigatorKey!.currentState!.context;
//           try {
//             final authProvider = Provider.of<AuthProvider>(
//               context,
//               listen: false,
//             );
//             if (authProvider.getStaff() != StaffModel.empty) {
//               // Staff context
//               final route = authProvider.getStaff().isSignedIn
//                   ? StaffSignOutForm.routeName
//                   : StaffSignInForm.routeName;
//               _navigatorKey!.currentState!.pushNamed(route);
//             } else if (authProvider.getSecurityUser() !=
//                     SecurityUserModel.empty ||
//                 authProvider.getAccesseUser() != AccessUser.empty()) {
//               // Student/Guardian context
//               _navigatorKey!.currentState!.pushNamed(
//                 StudentSignInOutButton.routeName,
//               );
//             } else {
//               debugPrint('No user context available, navigating to AuthScreen');
//               _navigatorKey!.currentState!.pushNamed(AuthScreen.routName);
//             }
//           } catch (e) {
//             debugPrint('Error accessing AuthProvider or navigating: $e');
//             _navigatorKey!.currentState!.pushNamed(AuthScreen.routName);
//           }
//         } else {
//           debugPrint('Navigator key unavailable or route not found');
//         }
//       },
//     );

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'school_proximity_channel',
//       'School Proximity Alerts',
//       description: 'Notifications for school geofence proximity',
//       importance: Importance.high,
//     );
//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);
//   }

//   Future<void> _startLocationTracking() async {
//     try {
//       debugPrint('Starting location tracking...');
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         debugPrint('Location services disabled');
//         _isLocationEnabled = false;
//         notifyListeners();
//         return;
//       }

//       final permission = await Permission.locationWhenInUse.status;
//       if (!permission.isGranted && !permission.isLimited) {
//         debugPrint('Location permission not granted');
//         _isLocationEnabled = false;
//         notifyListeners();
//         return;
//       }

//       _currentPosition =
//           await Geolocator.getCurrentPosition(
//             locationSettings: const LocationSettings(
//               accuracy: LocationAccuracy.high,
//             ),
//           ).timeout(
//             const Duration(seconds: 30),
//             onTimeout: () {
//               throw Exception('Failed to get initial position: Timeout');
//             },
//           );

//       _isLocationEnabled = true;
//       if (_targetLatitude != 0.0 && _targetLongitude != 0.0) {
//         _checkGeofence(_currentPosition!);
//       }
//       notifyListeners();

//       await _positionStreamSubscription?.cancel();
//       _positionStreamSubscription =
//           Geolocator.getPositionStream(
//             locationSettings: const LocationSettings(
//               accuracy: LocationAccuracy.high,
//               distanceFilter: 10,
//             ),
//           ).listen(
//             (Position position) {
//               _currentPosition = position;
//               _isLocationEnabled = true;
//               if (_targetLatitude != 0.0 && _targetLongitude != 0.0) {
//                 _checkGeofence(position);
//               }
//               notifyListeners();
//             },
//             onError: (error) {
//               debugPrint('Position stream error: $error');
//               _isLocationEnabled = false;
//               _isWithinGeofence = false;
//               notifyListeners();
//             },
//           );
//     } catch (e) {
//       debugPrint('Error starting location tracking: $e');
//       _isLocationEnabled = false;
//       _isWithinGeofence = false;
//       notifyListeners();
//     }
//   }

//   /// Public method to manually update & check position
//   Future<void> updatePosition() async {
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       _currentPosition = position;
//       _isLocationEnabled = true;
//       if (_targetLatitude != 0.0 && _targetLongitude != 0.0) {
//         _checkGeofence(position);
//       }
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error updating position: $e');
//       _isLocationEnabled = false;
//       _isWithinGeofence = false;
//       notifyListeners();
//     }
//   }

//   /// Force check geofence immediately (e.g. after login)
//   Future<void> forceCheckGeofence(BuildContext? context) async {
//     if (_currentPosition == null) {
//       await updatePosition();
//     }
//     if (_currentPosition != null) {
//       _checkGeofence(_currentPosition!, triggerNotification: true);
//     }
//   }

//   void _checkGeofence(Position position, {bool triggerNotification = false}) {
//     if (_targetLatitude == 0.0 || _targetLongitude == 0.0) {
//       _isWithinGeofence = false;
//       notifyListeners();
//       return;
//     }

//     final distanceInMeters = Geolocator.distanceBetween(
//       position.latitude,
//       position.longitude,
//       _targetLatitude,
//       _targetLongitude,
//     );

//     final wasWithin = _isWithinGeofence;
//     _isWithinGeofence = distanceInMeters <= _geofenceRadiusMeters;

//     if (wasWithin != _isWithinGeofence) {
//       notifyListeners();
//       onGeofenceStatusChanged?.call(_isWithinGeofence);

//       if (_isWithinGeofence && _isNotificationEnabled) {
//         triggerGeofenceNotification();
//       }
//     } else if (_isWithinGeofence && triggerNotification) {
//       // Still inside geofence but forced check
//       triggerGeofenceNotification();
//     }
//   }

//   /// Send proximity notification
//   // void triggerGeofenceNotification() {
//   //   _flutterLocalNotificationsPlugin.show(
//   //     1,
//   //     'School Proximity Alert',
//   //     'You are within $_geofenceRadiusMeters meters of the school!',
//   //     const NotificationDetails(
//   //       android: AndroidNotificationDetails(
//   //         'school_proximity_channel',
//   //         'School Proximity Alerts',
//   //         channelDescription: 'Notifications for school geofence proximity',
//   //         importance: Importance.high,
//   //         priority: Priority.high,
//   //         icon: 'ic_notification',
//   //       ),
//   //       iOS: DarwinNotificationDetails(
//   //         presentAlert: true,
//   //         presentBadge: true,
//   //         presentSound: true,
//   //       ),
//   //     ),
//   //     payload: 'school_geofence',
//   //   );
//   // }
//   void triggerGeofenceNotification() {
//     final authProvider = AuthProvider(); // Access statically or via provider
//     String route;
//     if (authProvider.getStaff() != StaffModel.empty) {
//       route = authProvider.getStaff().isSignedIn
//           ? StaffSignOutForm.routeName
//           : StaffSignInForm.routeName;
//     } else {
//       route = StudentSignInOutButton.routeName;
//     }
//     _flutterLocalNotificationsPlugin.show(
//       1,
//       'School Proximity Alert',
//       'You are within $_geofenceRadiusMeters meters of the school!',
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'school_proximity_channel',
//           'School Proximity Alerts',
//           channelDescription: 'Notifications for school geofence proximity',
//           importance: Importance.high,
//           priority: Priority.high,
//           icon: 'ic_notification',
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       ),
//       payload: route,
//     );
//   }

//   Future<bool> checkLocationStatus() async {
//     try {
//       final permission = await Permission.locationWhenInUse.status;
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       _isLocationEnabled =
//           (permission.isGranted || permission.isLimited) && serviceEnabled;
//       if (_isLocationEnabled && _currentPosition != null) {
//         if (_targetLatitude != 0.0 && _targetLongitude != 0.0) {
//           _checkGeofence(_currentPosition!);
//         }
//       }
//       notifyListeners();
//       return _isLocationEnabled;
//     } catch (e) {
//       debugPrint('Error checking location status: $e');
//       _isLocationEnabled = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<void> openLocationSettings() async {
//     await Geolocator.openLocationSettings();
//     await checkLocationStatus();
//   }

//   void pauseTracking() {
//     _positionStreamSubscription?.cancel();
//     _positionStreamSubscription = null;
//     debugPrint('Location tracking paused');
//   }

//   Future<void> resumeTracking() async {
//     if (_isLocationEnabled && _positionStreamSubscription == null) {
//       await _startLocationTracking();
//     }
//   }

//   @override
//   void dispose() {
//     _positionStreamSubscription?.cancel();
//     _positionStreamSubscription = null;
//     debugPrint('LocationService disposed');
//     super.dispose();
//   }
// }
