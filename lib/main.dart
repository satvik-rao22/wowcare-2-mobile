import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/src/core/common/app/bloc/theme_providers.dart';

import 'src/app.dart';
import 'src/core/Common/app/providers/splash_screen.dart';

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
      Navigator.pushReplacementNamed(context, '/first-screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
