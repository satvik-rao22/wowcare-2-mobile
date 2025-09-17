import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/src/core/Common/extentions/context_extentions.dart';
import 'package:wowcare/src/presentation/screens/on_boarding/presentation/cubit/cubit/on_boarding_cubit.dart';

import '../../../../../core/res/colors.dart';
import '../../domain/entities/page_content.dart';

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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(pageContent.image, height: context.height * 0.4),
              SizedBox(height: context.height * 0.12),
              Column(
                children: [
                  Text(
                    pageContent.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.height * 0.02),
                  Text(
                    pageContent.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  SizedBox(height: context.height * 0.15),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 100,
          left: 120,
          right: 120,
          child: SizedBox(
            width: 200,
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
                  ? const Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
