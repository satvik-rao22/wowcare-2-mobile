import 'package:flutter/material.dart';
import 'package:wowcare/src/core/extentions/context_extentions.dart';

import '../../../core/common/widgets/rounded_button.dart';
import '../../../core/res/colors.dart';
import '../../../core/res/media_res.dart';
import 'sign_in_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routName = '/auth-screen';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late final AnimationController _bottomMenuHeightAnimationController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );

  late final Animation<double> _bottomMenuHeightUpAnimation =
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _bottomMenuHeightAnimationController,
          curve: const Interval(0, 0.6, curve: Curves.easeInOut),
        ),
      );

  late final Animation<double> _bottomMenuHeightDownAnimation =
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _bottomMenuHeightAnimationController,
          curve: const Interval(0.6, 1, curve: Curves.easeInOut),
        ),
      );

  @override
  void initState() {
    super.initState();
    startAnimation();
  }

  Future<void> startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _bottomMenuHeightAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _bottomMenuHeightAnimationController.dispose();
    super.dispose();
  }

  Widget _buildLottieAnimation() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: context.width,
        height: context.height,
        child: Image.asset(MediaRes.loginLottie, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _bottomMenuHeightAnimationController,
        builder: (context, child) {
          final height =
              context.height * 0.3 * _bottomMenuHeightUpAnimation.value -
              context.height * 0.05 * _bottomMenuHeightDownAnimation.value;
          return Container(
            width: context.width,
            height: height,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: AnimatedSwitcher(
              switchInCurve: Curves.easeInOut,
              duration: const Duration(milliseconds: 400),
              child: _bottomMenuHeightAnimationController.value != 1
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, boxConstraints) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: context.width / 5,
                                  height: context.height / 9,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/WowCarePNG.png',
                                        width: 68,
                                        height: 68,
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'WowCare',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: boxConstraints.maxHeight * 0.05),
                            RoundedButton(
                              lable: 'Login',
                              lableColor: AppColors.cardColor,
                              buttonColor: AppColors.themeColor,
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  SignInScreen.routeName,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.themeColor,
      body: Stack(children: [_buildLottieAnimation(), _buildBottomMenu()]),
    );
  }
}
