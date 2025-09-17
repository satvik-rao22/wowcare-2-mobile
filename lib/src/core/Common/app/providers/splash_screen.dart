// import 'package:flutter/material.dart';

// import '../../../res/media_res.dart';
// import '../../widgets/animation_slide_widgets.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Background Image
//           AnimationWrapper(
//             type: AnimationType.bounce,
//             duration: Duration.zero,
//             curve: Curves.easeOut,
//             child: Image.asset(
//               MediaRes.backgroundImage2, // Replace with your image path
//               fit: BoxFit.cover,
//             ),
//           ),

//           // Logo and loading indicator
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Logo
//               Image.asset(
//                 // MediaRes.logo_wow, // Replace with your logo path
//                 'assets/images/WowCarePNG.png',
//                 width: 150, // Adjust logo size
//                 height: 150,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../presentation/screens/on_boarding/presentation/views/onboarding_screen.dart';
import '../../../res/media_res.dart';
import '../../widgets/animation_slide_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToOnboarding();
  }

  void _goToOnboarding() {
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          AnimationWrapper(
            type: AnimationType.bounce,
            duration: Duration.zero,
            curve: Curves.easeOut,
            child: Image.asset(
              MediaRes.backgroundImage2, // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),

          // Logo
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/WowCarePNG.png',
                width: 150,
                height: 150,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
