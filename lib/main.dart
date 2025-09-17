import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'src/core/Common/app/providers/splash_screen.dart';
import 'src/core/Common/app/providers/theme_providers.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase if needed
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme cubit
        BlocProvider(create: (_) => ThemeCubit()),

        // Onboarding cubit
        // BlocProvider(create: (_) => OnBoardingCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, theme) {
          // Handle text scale manually
          double customScaler;
          double systemTextScaleFactor = MediaQuery.of(
            context,
          ).textScaler.scale(1);

          if (systemTextScaleFactor < 0.85) {
            customScaler = 0.8;
          } else if (systemTextScaleFactor < 1.0) {
            customScaler = 0.9;
          } else if (systemTextScaleFactor < 1.2) {
            customScaler = 1.0;
          } else if (systemTextScaleFactor < 1.5) {
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
              theme: theme,
              home: const SplashScreen(), // ✅ directly show splash
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
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // final onboardingCubit = context.read<OnBoardingCubit>();

    // if (onboardingCubit.state == OnBoardingStatus.firstLaunch) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(
    //       builder: (_) => BlocProvider.value(
    //         value: onboardingCubit,
    //         child: const OnboardingScreen(),
    //       ),
    //     ),
    //   );
    // } else {
    //   Navigator.pushReplacementNamed(context, '/first-screen');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
