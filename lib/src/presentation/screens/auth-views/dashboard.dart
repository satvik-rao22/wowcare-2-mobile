// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});
//   // final SecurityUserModel? user;
//   final String? role;
//   static const routeName = '/dashboard';

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
//   String role = '';
//   bool _isLoadingUser = true;
//   bool _isInitializingLocation = true;
//   bool isLoadingProfilePhoto = false;
//   bool _permissionDenied = false;
//   bool isFirstTime = true;
//   bool isHandlingData = false;

//   // final LocationService _locationService = LocationService();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     WidgetsBinding.instance.addObserver(this);
    // _handleLocationPermission();

    // if (widget.user != null) {
    //   _handleUserData(widget.user!);
    // }
    // role = widget.role ?? widget.user?.refTable ?? '';
//   }

  // Future<void> _handleLocationPermission() async {
  //   setState(() {
  //     _isInitializingLocation = true;
  //   });

  //   // Check permission first
  //   LocationPermission permission = await Geolocator.checkPermission();

  //   // If permission is denied, request it
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //   }

  //   // Handle permission result
  //   if (permission == LocationPermission.denied ||
  //       permission == LocationPermission.deniedForever) {
  //     // User denied permission - proceed to dashboard anyway
  //     setState(() {
  //       _permissionDenied = true;
  //       _isInitializingLocation = false;
  //     });
  //     return;
  //   }

  //   // User granted permission, check if GPS is enabled
  //   final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

  //   if (!isLocationEnabled) {
  //     // Show location settings prompt only if user granted permission
  //     bool openedSettings = await _showLocationSettingsDialog();

  //     if (openedSettings) {
  //       // Wait for a moment to check again if GPS was enabled
  //       await Future.delayed(const Duration(seconds: 3));
  //       final isEnabledAfterPrompt =
  //           await Geolocator.isLocationServiceEnabled();

  //       if (!isEnabledAfterPrompt) {
  //         // User didn't turn on GPS after opening settings
  //         // We'll still initialize location service but it won't work until GPS is enabled
  //         await _locationService.initialize();
  //       } else {
  //         // User turned on GPS
  //         await _locationService.initialize();
  //       }
  //     } else {
  //       // User dismissed the dialog, initialize anyway
  //       await _locationService.initialize();
  //     }
  //   } else {
  //     // GPS is already enabled, just initialize
  //     await _locationService.initialize();
  //   }

  //   setState(() {
  //     _isInitializingLocation = false;
  //   });
  // }

//   Future<bool> _showLocationSettingsDialog() async {
//     bool openedSettings = false;

//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Location Services Disabled'),
//           content: const Text(
//             'GPS is required for better experience. Would you like to turn it on?',
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Open Settings'),
//               onPressed: () async {
//                 openedSettings = true;
//                 Navigator.of(context).pop();
//                 await Geolocator.openLocationSettings();
//               },
//             ),
//             TextButton(
//               child: const Text('Continue Without GPS'),
//               onPressed: () {
//                 openedSettings = false;
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );

//     return openedSettings;
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     // _locationService.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // _locationService.checkLocationStatus();
//       // _locationService.resumeTracking();
//     } else if (state == AppLifecycleState.paused) {
//       // _locationService.pauseTracking();
//     }
//   }

//   Future<void> _loadUserData() async {
//     setState(() {
//       _isLoadingUser = true;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<AuthenticationBloc, AuthenticationState>(
//       listener: (context, state) {
//         if (state is SingleSecurityUserLoaded) {
//           _handleUserData(state.user);
//           context.userProviders.initUser(state.user);
//           setState(() {
//             _isLoadingUser = false;
//           });
//         } else if (state is AuthErrorAuthentication) {
//           setState(() {
//             _isLoadingUser = false;
//           });
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(state.message)));
//         }
//       },
//       builder: (context, state) {
//         if ((state is GettingSingleSecurityUser && _isLoadingUser) ||
//             _isInitializingLocation) {
//           return _loadingScreen();
//         }
//         if (state is SingleSecurityUserLoaded) {
//           // If user denied location permission, go straight to dashboard
//           if (isFirstTime) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               setState(() {
//                 isFirstTime = false;
//               });
//               _handleUserData(state.user);
//             });
//           }
//           if (_permissionDenied) {
//             return _getDashboardByRole();
//           }

//           // If user allowed permission but GPS is not enabled
//           final locationService = Provider.of<LocationService>(context);
//           if (!locationService.isLocationEnabled) {
//             // Show a non-blocking indicator that location is off
//             // but still show the dashboard
//             return _getDashboardWithLocationWarning();
//           }

//           return _getDashboardByRole();
//         }

//         return _unrecognizedRoleScreen();
//       },
//     );
//   }

//   Widget _getDashboardByRole() {
//     if (!isHandlingData) {
//       if (isAdminRole(role)) {
//         if (ModalRoute.of(context)?.settings.name != AdminDashboard.routeName) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             Navigator.pushReplacementNamed(context, AdminDashboard.routeName);
//           });
//           return _loadingScreen();
//         }
//         return const AdminDashboard();
//       } else if (isTeachingRole(role)) {
//         if (ModalRoute.of(context)?.settings.name != StaffDashboard.routeName) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             Navigator.pushReplacementNamed(context, StaffDashboard.routeName);
//           });
//           return _loadingScreen();
//         }
//         return const StaffDashboard();
//       } else if (isGuardianRole(role)) {
//         if (ModalRoute.of(context)?.settings.name !=
//             ParentDashboard.routeName) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             Navigator.pushReplacementNamed(context, ParentDashboard.routeName);
//           });
//           return _loadingScreen();
//         }
//         return const ParentDashboard();
//       } else if (isKioskRole(role)) {
//         if (ModalRoute.of(context)?.settings.name != KioskDashboard.routeName) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             Navigator.pushReplacementNamed(context, KioskDashboard.routeName);
//           });
//           return _loadingScreen();
//         }
//         return const KioskDashboard();
//       }
//     }
//     return _unrecognizedRoleScreen();
//   }

//   Widget _getDashboardWithLocationWarning() {
//     // Wrap the dashboard with a banner notification that location is off
//     return Stack(children: [_getDashboardByRole()]);
//   }

//   Widget _unrecognizedRoleScreen() {
//     return const Scaffold(
//       body: Center(child: SpinKitFoldingCube(color: Colors.black54, size: 80)),
//     );
//   }

//   Widget _loadingScreen() {
//     return const Scaffold(
//       body: Center(
//         child: SpinKitFoldingCube(color: AppColors.themeColor, size: 80),
//       ),
//     );
//   }

//   Future<void> _initializeProfilePhoto(
//     StaffModel? staff,
//     GuardianDataModel? guardian,
//   ) async {
//     if (!mounted) return;

//     try {
//       final documentBloc = context.read<DocumentBloc>();
//       final photoProvider = context.read<ProfilePhotoProvider>();

//       if (photoProvider.profilePhoto == null) {
//         await photoProvider.loadProfilePhoto(
//           documentBloc: documentBloc,
//           isStaff: staff != null ? true : false,
//           staff: staff,
//           guardian: guardian,
//           context: context,
//         );
//       }
//     } catch (e) {
//       debugPrint('Error loading profile photo: $e');
//     }
//   }

//   Future<void> _handleUserData(SecurityUserModel user) async {
//     setState(() {
//       isHandlingData = true;
//     });
//     if (!mounted) return;
//     try {
//       final count = await context.read<SchoolDataCubit>().getUserCount(
//         ssoKey: user.ssoKey,
//       );
//       if (!mounted) return;
//       await context.read<AuthProvider>().setUserCount(count);
//       await context.read<AuthProvider>().setSecurityUser(user);

//       if (user.refTable == 'Staff') {
//         final staff = await context.read<StaffCubit>().getSingleStaff(
//           id: user.refTableId,
//         );
//         final staffModel = StaffModel.fromMap((staff as StaffModel).toMap());
//         context.staffProviders.initStaff(staffModel);
//         if (!mounted) return;
//         final school = await context.read<SchoolCubit>().getSchool(
//           id: user.schoolId,
//         );
//         await context.read<AuthProvider>().setStaff(staff);
//         await context.read<AuthProvider>().setUserSchool(school);
//         if (!mounted) return;

//         setState(() {
//           role = staff.designation;
//           isHandlingData = false;
//         });

//         _initializeProfilePhoto(staff, null);
//       } else if (user.refTable == 'Guardian') {
//         final guardian = await context.read<GuardianCubit>().getGuardian(
//           id: user.refTableId,
//         );
//         debugPrint('Guardian fetched: ${guardian.toString()}');
//         final guardianModel = GuardianDataModel.fromMap(
//           (guardian as GuardianDataModel).toMap(),
//         );
//         context.guardianProvider.initGuardian(guardianModel);
//         await context.read<AuthProvider>().setGuardian(guardian);
//         final school = await context.read<SchoolCubit>().getSchool(
//           id: user.schoolId,
//         );
//         if (!mounted) return;
//         await context.read<AuthProvider>().setUserSchool(school);

//         setState(() {
//           role = 'Guardian';
//           isHandlingData = false;
//         });
//         _initializeProfilePhoto(null, (guardian as GuardianDataModel));
//       } else if (user.refTable == 'Kiosk') {
//         final staff = await context.read<StaffCubit>().getSingleStaff(
//           id: user.refTableId,
//         );
//         final staffModel = StaffModel.fromMap((staff as StaffModel).toMap());
//         context.staffProviders.initStaff(staffModel);
//         if (!mounted) return;
//         final school = await context.read<SchoolCubit>().getSchool(
//           id: user.schoolId,
//         );
//         await context.read<AuthProvider>().setStaff(staff);
//         await context.read<AuthProvider>().setUserSchool(school);
//         if (!mounted) return;

//         setState(() {
//           role = staff.designation;
//           isHandlingData = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isHandlingData = false;
//       });
//       debugPrint('Error in _handleUserData: $e');
//     }
//   }
// }

// bool isKioskRole(String role) {
//   return ['Kiosk'].contains(role);
// }

// bool isAdminRole(String role) {
//   return ['Admin', 'Director', 'Assistant Director', 'Owner'].contains(role);
// }

// bool isGuardianRole(String role) {
//   return ['Guardian'].contains(role);
// }

// bool isTeachingRole(String role) {
//   return [
//     'Staff',
//     'Lead Teacher',
//     'Floater Teacher',
//     'Assistant Teacher',
//     'Associate Teacher',
//   ].contains(role);
// }
