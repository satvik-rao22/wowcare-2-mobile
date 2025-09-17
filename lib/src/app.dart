// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'core/Common/app/providers/splash_screen.dart';
// import 'core/common/views/page_under_construction.dart';
// import 'injection-container.dart';
// import 'presentation/screens/on_boarding/presentation/cubit/cubit/on_boarding_cubit.dart';
// import 'presentation/screens/on_boarding/presentation/views/onboarding_screen.dart';

// Route<dynamic> generateRoute(RouteSettings settings) {
//   switch (settings.name) {
//     case '/':
//       return _pageBuilder((_) => const SplashScreen(), settings: settings);

//     case '/first-screen':
//       return _pageBuilder(
//         (_) => BlocProvider(
//           create: (_) => sl<OnBoardingCubit>(),
//           child: const OnboardingScreen(),
//         ),
//         settings: settings,
//       );

//     default:
//       return _pageBuilder(
//         (_) => const PageUnderConstruction(),
//         settings: settings,
//       );
//   }
// }

// PageRouteBuilder<dynamic> _pageBuilder(
//   Widget Function(BuildContext) page, {
//   required RouteSettings settings,
// }) {
//   return PageRouteBuilder(
//     transitionsBuilder: (_, animation, __, child) =>
//         FadeTransition(opacity: animation, child: child),
//     pageBuilder: (context, _, __) => page(context),
//     settings: settings,
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/src/presentation/screens/on_boarding/presentation/cubit/cubit/on_boarding_cubit.dart';

import 'core/Common/app/providers/splash_screen.dart';
import 'core/common/views/page_under_construction.dart';
import 'presentation/screens/on_boarding/presentation/views/onboarding_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return _pageBuilder((_) => const SplashScreen(), settings: settings);

    case '/first-screen':
      return _pageBuilder(
        // (_) => BlocProvider(
        //   // create: (_) => OnBoardingCubit(
        //   //   cacheFirstTimer: ,
        //   //   checkIfUserIsFirstTimer: ,
        //   // ), // Directly instantiate OnBoardingCubit
        //   child: const OnboardingScreen(),
        // ),
        // settings: settings,
        (_) => const OnboardingScreen(),
        settings: settings,
      );

    default:
      return _pageBuilder(
        (_) => const PageUnderConstruction(),
        settings: settings,
      );
  }
}

PageRouteBuilder<dynamic> _pageBuilder(
  Widget Function(BuildContext) page, {
  required RouteSettings settings,
}) {
  return PageRouteBuilder(
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, __) => page(context),
    settings: settings,
  );
}
