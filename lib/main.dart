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
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/shared/common/app/providers/theme_providers.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';

import 'src/app_router.dart';
import 'shared/common/app/providers/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
      final loginCompleted =
          await storage.getBool(StorageKeys.loginCompleted) ?? false;
      final accessToken = await storage.getString(StorageKeys.accessToken) ?? '';

      if (!seenOnboarding) {
        // If onboarding is available, always clear any old auth state so the user
        // must complete the login flow after onboarding.
        await serviceLocator<AuthLocalDataSource>().clearCache();
        Navigator.pushReplacementNamed(context, '/first-screen');
      } else if (accessToken.trim().isEmpty) {
        // If we don't have a token, always start at login regardless of stale flags.
        Navigator.pushReplacementNamed(context, SignInScreen.routeName);
      } else if (!loginCompleted) {
        // Token exists but user hasn't finished org/school selection in this session.
        // We currently send them back through Sign-In flow (which leads to org selection).
        Navigator.pushReplacementNamed(context, SignInScreen.routeName);
      } else {
        Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}