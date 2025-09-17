import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/animation_slide_widgets.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/src/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.firstScreen);
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
              MediaRes.backgroundImage2,
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:lottie/lottie.dart';
// import 'package:wowcare/core/res/media_res.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
//   late final AnimationController _bottomMenuHeightAnimationController =
//       AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 600),
//   );

//   late final Animation<double> _bottomMenuHeightUpAnimation =
//       Tween<double>(begin: 0.0, end: 1.0).animate(
//     CurvedAnimation(
//       parent: _bottomMenuHeightAnimationController,
//       curve: Curves.easeInOut,
//     ),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _bottomMenuHeightAnimationController.forward();
//   }

//   @override
//   void dispose() {
//     _bottomMenuHeightAnimationController.dispose();
//     super.dispose();
//   }

//   Widget _buildLottieAnimation() {
//     return Container(
//       width: MediaQuery.of(context).size.width,
//       height: MediaQuery.of(context).size.height * 0.4,
//       child: Lottie.asset(
//         MediaRes.signInLottie,
//         fit: BoxFit.cover,
//       ),
//     );
//   }

//   Widget _buildBottomMenu() {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: AnimatedBuilder(
//         animation: _bottomMenuHeightAnimationController,
//         builder: (context, child) {
//           final height = MediaQuery.of(context).size.height *
//               0.5 *
//               _bottomMenuHeightUpAnimation.value;

//           return Container(
//             width: MediaQuery.of(context).size.width,
//             height: height,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(30.0),
//                 topRight: Radius.circular(30.0),
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.white,
//                   radius: MediaQuery.of(context).size.width * 0.25,
//                   child: SvgPicture.asset(
//                     'assets/images/WowLogoRound.svg',
//                     width: 150,
//                     height: 150,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     // Navigation placeholder
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 40, vertical: 15), backgroundColor: Colors.orange,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ), // Replace with your color
//                   ),
//                   child: const Text(
//                     'Login',
//                     style: TextStyle(fontSize: 16, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.orangeAccent, // Replace with your theme color
//       body: Stack(
//         children: [
//           _buildLottieAnimation(),
//           _buildBottomMenu(),
//         ],
//       ),
//     );
//   }
// }

