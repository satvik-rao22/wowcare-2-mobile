import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/shared/common/app/providers/theme_providers.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';

import 'src/app_router.dart';
import 'shared/common/app/providers/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// App starts from Splash and follows onboarding / login-context redirect flow.
// Create a global instance of NotificationService that will be initialized later
// final NotificationService notificationService = NotificationService();

// // This function is required to handle background messages
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   print("Handling a background message: ${message.messageId}");
//   // You can do minimal processing here, but avoid heavy work
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  // Only initialize if not already
  if (Platform.isIOS) {
    await Firebase.initializeApp(); // auto from GoogleService-Info.plist
  } else {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
  }

  // Set up background message handler
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // await init();
  // await initOld();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();

    // setAccessToken();
  }

  // void setAccessToken() async {
  //   if (AuthProvider.accessToken.isEmpty) {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     if ((prefs.getBool('rememberMe') ?? false) &&
  //         prefs.getString('accessToken').toString().isNotEmpty) {
  //       String token = prefs.getString('accessToken') ?? '';
  //       AuthProvider.setAccessToken(token);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // ChangeNotifierProvider.value(value: _locationService),
        // ChangeNotifierProvider(create: (_) => UserProviders()),
        // ChangeNotifierProvider(create: (_) => StaffProviders()),
        // ChangeNotifierProvider(create: (_) => GuardianProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Needed by GlobalScaffold/Drawer/NavBar to determine role-based UI
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => NavBarHeightProvider()),
        // ChangeNotifierProvider(create: (_) => ProfilePhotoProvider()),
        // BlocProvider(create: (_) => sl<MasterLookupBloc>()),
        // BlocProvider(create: (context) => sl<NappingStudentsCubit>()),
        // BlocProvider(create: (_) => sl<FormValidatorBloc>()),
        // BlocProvider(create: (_) => sl<AccessBloc>()),
        // BlocProvider(create: (_) => sl<PhysicalTrackerBloc>()),
        // BlocProvider(create: (_) => sl<AuthenticationBloc>()),
        // BlocProvider(create: (_) => sl<DocumentBloc>()),
        // BlocProvider(create: (_) => sl<DocumentCubit>()),
        // BlocProvider(create: (_) => sl<StaffCubit>()),
        // BlocProvider(create: (_) => sl<AddressCubit>()),
        // BlocProvider(create: (_) => sl<GuardianCubit>()),
        // BlocProvider(create: (_) => sl<PaymentGatewayMerchantSettingsCubit>()),
        // BlocProvider(create: (_) => sl<TotalAttendanceCubit>()),
        // BlocProvider(create: (_) => sl<AttendanceCubit>()),
        // BlocProvider(create: (_) => sl<AttendanceReportCubit>()),
        // BlocProvider(create: (_) => sl<RoomdataCubit>()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          double customScaler;
          double systemTextScaleFactor = MediaQuery.of(
            context,
          ).textScaler.scale(1);

          if (systemTextScaleFactor < 0.85) {
            customScaler = 0.8;
          } else if (systemTextScaleFactor >= 0.85 &&
              systemTextScaleFactor < 1.0) {
            customScaler = 0.9;
          } else if (systemTextScaleFactor >= 1.0 &&
              systemTextScaleFactor < 1.2) {
            customScaler = 1.0;
          } else if (systemTextScaleFactor >= 1.2 &&
              systemTextScaleFactor < 1.5) {
            customScaler = 1.1;
          } else {
            customScaler = 1.2;
          }

          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(customScaler)),
            child: Sizer(
              builder: (context, orientation, screenType) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<AuthCubit>(
                      create: (_) {
                        final cubit = serviceLocator<AuthCubit>();
                        cubit.initialize();
                        return cubit;
                      },
                    ),
                  ],
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'WowCare',
                    theme: themeProvider.currentTheme,
                    home: const SplashScreenWrapper(),
                    onGenerateRoute: generateRoute,
                    navigatorKey: navigatorKey,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
    _navigateToHome();
  }

  // Initialize notifications now that we have a context
  Future<void> _initNotifications() async {
    // try {
    //   await notificationService.init(context);
    //   print('Notification service initialized successfully');
    // } catch (e) {
    //   print('Error initializing notification service: $e');
    // }
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      final storage = serviceLocator<StorageService>();

      final seenOnboarding =
          await storage.getBool(StorageKeys.onboardingSeen) ?? false;

      if (!seenOnboarding) {
        // Very first app launch: always show onboarding once and clear any old auth.
        await serviceLocator<AuthLocalDataSource>().clearCache();
        Navigator.pushReplacementNamed(context, '/first-screen');
      } else {
        // After onboarding:
        // - Always call login-context on app start whenever we have a cached login,
        //   and always use its redirectUrl (if any) to decide navigation.
        String? redirectUrl;
        bool hasCachedLogin = false;
        try {
          final authLocal = serviceLocator<AuthLocalDataSource>();
          final cachedLogin = await authLocal.getCachedLoginResponse();
          if (cachedLogin != null) {
            hasCachedLogin = true;
            final authRemote = serviceLocator<AuthRemoteDataSource>();
            final contextData = await authRemote.getLoginContext(
              accessToken: cachedLogin.accessToken,
            );
            await authLocal.saveLoginContext(contextData);

            // Sync org/school from login-context (LastLoginOrganizationCode,
            // LastLoginSchoolCode) into storage so all APIs use them.
            await authLocal.saveOrgAndSchoolFromContext(contextData);

            // Backend may return redirectUrl to tell us where to go
            // (select-school, select-organization, select-app, dashboard, etc).
            final rawRedirect = contextData['redirectUrl'];
            redirectUrl = rawRedirect is String ? rawRedirect.trim() : null;

            final String orgCode =
                (contextData['LastLoginOrganizationCode'] as String?)?.trim() ??
                    '';
            final String schoolCode =
                (contextData['LastLoginSchoolCode'] as String?)?.trim() ?? '';

            // Save org/school selection from login-context, but:
            // - do NOT overwrite an existing local schoolCode with null/empty
            // - if context schoolCode is empty, reuse the locally stored one
            //   so APIs can continue to use the last known school.
            if (orgCode.isNotEmpty) {
              final existingSchoolCode =
                  (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
              final effectiveSchoolCode =
                  schoolCode.isNotEmpty ? schoolCode : existingSchoolCode;

              if (effectiveSchoolCode.isNotEmpty) {
                await authLocal.setSelectedOrgAndSchool(
                  organizationCode: orgCode,
                  schoolCode: effectiveSchoolCode,
                  schoolName: '',
                );
              } else {
                // We only know the organization; keep any existing school selection
                // and just ensure organizationCode is stored.
                await storage.saveString(StorageKeys.organizationCode, orgCode);
              }
            }
          }
        } catch (_) {
          // Non-fatal: if context fetch fails, we still decide navigation below.
        }

        // If we have a cached login, navigation always follows login-context:
        if (hasCachedLogin) {
          await context.read<RoleProvider>().refreshAccessFromServer(force: true);
          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            final url = redirectUrl.toLowerCase();
            if (url.contains('select-school')) {
              final orgCode = await storage.getString(StorageKeys.organizationCode);
              if (orgCode != null && orgCode.isNotEmpty) {
                if (!mounted) return;
                await context.read<AuthCubit>().loadCachedData();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchoolSelectionScreen(
                      selectedOrg: orgCode,
                      orgFromLoginContext: true,
                    ),
                  ),
                );
                return;
              }
              // Fallback: org not in storage, go to org selection first
              if (!mounted) return;
              await context.read<AuthCubit>().loadCachedData();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrganizationSelectionScreen(),
                ),
              );
              return;
            }
            if (url.contains('select-organization')) {
              if (!mounted) return;
              await context.read<AuthCubit>().loadCachedData();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrganizationSelectionScreen(),
                ),
              );
              return;
            }
            if (url.contains('dashboard') || url.contains('select-app')) {
              // Backend explicitly says to go to dashboard/app selection.
              Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
              return;
            }
          }

          // No redirectUrl or unrecognized value: default to dashboard when logged in.
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        } else {
          // No cached login at all: go to Login, which will call login-context after success.
          Navigator.pushReplacementNamed(context, SignInScreen.routeName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// // NOTE: Login bypass removed. App always starts from Splash and follows
// // onboarding/login-context redirect flow.
// // Create a global instance of NotificationService that will be initialized later
// // final NotificationService notificationService = NotificationService();

// // // This function is required to handle background messages
// // @pragma('vm:entry-point')
// // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// //   print("Handling a background message: ${message.messageId}");
// //   // You can do minimal processing here, but avoid heavy work
// // }
// const bool kBypassLogin = true;
// const String kBypassOrganizationCode = 'ORG_49C7E2C8-8';
// const String kBypassSchoolCode = 'SCH_EE387C14-9';
// const String kBypassStaffCode = 'STF_C7899FBB-3';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize dependency injection
//   await configureDependencies();

//   // Only initialize if not already
//   if (Platform.isIOS) {
//     await Firebase.initializeApp(); // auto from GoogleService-Info.plist
//   } else {
//     // await Firebase.initializeApp(
//     //   options: DefaultFirebaseOptions.currentPlatform,
//     // );
//   }

//   // Set up background message handler
//   // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   // await init();
//   // await initOld();

//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//     DeviceOrientation.landscapeLeft,
//     DeviceOrientation.landscapeRight
//   ]);

//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   // final LocationService _locationService = LocationService();

//   @override
//   void initState() {
//     super.initState();

//     // setAccessToken();
//   }

//   // void setAccessToken() async {
//   //   if (AuthProvider.accessToken.isEmpty) {
//   //     SharedPreferences prefs = await SharedPreferences.getInstance();
//   //     if ((prefs.getBool('rememberMe') ?? false) &&
//   //         prefs.getString('accessToken').toString().isNotEmpty) {
//   //       String token = prefs.getString('accessToken') ?? '';
//   //       AuthProvider.setAccessToken(token);
//   //     }
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         // ChangeNotifierProvider(create: (_) => NotificationProvider()),
//         // ChangeNotifierProvider.value(value: _locationService),
//         // ChangeNotifierProvider(create: (_) => UserProviders()),
//         // ChangeNotifierProvider(create: (_) => StaffProviders()),
//         // ChangeNotifierProvider(create: (_) => GuardianProvider()),
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         // Needed by GlobalScaffold/Drawer/NavBar to determine role-based UI
//         ChangeNotifierProvider(create: (_) => RoleProvider()),
//         // ChangeNotifierProvider(create: (_) => AuthProvider()),
//         // ChangeNotifierProvider(create: (_) => NavBarHeightProvider()),
//         // ChangeNotifierProvider(create: (_) => ProfilePhotoProvider()),
//         // BlocProvider(create: (_) => sl<MasterLookupBloc>()),
//         // BlocProvider(create: (context) => sl<NappingStudentsCubit>()),
//         // BlocProvider(create: (_) => sl<FormValidatorBloc>()),
//         // BlocProvider(create: (_) => sl<AccessBloc>()),
//         // BlocProvider(create: (_) => sl<PhysicalTrackerBloc>()),
//         // BlocProvider(create: (_) => sl<AuthenticationBloc>()),
//         // BlocProvider(create: (_) => sl<DocumentBloc>()),
//         // BlocProvider(create: (_) => sl<DocumentCubit>()),
//         // BlocProvider(create: (_) => sl<StaffCubit>()),
//         // BlocProvider(create: (_) => sl<AddressCubit>()),
//         // BlocProvider(create: (_) => sl<GuardianCubit>()),
//         // BlocProvider(create: (_) => sl<PaymentGatewayMerchantSettingsCubit>()),
//         // BlocProvider(create: (_) => sl<TotalAttendanceCubit>()),
//         // BlocProvider(create: (_) => sl<AttendanceCubit>()),
//         // BlocProvider(create: (_) => sl<AttendanceReportCubit>()),
//         // BlocProvider(create: (_) => sl<RoomdataCubit>()),
//       ],
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, _) {
//           double customScaler;
//           double systemTextScaleFactor = MediaQuery.of(
//             context,
//           ).textScaler.scale(1);

//           if (systemTextScaleFactor < 0.85) {
//             customScaler = 0.8;
//           } else if (systemTextScaleFactor >= 0.85 &&
//               systemTextScaleFactor < 1.0) {
//             customScaler = 0.9;
//           } else if (systemTextScaleFactor >= 1.0 &&
//               systemTextScaleFactor < 1.2) {
//             customScaler = 1.0;
//           } else if (systemTextScaleFactor >= 1.2 &&
//               systemTextScaleFactor < 1.5) {
//             customScaler = 1.1;
//           } else {
//             customScaler = 1.2;
//           }

//           return MediaQuery(
//             data: MediaQuery.of(
//               context,
//             ).copyWith(textScaler: TextScaler.linear(customScaler)),
//             child: Sizer(
//               builder: (context, orientation, screenType) {
//                 return MultiBlocProvider(
//                   providers: [
//                     BlocProvider<AuthCubit>(
//                       create: (_) {
//                         final cubit = serviceLocator<AuthCubit>();
//                         cubit.initialize();
//                         return cubit;
//                       },
//                     ),
//                   ],
//                   child: MaterialApp(
//                     debugShowCheckedModeBanner: false,
//                     title: 'WowCare',
//                     theme: themeProvider.currentTheme,
//                     home: const SplashScreenWrapper(),
//                     onGenerateRoute: generateRoute,
//                     navigatorKey: navigatorKey,
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class SplashScreenWrapper extends StatefulWidget {
//   const SplashScreenWrapper({super.key});

//   @override
//   State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
// }

// class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
//   @override
//   void initState() {
//     super.initState();
//     _initNotifications();
//     _navigateToHome();
//   }

//   // Initialize notifications now that we have a context
//   Future<void> _initNotifications() async {
//     // try {
//     //   await notificationService.init(context);
//     //   print('Notification service initialized successfully');
//     // } catch (e) {
//     //   print('Error initializing notification service: $e');
//     // }
//   }

//   _navigateToHome() async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (mounted) {
//       final storage = serviceLocator<StorageService>();

//       final seenOnboarding =
//           await storage.getBool(StorageKeys.onboardingSeen) ?? false;

//       if (!seenOnboarding) {
//         // Very first app launch: always show onboarding once and clear any old auth.
//         await serviceLocator<AuthLocalDataSource>().clearCache();
//         Navigator.pushReplacementNamed(context, '/first-screen');
//       } else {
//         // After onboarding:
//         // - Always call login-context on app start whenever we have a cached login,
//         //   and always use its redirectUrl (if any) to decide navigation.
//         String? redirectUrl;
//         bool hasCachedLogin = false;
//         try {
//           final authLocal = serviceLocator<AuthLocalDataSource>();
//           final cachedLogin = await authLocal.getCachedLoginResponse();
//           if (cachedLogin != null) {
//             hasCachedLogin = true;
//             final authRemote = serviceLocator<AuthRemoteDataSource>();
//             final contextData = await authRemote.getLoginContext(
//               accessToken: cachedLogin.accessToken,
//             );
//             await authLocal.saveLoginContext(contextData);

//             // Sync org/school from login-context (LastLoginOrganizationCode,
//             // LastLoginSchoolCode) into storage so all APIs use them.
//             await authLocal.saveOrgAndSchoolFromContext(contextData);

//             // Backend may return redirectUrl to tell us where to go
//             // (select-school, select-organization, select-app, dashboard, etc).
//             final rawRedirect = contextData['redirectUrl'];
//             redirectUrl = rawRedirect is String ? rawRedirect.trim() : null;

//             final String orgCode =
//                 (contextData['LastLoginOrganizationCode'] as String?)?.trim() ??
//                     '';
//             final String schoolCode =
//                 (contextData['LastLoginSchoolCode'] as String?)?.trim() ?? '';

//             // Save org/school selection from login-context, but:
//             // - do NOT overwrite an existing local schoolCode with null/empty
//             // - if context schoolCode is empty, reuse the locally stored one
//             //   so APIs can continue to use the last known school.
//             if (orgCode.isNotEmpty) {
//               final existingSchoolCode =
//                   (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
//               final effectiveSchoolCode =
//                   schoolCode.isNotEmpty ? schoolCode : existingSchoolCode;

//               if (effectiveSchoolCode.isNotEmpty) {
//                 await authLocal.setSelectedOrgAndSchool(
//                   organizationCode: orgCode,
//                   schoolCode: effectiveSchoolCode,
//                   schoolName: '',
//                 );
//               } else {
//                 // We only know the organization; keep any existing school selection
//                 // and just ensure organizationCode is stored.
//                 await storage.saveString(StorageKeys.organizationCode, orgCode);
//               }
//             }
//           }
//         } catch (_) {
//           // Non-fatal: if context fetch fails, we still decide navigation below.
//         }

//         // If we have a cached login, navigation always follows login-context:
//         if (hasCachedLogin) {
//           if (redirectUrl != null && redirectUrl.isNotEmpty) {
//             final url = redirectUrl.toLowerCase();
//             if (url.contains('select-school')) {
//               final orgCode = await storage.getString(StorageKeys.organizationCode);
//               if (orgCode != null && orgCode.isNotEmpty) {
//                 if (!mounted) return;
//                 await context.read<AuthCubit>().loadCachedData();
//                 if (!mounted) return;
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => SchoolSelectionScreen(
//                       selectedOrg: orgCode,
//                       orgFromLoginContext: true,
//                     ),
//                   ),
//                 );
//                 return;
//               }
//               // Fallback: org not in storage, go to org selection first
//               if (!mounted) return;
//               await context.read<AuthCubit>().loadCachedData();
//               if (!mounted) return;
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const OrganizationSelectionScreen(),
//                 ),
//               );
//               return;
//             }
//             if (url.contains('select-organization')) {
//               if (!mounted) return;
//               await context.read<AuthCubit>().loadCachedData();
//               if (!mounted) return;
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const OrganizationSelectionScreen(),
//                 ),
//               );
//               return;
//             }
//             if (url.contains('dashboard') || url.contains('select-app')) {
//               // Backend explicitly says to go to dashboard/app selection.
//               Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
//               return;
//             }
//           }

//           // No redirectUrl or unrecognized value: default to dashboard when logged in.
//           Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
//         } else {
//           // No cached login at all: go to Login, which will call login-context after success.
//           Navigator.pushReplacementNamed(context, SignInScreen.routeName);
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const SplashScreen();
//   }
}