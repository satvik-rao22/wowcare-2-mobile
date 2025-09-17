// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'src/core/Common/app/providers/splash_screen.dart';
// import 'src/core/common/app/providers/theme_providers.dart';
// import 'src/core/common/app/providers/user_providers.dart';
// import 'src/core/common/app/providers/guardian_provider.dart';
// import 'src/core/common/app/providers/staff_provider.dart';
// import 'src/core/common/app/providers/profile_photo_provider.dart';
// import 'src/core/common/app/providers/auth_providers.dart';
// import 'src/core/common/app/providers/nav_bar_providers.dart';
// import 'src/presentation/screens/on_boarding/data/datasources/on_boarding_local_datasource.dart';
// import 'src/presentation/screens/on_boarding/presentation/cubit/cubit/on_boarding_cubit.dart';
// import 'src/presentation/screens/on_boarding/presentation/views/onboarding_screen.dart';

// Route<dynamic> generateRoute(RouteSettings settings) {
//   switch (settings.name) {
//     case '/':
//       return _pageBuilder((_) => const SplashScreen(), settings: settings);

//     case '/first-screen':
//       final prefs = sl<SharedPreferences>();

//       return _pageBuilder((context) {
//         if (prefs.getBool(kFirstTimerKey) ?? true) {
//           return BlocProvider(
//             create: (_) => sl<OnBoardingCubit>(),
//             child: const OnboardingScreen(),
//           );
//         }
//       }, settings: settings);
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
