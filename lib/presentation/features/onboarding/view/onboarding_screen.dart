import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wowcare/domain/features/onboarding/entities/page_content.dart';
// Removed missing context extensions and PageContent; using inline content for now

import '../../../../app/theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    // context.read<OnBoardingCubit>().checkIfUserIsFirstTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          // BlocConsumer<OnBoardingCubit, OnBoardingState>(
          //   listener: (context, state) {
          //     if (state is OnBoardingStatus && !state.isFirstTimer) {
          //       Navigator.pushReplacementNamed(context, '/home');
          //     } else if (state is UserCached) {
          //       Navigator.pushReplacementNamed(context, '/first-screen');
          //     }
          //   },
          //   builder: (context, state) {
          //     if (state is CheckingIfUserIsFirstTimer ||
          //         state is CachingFirstTimer) {
          //       return const Center(child: CircularProgressIndicator());
          //     }
          Stack(
            children: [
              PageView(
                controller: pageController,
                children: [
                  OnboardingBody(
                    pageContent: const PageContent.first(),
                    onNextPressed: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  OnboardingBody(
                    pageContent: const PageContent.second(),
                    onNextPressed: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  OnboardingBody(
                    pageContent: const PageContent.third(),
                    onNextPressed: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const OnboardingBody(
                    pageContent: PageContent.forth(),
                    isLastPage: true,
                  ),
                ],
              ),
              Align(
                alignment: const Alignment(0, 0.06),
                child: SmoothPageIndicator(
                  controller: pageController,
                  count: 4,
                  onDotClicked: (index) {
                    pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 40,
                    activeDotColor: AppColors.themeColor,
                    dotColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class OnboardingBody extends StatelessWidget {
  const OnboardingBody({
    super.key,
    required this.pageContent,
    this.isLastPage = false,
    this.onNextPressed,
  });

  final PageContent pageContent;
  final bool isLastPage;
  final VoidCallback? onNextPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive values
    double buttonBottom = screenHeight * 0.08; // 8% from bottom
    double buttonWidth = screenWidth > 600 ? 300 : 200;
    double buttonLeft = screenWidth > 600 ? screenWidth * 0.2 : 32;
    double buttonRight = screenWidth > 600 ? screenWidth * 0.2 : 32;
    double titleFontSize = screenWidth > 600 ? 32 : 24;
    double descFontSize = screenWidth > 600 ? 20 : 16;
    double buttonFontSize = screenWidth > 600 ? 22 : 16;
    double iconSize = screenWidth > 600 ? 32 : 24;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(pageContent.image, height: MediaQuery.of(context).size.height * 0.4),
              SizedBox(height: MediaQuery.of(context).size.height * 0.12),
              Column(
                children: [
                  Text(
                    pageContent.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    pageContent.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: buttonBottom,
          left: buttonLeft,
          right: buttonRight,
          child: SizedBox(
            width: buttonWidth,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 14,
                ),
              ),
              onPressed: () {
                if (isLastPage) {
                  // context.read<OnBoardingCubit>().cacheFirstTimer();
                } else {
                  onNextPressed?.call();
                }
              },
              child: isLastPage
                  ? Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: iconSize,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}



