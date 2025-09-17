// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:intl/intl.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';

// final FirebaseFirestore firestore = FirebaseFirestore.instance;

// class MyChildsDayCard extends StatefulWidget {
//   const MyChildsDayCard({
//     required this.studentId,
//     required this.guardianStudents,
//     this.onClose,
//     super.key,
//   });

//   final int studentId;
//   final List<StudentModel> guardianStudents;
//   final VoidCallback? onClose;

//   @override
//   State<MyChildsDayCard> createState() => MyChildsDayCardState();
// }

// class MyChildsDayCardState extends State<MyChildsDayCard> {
//   Timer? _timer;
//   late Duration _duration;
//   String _statusText = 'School starts in';
//   late bool isLocationEnabled;
//   late bool isWithinGeofence;
//   List<StudentEntity> _cachedStudents = [];
//   StudentEntity studenttoShow = StudentEntity.empty;
//   bool _isMinimized = false;
//   bool _hasShownPopup = false;
//   final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
//   bool _isNavigating = false;
//   String? _precomputedRoute;
//   String _currentLocationName = 'Fetching location...';
//   StreamSubscription<Position>? _positionStreamSubscription;
//   Timer? _debounceTimer;

//   @override
//   void initState() {
//     super.initState();
//     _duration = const Duration(hours: 0);
//     _statusText = 'Loading schedule...';

//     final locationService = LocationService();
//     isLocationEnabled = locationService.isLocationEnabled;
//     isWithinGeofence = locationService.isWithinGeofence;
//     debugPrint('Initial isLocationEnabled: $isLocationEnabled');
//     debugPrint('Initial isWithinGeofence: $isWithinGeofence');

//     locationService.onGeofenceStatusChanged = (isNear) {
//       debugPrint('Geofence status changed: isNear=$isNear');
//       if (mounted) {
//         setState(() {
//           isWithinGeofence = isNear;
//         });
//         _updateLocationName();
//         if (isNear && !_hasShownPopup && !studenttoShow.isSignedIn) {
//           _showGeofencePopup();
//           _hasShownPopup = true;
//         } else if (!isNear) {
//           _hasShownPopup = false;
//         }
//       }
//     };

//     _startLocationUpdates();
//     locationService.addListener(_updateLocationStatus);
//     _initializeData().then((_) {
//       if (mounted &&
//           isLocationEnabled &&
//           isWithinGeofence &&
//           !studenttoShow.isSignedIn &&
//           !_hasShownPopup) {
//         _showGeofencePopup();
//         _hasShownPopup = true;
//       }
//     });
//     _updateLocationName();
//   }

//   void _startLocationUpdates() {
//     final locationService = LocationService();
//     if (locationService.isLocationEnabled) {
//       _positionStreamSubscription = Geolocator.getPositionStream(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           distanceFilter: 10,
//         ),
//       ).listen((Position position) {
//         if (_debounceTimer?.isActive ?? false) return;
//         _debounceTimer = Timer(const Duration(milliseconds: 500), () {
//           debugPrint(
//               'Location updated: Lat=${position.latitude}, Lon=${position.longitude}');
//           final wasWithinGeofence = isWithinGeofence;
//           isWithinGeofence = locationService.isWithinGeofence;
//           if (mounted) {
//             setState(() {
//               isWithinGeofence = locationService.isWithinGeofence;
//             });
//             if (isWithinGeofence &&
//                 !wasWithinGeofence &&
//                 !studenttoShow.isSignedIn &&
//                 !_hasShownPopup) {
//               _showGeofencePopup();
//               _hasShownPopup = true;
//             } else if (!isWithinGeofence) {
//               _hasShownPopup = false;
//             }
//             _updateLocationName();
//           }
//         });
//       }, onError: (e) {
//         debugPrint('Location stream error: $e');
//         if (mounted) {
//           setState(() {
//             isLocationEnabled = false;
//             _currentLocationName = 'Location unavailable';
//           });
//         }
//       });
//     }
//   }

//   Future<void> _updateLocationName() async {
//     final locationService = LocationService();
//     final position = locationService.currentPosition;
//     if (position != null) {
//       try {
//         final placemarks = await placemarkFromCoordinates(
//           position.latitude,
//           position.longitude,
//         );
//         if (placemarks.isNotEmpty && mounted) {
//           final placemark = placemarks.first;
//           final address = [
//             placemark.street,
//             placemark.locality,
//             placemark.administrativeArea,
//             placemark.country
//           ].where((e) => e != null && e.isNotEmpty).join(', ');
//           setState(() {
//             _currentLocationName =
//                 address.isNotEmpty ? address : 'Unknown location';
//           });
//         } else {
//           setState(() {
//             _currentLocationName = 'Unknown location';
//           });
//         }
//       } catch (e) {
//         debugPrint('Error fetching location name: $e');
//         if (mounted) {
//           setState(() {
//             _currentLocationName = 'Error fetching location';
//           });
//         }
//       }
//     } else {
//       setState(() {
//         _currentLocationName = 'Location unavailable';
//       });
//     }
//   }

//   void _showGeofencePopup() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         title: const Text(
//           'School Proximity Alert',
//           style: TextStyle(
//             color: AppColors.primaryColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'You are near ${studenttoShow.fullName}\'s school!',
//               style: const TextStyle(
//                 color: AppColors.primaryColor,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Would you like to sign ${studenttoShow.fullName} in or out?',
//               style: TextStyle(
//                 color: AppColors.primaryColor.withValues(alpha: 0.7),
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primaryColor,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () async {
//               Navigator.pop(context);
//               await _handleSignInOut();
//             },
//             child: const Text('Sign In/Out'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _precomputeNavigationRoute() {
//     if (_cachedStudents.isEmpty) {
//       _precomputedRoute = null;
//       return;
//     }
//     final allSignedIn = _cachedStudents.every((student) => student.isSignedIn);
//     final allSignedOut =
//         _cachedStudents.every((student) => !student.isSignedIn);
//     setState(() {
//       _precomputedRoute = allSignedIn
//           ? StudentSignOutForm.routeName
//           : allSignedOut
//               ? StudentSignInForm.routeName
//               : StudentSignInOutButton.routeName;
//     });
//   }

//   Future<void> _handleSignInOut() async {
//     if (AuthProvider.targetLatitude == 0.0 ||
//         AuthProvider.targetLongitude == 0.0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('School location not set. Please try again later.')),
//       );
//       return;
//     }

//     if (_isNavigating) return;
//     _isNavigating = true;
//     _isLoadingNotifier.value = true;

//     try {
//       if (_cachedStudents.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('No students available')),
//           );
//         }
//         return;
//       }

//       if (LocationService().isWithinGeofence) {
//         debugPrint('Navigating to $_precomputedRoute');
//         final result = await Navigator.of(context).pushNamed(
//           _precomputedRoute ?? StudentSignInOutButton.routeName,
//           arguments: _cachedStudents,
//         );

//         if (result == true && mounted) {
//           debugPrint('Form returned success, refreshing data');
//           await _refreshStudentCache();
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text('You are not within the geofencing range.')),
//           );
//         }
//       }
//     } finally {
//       _isLoadingNotifier.value = false;
//       _isNavigating = false;
//     }
//   }

//   Future<void> _initializeData() async {
//     await getSingleStudent();
//     await _refreshStudentCache();
//     _calculateNextSchoolEvent();
//     _startCountdown();
//   }

//   Future<void> _refreshStudentCache() async {
//     final ids = widget.guardianStudents.map((e) => e.id.toString()).join(',');
//     debugPrint('Getting student data for IDs: $ids');
//     DataMap parameters = {
//       'size': '100',
//       'page': '0',
//       'sort': 'id,asc',
//       'status.in': 'A',
//       'id.in': ids,
//     };
//     try {
//       final fetchedStudents = await context
//           .read<StudentDataCubit>()
//           .getAllStudentsData(parameters: parameters);
//       if (mounted) {
//         setState(() {
//           _cachedStudents = fetchedStudents;
//           _precomputeNavigationRoute();
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching all students: $e');
//       if (mounted) {
//         setState(() {
//           _cachedStudents = [];
//           _precomputedRoute = null;
//         });
//       }
//     }
//   }

//   Future<void> _refreshLocationData() async {
//     final locationService = LocationService();
//     try {
//       debugPrint('Refreshing location data...');
//       await locationService.updatePosition();
//       setState(() {
//         isLocationEnabled = locationService.isLocationEnabled;
//         isWithinGeofence = locationService.isWithinGeofence;
//       });
//       debugPrint(
//           'Location refreshed: Lat=${locationService.currentPosition?.latitude}, Lon=${locationService.currentPosition?.longitude}, isWithinGeofence=$isWithinGeofence');
//     } catch (e) {
//       debugPrint('Error refreshing location: $e');
//       setState(() {
//         isLocationEnabled = false;
//       });
//     }
//   }

//   @override
//   void didUpdateWidget(MyChildsDayCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.studentId != widget.studentId) {
//       debugPrint(
//           'StudentId changed from ${oldWidget.studentId} to ${widget.studentId}');
//       _timer?.cancel();
//       setState(() {
//         _statusText = 'Loading schedule...';
//         _duration = const Duration(hours: 0);
//         studenttoShow = StudentEntity.empty;
//       });
//       _initializeData();
//     }
//   }

//   void restartTimer() {
//     debugPrint('Timer refresh called');
//     _timer?.cancel();
//     setState(() {
//       _statusText = 'Loading schedule...';
//       _duration = const Duration(hours: 0);
//     });
//     _refreshDataAndTimer();
//   }

//   Future<void> _refreshDataAndTimer() async {
//     try {
//       await _refreshLocationData(); // Added to refresh location data
//       await getSingleStudent();
//       await _refreshStudentCache();
//       _calculateNextSchoolEvent();
//       _startCountdown();
//       debugPrint('Timer and data refreshed successfully');
//     } catch (e) {
//       debugPrint('Error refreshing timer data: $e');
//       if (mounted) {
//         setState(() {
//           _statusText = 'Error refreshing data';
//         });
//       }
//     }
//   }

//   void _calculateNextSchoolEvent() {
//     final now = DateTime.now();
//     final schedule = studenttoShow.schedule;

//     if (schedule.isEmpty) {
//       setState(() {
//         _duration = const Duration(hours: 0);
//         _statusText = 'No schedule available';
//       });
//       return;
//     }

//     final currentDayOfWeek = now.weekday;
//     ScheduleDataModel? todaySchedule =
//         _findScheduleForDay(schedule, currentDayOfWeek);

//     if (todaySchedule != null &&
//         todaySchedule.startTime.isNotEmpty &&
//         todaySchedule.endTime.isNotEmpty) {
//       final startTime = _parseTimeString(todaySchedule.startTime);
//       final endTime = _parseTimeString(todaySchedule.endTime);

//       if (startTime != null && endTime != null) {
//         final todayDate = now.toLocal().toString().split(' ')[0];
//         final schoolStartTime =
//             DateTime.parse('$todayDate ${_convertTo24Hour(startTime)}');
//         final schoolEndTime =
//             DateTime.parse('$todayDate ${_convertTo24Hour(endTime)}');

//         if (now.isBefore(schoolStartTime)) {
//           setState(() {
//             _duration = schoolStartTime.difference(now);
//             _statusText = 'School starts in';
//           });
//           return;
//         } else if (now.isAfter(schoolStartTime) &&
//             now.isBefore(schoolEndTime)) {
//           setState(() {
//             _duration = schoolEndTime.difference(now);
//             _statusText = 'School ends in';
//           });
//           return;
//         }
//       }
//     }

//     _findNextSchoolDay(now, schedule);
//   }

//   ScheduleDataModel? _findScheduleForDay(
//       List<ScheduleDataModel> schedule, int dayOfWeek) {
//     final dayNames = [
//       '',
//       'Monday',
//       'Tuesday',
//       'Wednesday',
//       'Thursday',
//       'Friday',
//       'Saturday',
//       'Sunday'
//     ];
//     final targetDay = dayNames[dayOfWeek];
//     return schedule.firstWhere(
//       (s) => s.day.toLowerCase() == targetDay.toLowerCase(),
//       orElse: () => ScheduleDataModel.empty,
//     );
//   }

//   void _findNextSchoolDay(DateTime now, List<ScheduleDataModel> schedule) {
//     for (int i = 1; i <= 7; i++) {
//       final futureDate = now.add(Duration(days: i));
//       final futureDayOfWeek = futureDate.weekday;

//       final futureSchedule = _findScheduleForDay(schedule, futureDayOfWeek);
//       if (futureSchedule != null &&
//           futureSchedule.startTime.isNotEmpty &&
//           futureSchedule.endTime.isNotEmpty) {
//         final startTime = _parseTimeString(futureSchedule.startTime);
//         if (startTime != null) {
//           final futureDateString =
//               futureDate.toLocal().toString().split(' ')[0];
//           final futureSchoolStartTime = DateTime.parse(
//               '$futureDateString ${_convertTo24Hour(startTime)}');
//           setState(() {
//             _duration = futureSchoolStartTime.difference(now);
//             if (i == 1) {
//               _statusText = 'Tomorrow\'s school starts in';
//             } else {
//               final dayNames = [
//                 '',
//                 'Monday',
//                 'Tuesday',
//                 'Wednesday',
//                 'Thursday',
//                 'Friday',
//                 'Saturday',
//                 'Sunday'
//               ];
//               _statusText = '${dayNames[futureDayOfWeek]}\'s school starts in';
//             }
//           });
//           return;
//         }
//       }
//     }

//     setState(() {
//       _duration = const Duration(hours: 0);
//       _statusText = 'No upcoming school schedule';
//     });
//   }

//   String _getCurrentSchoolHours() {
//     final schedule = studenttoShow.schedule;
//     if (schedule.isEmpty) return 'No schedule';

//     final now = DateTime.now();
//     final currentDayOfWeek = now.weekday;
//     final todaySchedule = _findScheduleForDay(schedule, currentDayOfWeek);

//     if (todaySchedule != null &&
//         todaySchedule.startTime.isNotEmpty &&
//         todaySchedule.endTime.isNotEmpty) {
//       final startTime = _parseTimeString(todaySchedule.startTime);
//       final endTime = _parseTimeString(todaySchedule.endTime);

//       if (startTime != null && endTime != null) {
//         return '${DateFormat('hh:mm a').format(DateTime(2000, 1, 1, startTime.hour, startTime.minute))} - ${DateFormat('hh:mm a').format(DateTime(2000, 1, 1, endTime.hour, endTime.minute))}';
//       }
//     }

//     final nearestSchedule = _findNearestSchedule(schedule, now);
//     if (nearestSchedule != null &&
//         nearestSchedule.startTime.isNotEmpty &&
//         nearestSchedule.endTime.isNotEmpty) {
//       final startTime = _parseTimeString(nearestSchedule.startTime);
//       final endTime = _parseTimeString(nearestSchedule.endTime);
//       if (startTime != null && endTime != null) {
//         final dayAbbreviation = _getDayAbbreviation(nearestSchedule.day);
//         return '${DateFormat('hh:mm a').format(DateTime(2000, 1, 1, startTime.hour, startTime.minute))} - ${DateFormat('hh:mm a').format(DateTime(2000, 1, 1, endTime.hour, endTime.minute))} ($dayAbbreviation)';
//       }
//     }
//     return 'No upcoming schedule';
//   }

//   ScheduleDataModel? _findNearestSchedule(
//       List<ScheduleDataModel> schedule, DateTime now) {
//     for (int i = 1; i <= 7; i++) {
//       final futureDate = now.add(Duration(days: i));
//       final futureDayOfWeek = futureDate.weekday;
//       final futureSchedule = _findScheduleForDay(schedule, futureDayOfWeek);
//       if (futureSchedule != null) {
//         return futureSchedule;
//       }
//     }
//     return null;
//   }

//   String _getDayAbbreviation(String fullDay) {
//     switch (fullDay.toLowerCase()) {
//       case 'monday':
//         return 'MON';
//       case 'tuesday':
//         return 'TUE';
//       case 'wednesday':
//         return 'WED';
//       case 'thursday':
//         return 'THU';
//       case 'friday':
//         return 'FRI';
//       case 'saturday':
//         return 'SAT';
//       case 'sunday':
//         return 'SUN';
//       default:
//         return fullDay.substring(0, 3).toUpperCase();
//     }
//   }

//   TimeOfDay? _parseTimeString(String timeStr) {
//     try {
//       final parts = timeStr.split(' ');
//       final timeParts = parts[0].split(':');
//       int hours = int.parse(timeParts[0]);
//       int minutes = int.parse(timeParts[1]);
//       if (parts.length > 1) {
//         final isPM = parts[1].toLowerCase() == 'pm';
//         if (isPM && hours != 12) hours += 12;
//         if (!isPM && hours == 12) hours = 0;
//       }
//       return TimeOfDay(hour: hours, minute: minutes);
//     } catch (e) {
//       debugPrint('Error parsing time string: $e');
//       return null;
//     }
//   }

//   String _convertTo24Hour(TimeOfDay time) {
//     final hours = time.hour.toString().padLeft(2, '0');
//     final minutes = time.minute.toString().padLeft(2, '0');
//     return '$hours:$minutes:00';
//   }

//   Future<void> getSingleStudent() async {
//     try {
//       final fetchedStudent = await context
//           .read<StudentDataCubit>()
//           .getSingleStudentData(id: widget.studentId);
//       if (mounted) {
//         setState(() {
//           studenttoShow = fetchedStudent;
//         });
//         debugPrint('Student data updated: ${studenttoShow.fullName}');
//       }
//     } catch (e) {
//       debugPrint('Error fetching single student: $e');
//       if (mounted) {
//         setState(() {
//           _statusText = 'Error loading student data';
//         });
//       }
//     }
//   }

//   Future<List<StudentEntity>> getAllStudents() async {
//     try {
//       final ids = widget.guardianStudents.map((e) => e.id.toString()).join(',');
//       debugPrint('Getting student data for IDs: $ids');
//       DataMap parameters = {
//         'size': '100',
//         'page': '0',
//         'sort': 'id,asc',
//         'status.in': 'A',
//         'id.in': ids,
//       };
//       final fetchedStudents = await context
//           .read<StudentDataCubit>()
//           .getAllStudentsData(parameters: parameters);
//       if (mounted) {
//         setState(() {
//           _cachedStudents = fetchedStudents;
//           _precomputeNavigationRoute();
//         });
//       }
//       return fetchedStudents;
//     } catch (e) {
//       debugPrint('Error fetching all students: $e');
//       return [];
//     }
//   }

//   void _updateLocationStatus() {
//     if (mounted) {
//       setState(() {
//         final locationService = LocationService();
//         isLocationEnabled = locationService.isLocationEnabled;
//         isWithinGeofence = locationService.isWithinGeofence;
//       });
//       _updateLocationName();
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _debounceTimer?.cancel();
//     _positionStreamSubscription?.cancel();
//     LocationService().onGeofenceStatusChanged = null;
//     _isLoadingNotifier.dispose();
//     super.dispose();
//   }

//   void _startCountdown() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//       setState(() {
//         if (_duration.inSeconds > 0) {
//           _duration = _duration - const Duration(seconds: 1);
//         } else {
//           _calculateNextSchoolEvent();
//         }
//       });
//     });
//   }

//   Widget _buildAlignedTimerDisplay(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final bool showDays = duration.inHours >= 24;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         if (showDays) ...[
//           _buildTimeUnit(duration.inDays.toString(), 'DD'),
//           _buildTimeSeparator(),
//         ],
//         _buildTimeUnit(twoDigits(duration.inHours.remainder(24)), 'HH'),
//         _buildTimeSeparator(),
//         _buildTimeUnit(twoDigits(duration.inMinutes.remainder(60)), 'MM'),
//         _buildTimeSeparator(),
//         _buildTimeUnit(twoDigits(duration.inSeconds.remainder(60)), 'SS'),
//       ],
//     );
//   }

//   Widget _buildTimeUnit(String value, String label) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             color: AppColors.primaryColor,
//             fontSize: 48,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             color: AppColors.primaryColor.withValues(alpha: 0.5),
//             fontSize: 12,
//             height: 0.1,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTimeSeparator() {
//     return const Padding(
//       padding: EdgeInsets.fromLTRB(2, 0, 2, 10),
//       child: Text(
//         ':',
//         style: TextStyle(
//           color: AppColors.primaryColor,
//           fontSize: 48,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Widget _builtStudentDetailContainer() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Column(
//           children: [
//             BlocProvider(
//               create: (context) => sl<DocumentBloc>(),
//               child: Stack(
//                 children: [
//                   DocumentImageWidget(
//                     fileUuid: studenttoShow.id != 0
//                         ? '${studenttoShow.photoUuid}'
//                         : '',
//                     name: studenttoShow.fullName,
//                     size: 90,
//                     fontSize: 28,
//                   ),
//                   Positioned(
//                     right: 4,
//                     top: 4,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: studenttoShow.profileStatus == 'Upcoming'
//                             ? const Color.fromARGB(255, 253, 205, 22)
//                             : studenttoShow.isSignedIn
//                                 ? const Color.fromRGBO(0, 177, 21, 1)
//                                 : studenttoShow.isAbsent
//                                     ? const Color.fromRGBO(200, 32, 32, 1)
//                                     : null,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: studenttoShow.profileStatus == 'Upcoming' ||
//                                   studenttoShow.isSignedIn ||
//                                   studenttoShow.isAbsent
//                               ? Colors.white
//                               : Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                       constraints: const BoxConstraints(
//                         minWidth: 18,
//                         minHeight: 18,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(width: 20),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               studenttoShow.id != 0 ? '${studenttoShow.fullName}' : '',
//               style: const TextStyle(
//                 color: AppColors.primaryColor,
//                 fontSize: 18,
//               ),
//             ),
//             const SizedBox(height: 4),
//             CustomChip(
//               label: _getCurrentSchoolHours(),
//               labelStyle: const TextStyle(
//                 color: AppColors.secondaryColor,
//                 fontWeight: FontWeight.w500,
//               ),
//               color: const Color.fromRGBO(177, 175, 233, 0.3),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 BlocProvider(
//                   create: (context) => sl<DocumentBloc>(),
//                   child: DocumentImageWidget(
//                     fileUuid: '',
//                     name: studenttoShow.roomName,
//                     size: 32,
//                   ),
//                 ),
//                 const SizedBox(width: 8.0),
//                 Text(
//                   studenttoShow.id != 0 ? '${studenttoShow.roomName}' : '',
//                   style: const TextStyle(
//                     color: AppColors.primaryColor,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   bool areAllStudentsSignedIn() {
//     return _cachedStudents.isNotEmpty &&
//         _cachedStudents.every((student) => student.isSignedIn == true);
//   }

//   bool areAllStudentsSignedOut() {
//     return _cachedStudents.isNotEmpty &&
//         _cachedStudents.every((student) => student.isSignedIn == false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       physics: const NeverScrollableScrollPhysics(),
//       child: Card(
//         elevation: 0,
//         margin: const EdgeInsets.all(0),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: BorderSide(
//             color: AppColors.primaryColor.withValues(alpha: 0.1),
//           ),
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//               decoration: const BoxDecoration(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//                 color: Colors.white,
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Text(
//                         'My Child’s Day',
//                         style: TextStyle(
//                           color: AppColors.primaryColor,
//                           fontSize: 20,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         textAlign: TextAlign.start,
//                       ),
//                       const Spacer(),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _isMinimized = !_isMinimized;
//                           });
//                           if (_isMinimized && widget.onClose != null) {
//                             widget.onClose!();
//                           }
//                         },
//                         child: Container(
//                           width: 32,
//                           height: 32,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             border: Border.all(
//                               color: AppColors.themeColor,
//                               width: 2,
//                             ),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Center(
//                             child: Icon(
//                               _isMinimized ? Icons.add : Icons.remove,
//                               color: AppColors.themeColor,
//                               size: 24,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (!_isMinimized) ...[
//                     const SizedBox(height: 8),
//                     Center(
//                       child: Text(
//                         _statusText,
//                         style: const TextStyle(
//                           color: AppColors.primaryColor,
//                           fontSize: 17,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     _buildAlignedTimerDisplay(_duration),
//                     const SizedBox(height: 16),
//                     GestureDetector(
//                       onTap: () async {
//                         debugPrint(
//                             'context.currentGuardian!.students ${context.currentGuardian!.students}');
//                         GuardianDataModel guardianDataModel = await context
//                             .read<GuardianCubit>()
//                             .updateGuardian(
//                               updateguardian: GuardianDataModel(
//                                 id: context.currentGuardian!.id,
//                                 fullName: context.currentGuardian!.fullName,
//                                 email: context.currentGuardian!.email,
//                                 phoneNumber:
//                                     context.currentGuardian!.phoneNumber,
//                                 relation: context.currentGuardian!.relation,
//                                 emergencyContact:
//                                     context.currentGuardian!.emergencyContact,
//                                 inviteFlag: context.currentGuardian!.inviteFlag,
//                                 signInPin: context.currentGuardian!.signInPin,
//                                 isReminder:
//                                     context.currentGuardian!.isReminder == false
//                                         ? true
//                                         : false,
//                                 studentId: context.currentGuardian!.studentId,
//                                 schoolId: context.currentGuardian!.schoolId,
//                                 status: context.currentGuardian!.status,
//                                 lastModified:
//                                     context.currentGuardian!.lastModified,
//                                 lastModifiedBy:
//                                     context.currentGuardian!.lastModifiedBy,
//                                 photoUuid: context.currentGuardian!.photoUuid,
//                                 isUpcoming: context.currentGuardian!.isUpcoming,
//                                 students: context.currentGuardian!.students,
//                               ),
//                             );
//                         context.guardianProvider
//                             .initGuardian(guardianDataModel);
//                         guardianDataModel.isReminder
//                             ? CoreUtils.showTopSnackBar(
//                                 context: context,
//                                 isError: false,
//                                 isWarning: false,
//                                 isSuccess: true,
//                                 message: 'Remind set successfully',
//                                 isAdjust: false,
//                               )
//                             : CoreUtils.showTopSnackBar(
//                                 context: context,
//                                 isError: false,
//                                 isWarning: false,
//                                 isSuccess: true,
//                                 message:
//                                     'Remind timer has turned off successfully',
//                                 isAdjust: false,
//                               );
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SvgPicture.asset(MediaRes.notificationsGradientIcon),
//                           const SizedBox(width: 8),
//                           ShaderMask(
//                             shaderCallback: (bounds) =>
//                                 AppColors.buildPrimaryGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ).createShader(
//                               Rect.fromLTWH(0, 0, bounds.width, bounds.height),
//                             ),
//                             child: Text(
//                               context.currentGuardian!.isReminder
//                                   ? 'Turn off reminder'
//                                   : 'Send reminder',
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Center(
//                       child: Text(
//                         'Current Location: $_currentLocationName',
//                         style: TextStyle(
//                           color: AppColors.primaryColor.withValues(alpha: 0.7),
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     _builtStudentDetailContainer(),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         ShaderMask(
//                           shaderCallback: (bounds) =>
//                               AppColors.buildPrimaryGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ).createShader(
//                             Rect.fromLTWH(0, 0, bounds.width, bounds.height),
//                           ),
//                           child: Text(
//                             'Your Sign-In Pin:  ${context.currentGuardian!.signInPin}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         IconButton(
//                           onPressed: () {
//                             final studentDataState =
//                                 context.read<StudentDataCubit>().state;
//                             if (studentDataState is AllStudentsDataLoaded) {
//                               Navigator.pushNamed(
//                                 context,
//                                 QrScanScreen.routeName,
//                                 arguments: studentDataState.students,
//                               );
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                     content: Text(
//                                         'Loading student data. Please try again.')),
//                               );
//                             }
//                           },
//                           icon: SvgPicture.asset(MediaRes.scannerGradientIcon),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               decoration: ShapeDecoration(
//                                 gradient: isWithinGeofence && isLocationEnabled
//                                     ? const LinearGradient(
//                                         begin: Alignment(0.00, 0.50),
//                                         end: Alignment(1.00, 0.50),
//                                         colors: [
//                                           Color(0xFF5978F7),
//                                           Color(0xFF9B84FF)
//                                         ],
//                                       )
//                                     : const LinearGradient(
//                                         begin: Alignment(0.00, 0.50),
//                                         end: Alignment(1.00, 0.50),
//                                         colors: [Colors.grey, Colors.grey],
//                                       ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(6.96),
//                                 ),
//                               ),
//                               child: Tooltip(
//                                 message: !isLocationEnabled
//                                     ? 'Location permission is not granted.'
//                                     : !isWithinGeofence
//                                         ? 'You are not within the geofencing range.'
//                                         : '',
//                                 triggerMode: TooltipTriggerMode.tap,
//                                 preferBelow: false,
//                                 child: ValueListenableBuilder<bool>(
//                                   valueListenable: _isLoadingNotifier,
//                                   builder: (context, isLoading, child) {
//                                     return ElevatedButton(
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.transparent,
//                                         shadowColor: Colors.transparent,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(6.96),
//                                         ),
//                                       ),
//                                       onPressed: (isWithinGeofence &&
//                                               isLocationEnabled &&
//                                               !isLoading &&
//                                               !_isNavigating)
//                                           ? _handleSignInOut
//                                           : null,
//                                       child: Stack(
//                                         alignment: Alignment.center,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               const Expanded(
//                                                 flex: 2,
//                                                 child: Column(
//                                                   children: [
//                                                     Icon(
//                                                       Icons
//                                                           .share_location_outlined,
//                                                       color: Colors.white,
//                                                       size: 24,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                               Expanded(
//                                                 flex: 3,
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     BlocBuilder<
//                                                         StudentDataCubit,
//                                                         StudentDataState>(
//                                                       builder:
//                                                           (context, state) {
//                                                         if (state
//                                                                 is AllStudentsDataLoaded &&
//                                                             state.students
//                                                                 .isNotEmpty) {
//                                                           final isMultiple =
//                                                               state.students
//                                                                       .length >
//                                                                   1;
//                                                           final isSignedIn =
//                                                               studenttoShow
//                                                                   .isSignedIn;
//                                                           return Text(
//                                                             isMultiple
//                                                                 ? 'Sign-In/Out'
//                                                                 : (isSignedIn &&
//                                                                         !isMultiple
//                                                                     ? 'Sign-Out'
//                                                                     : 'Sign-In'),
//                                                             style:
//                                                                 const TextStyle(
//                                                               color:
//                                                                   Colors.white,
//                                                               fontSize: 20,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w700,
//                                                               letterSpacing:
//                                                                   16 *
//                                                                       (-3 /
//                                                                           100),
//                                                             ),
//                                                           );
//                                                         }
//                                                         return const Text(
//                                                           'Sign-In/Out',
//                                                           style: TextStyle(
//                                                             color: Colors.white,
//                                                             fontSize: 20,
//                                                             fontWeight:
//                                                                 FontWeight.w700,
//                                                             letterSpacing:
//                                                                 16 * (-3 / 100),
//                                                           ),
//                                                         );
//                                                       },
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           if (isLoading)
//                                             const CircularProgressIndicator(
//                                               valueColor:
//                                                   AlwaysStoppedAnimation<Color>(
//                                                       Colors.white),
//                                             ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             if (!_isMinimized)
//               CommunicationRowWidget(
//                 student: studenttoShow,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CommunicationRowWidget extends StatefulWidget {
//   const CommunicationRowWidget({
//     super.key,
//     required this.student,
//   });

//   final StudentEntity student;

//   @override
//   State<CommunicationRowWidget> createState() => _CommunicationRowWidgetState();
// }

// class _CommunicationRowWidgetState extends State<CommunicationRowWidget> {
//   String chatId = "chat";
//   bool isUsersLoading = false;
//   bool isChatLoading = false;
//   List<FirestoreUser> users = [];

//   @override
//   void initState() {
//     super.initState();
//     getAllFireStoreUsers();
//     getChatIdByStudentId();
//   }

//   @override
//   void didUpdateWidget(CommunicationRowWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.student != widget.student) {
//       getChatIdByStudentId();
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void getAllFireStoreUsers() async {
//     try {
//       setState(() {
//         isUsersLoading = true;
//       });
//       final event = await firestore.collection("users").get();
//       final fetchedUsers = event.docs.map((doc) {
//         final data = doc.data();
//         final profileData = data['profile'] as DataMap? ?? {};
//         final profile = UserProfile.fromMap(profileData);
//         return FirestoreUser(
//           id: data['id'] as String? ?? doc.id,
//           profile: profile,
//         );
//       }).toList();
//       if (mounted) {
//         setState(() {
//           users = fetchedUsers;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         // CoreUtils.showTopSnackBar(
//         //   context: context,
//         //   isError: true,
//         //   isWarning: false,
//         //   isSuccess: false,
//         //   message: 'Failed to fetch users',
//         //   isAdjust: false,
//         // );
//       }
//     }
//     setState(() {
//       isUsersLoading = false;
//     });
//   }

//   Future<List<QueryDocumentSnapshot>> getChatsByStudentId(
//       String studentId) async {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('chats')
//         .where('studentInfo.id', isEqualTo: studentId)
//         .get();
//     return querySnapshot.docs;
//   }

//   Future<void> getChatIdByStudentId() async {
//     setState(() {
//       isChatLoading = true;
//     });
//     final docs = await getChatsByStudentId('student_${widget.student.id}');
//     final chatIds = docs.map((doc) => doc.id).toList();
//     setState(() {
//       if (chatIds.isNotEmpty) {
//         chatId = chatIds[0];
//       } else {
//         chatId = 'temp';
//       }
//       isChatLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isChatLoading || isUsersLoading) {
//       return const ShimmerLoaderCard(child: SizedBox(height: 40));
//     }
//     return StreamBuilder<DocumentSnapshot>(
//       stream: firestore.collection("chats").doc(chatId).snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             // CoreUtils.showTopSnackBar(
//             //   context: context,
//             //   isError: true,
//             //   isWarning: false,
//             //   isSuccess: false,
//             //   message: 'Failed to get the student conversation',
//             //   isAdjust: false,
//             // );
//           });
//           return const ShimmerLoaderCard(child: SizedBox(height: 40));
//         }
//         if (!snapshot.hasData) {
//           return const ShimmerLoaderCard(child: SizedBox(height: 40));
//         }

//         final data = snapshot.data!.data() as Map<String, dynamic>?;
//         if (data == null) {
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
//               color: Color.fromRGBO(44, 99, 226, 0.05),
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 BlocProvider(
//                   create: (context) => sl<DocumentBloc>(),
//                   child: DocumentImageWidget(
//                     fileUuid: widget.student.photoUuid,
//                     name: widget.student.fullName,
//                     size: 40,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.student.fullName,
//                       style: const TextStyle(
//                         color: AppColors.primaryColor,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Text(
//                       'Chat not Found',
//                       style: TextStyle(
//                         color: AppColors.primaryColor.withValues(alpha: 0.5),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 CustomFloatingActionButton(
//                   onPressed: () {
//                     Navigator.of(context)
//                         .push(MaterialPageRoute(builder: (context) {
//                       return MultiBlocProvider(
//                         providers: [
//                           BlocProvider(
//                               create: (context) => sl<GuardianCubit>()),
//                           BlocProvider(
//                               create: (context) => sl<StudentDataCubit>()),
//                         ],
//                         child: const StudentConversationScreen(),
//                       );
//                     }));
//                   },
//                   svgIcon: MediaRes.communicationIcon,
//                   borderRadius: 14,
//                 ),
//               ],
//             ),
//           );
//         }
//         final chatJson = {
//           'chatId': snapshot.data!.id,
//           ...data,
//         };

//         final ParentMessagingChat chat = ParentMessagingChat.fromJson(chatJson);

//         final filteredMessages = [];
//         for (final message in chat.messages!) {
//           final isCurrentUserTarget = 'parent_${message.targetGuardianId}' ==
//               'parent_${context.currentGuardian!.id}';
//           final isPrivateMessage = message.isPrivate;
//           if (!isCurrentUserTarget && (isPrivateMessage ?? false)) {
//             continue;
//           } else {
//             filteredMessages.add(message);
//           }
//         }
//         final message = filteredMessages.isNotEmpty
//             ? filteredMessages[filteredMessages.length - 1]
//             : 'No Messages';
//         FirestoreUser? sender;
//         String senderName = 'Unknown';
//         for (final user in users) {
//           if (user.id == message.senderId) {
//             senderName = user.profile.name;
//             sender = user;
//             break;
//           }
//         }
//         sender ??= FirestoreUser(
//           id: '',
//           profile: UserProfile(
//               name: '',
//               email: '',
//               photoURL: '',
//               lastSeen: 0,
//               status: '',
//               role: ''),
//         );
//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//           decoration: const BoxDecoration(
//             borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
//             color: Color.fromRGBO(44, 99, 226, 0.05),
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               BlocProvider(
//                 create: (context) => sl<DocumentBloc>(),
//                 child: sender.id.startsWith('staff_')
//                     ? DocumentImageWidget(
//                         fileUuid: sender.profile.photoURL,
//                         name: sender.profile.name,
//                         size: 40,
//                       )
//                     : DocumentImageWidget(
//                         fileUuid: widget.student.photoUuid,
//                         name: widget.student.fullName,
//                         size: 40,
//                       ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       senderName,
//                       style: const TextStyle(
//                         color: AppColors.primaryColor,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     Text(
//                       message.text,
//                       style: TextStyle(
//                         color: AppColors.primaryColor.withValues(alpha: 0.5),
//                         fontWeight: FontWeight.w500,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               CustomFloatingActionButton(
//                 onPressed: () {
//                   Navigator.of(context)
//                       .push(MaterialPageRoute(builder: (context) {
//                     return MultiBlocProvider(
//                       providers: [
//                         BlocProvider(create: (context) => sl<GuardianCubit>()),
//                         BlocProvider(
//                             create: (context) => sl<StudentDataCubit>()),
//                       ],
//                       child: const StudentConversationScreen(),
//                     );
//                   }));
//                 },
//                 svgIcon: MediaRes.communicationIcon,
//                 borderRadius: 14,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
